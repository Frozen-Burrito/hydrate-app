import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'package:hydrate_app/src/models/hydration_record.dart';
import 'package:hydrate_app/src/utils/little_endian_extractor.dart';
import 'package:synchronized/synchronized.dart';

class HydrateDevice {

  /// Crea una nueva instancia de [HydrateDevice] a partir de un 
  /// [BluetoothDevice].
  HydrateDevice.fromBleDevice(BluetoothDevice device) 
    : deviceId = device.id,
      name = device.name,
      _underlyingBleDevice = device {
    _underlyingBleDevice.state.listen(_handleDeviceStateChange);
    _hydrationRecordsController.onListen = _addLatestHydrationRecordToStream;
  }

  /// El identificador único del dispositivo. Está basado en el ID de BLE.
  final DeviceIdentifier deviceId;
  /// El nombre del dispositivo.
  final String name;
  /// La implementación subyacente del dispositivo, como un dispositivo BLE central.
  final BluetoothDevice _underlyingBleDevice;

  Stream<HydrationRecord> get hydrationRecords => _hydrationRecordsController.stream;

  Stream<BluetoothDeviceState> get connectionState => _underlyingBleDevice.state;

  bool get isDisconnected => _deviceState == BluetoothDeviceState.disconnected;

  Stream<int> get maxTransmissionUnit => _underlyingBleDevice.mtu;

  /// Retorna los UUID de 128 bits de cada servicio soportado por este dispositivo.
  Set<String> get supportedServicesUUIDs => <String>{ hydrationSvcUUID, _batterySvcUUID };

  /// Retorna los UUID de 128 bits de cada atributo soportado por este dispositivo.
  Set<String> get supportedAttributesUUIDs => _supportedCharsUUIDs;

  Future<void> connect() {
    return _underlyingBleDevice.connect();
  }

  Future<void> disconnect() {
    return _underlyingBleDevice.disconnect();
  }

  Future<void> changeMaxTransmissionUnit(int newMtu) async {
    try {
      await _underlyingBleDevice.requestMtu(newMtu);
    } on Exception catch(ex) {
      debugPrint("Error al solicitar un MTU diferente ($newMtu): $ex");
    }
  }

  static const String hydrationSvcUUID = "000019f5-0000-1000-8000-00805f9b34fb";
  static const String _batterySvcUUID = "0000180f-0000-1000-8000-00805f9b34fb";

  static const String _mlAmountCharUUID = "0faf892c-0000-1000-8000-00805f9b34fb";
  static const String _temperatureCharUUID = "00002a6e-0000-1000-8000-00805f9b34fb";
  static const String _timestampCharUUID = "00000fff-0000-1000-8000-00805f9b34fb";
  static const String _canSyncRecordCharUUID = "0faf892f-0000-1000-8000-00805f9b34fb";
  static const String _batteryChargeCharUUID = "00002a19-0000-1000-8000-00805f9b34fb";

  static const Map<String, String> recordUUIDsToAttributes = {
    _mlAmountCharUUID: HydrationRecord.amountFieldName,
    _temperatureCharUUID: HydrationRecord.temperatureFieldName,
    _timestampCharUUID: HydrationRecord.dateFieldName,
    _batteryChargeCharUUID: HydrationRecord.batteryLvlFieldName,
  };

  final Set<String> _supportedCharsUUIDs = <String>{ 
    _mlAmountCharUUID,
    _temperatureCharUUID,
    _timestampCharUUID,
    _canSyncRecordCharUUID,
    _batteryChargeCharUUID,
  };

  final Set<String> _charsWithNotifySupport = <String>{ _canSyncRecordCharUUID };

  // El controlador para el Stream que contiene los HydrationRecord obtenidos
  // por BLE desde _underlyingDevice.
  final StreamController<HydrationRecord> _hydrationRecordsController = StreamController.broadcast(); 
  StreamSubscription<List<int>>? _onRecordAvailableSubscription;

  BluetoothDeviceState _deviceState = BluetoothDeviceState.disconnected;

  HydrationRecord? _latestHydrationRecord;

  final List<BluetoothService> _allServices = <BluetoothService>[];

  BluetoothService? _hydrationService;
  BluetoothService? _batteryService;

  final Lock _gattLock = Lock();

  static const Duration _immmediateDuration = Duration( milliseconds: 0 );
  static const Duration _delayOnSubsequentReads = Duration( milliseconds: 400 );
  static const Duration _delayBeforeWriteConfirm = Duration( milliseconds: 400 );

  void _handleDeviceStateChange(BluetoothDeviceState nextConnectionState) {

    _deviceState = nextConnectionState;

    switch (nextConnectionState) {
      case BluetoothDeviceState.disconnected:
        _onDeviceDisconnected();
        break;
      case BluetoothDeviceState.connected:
        _onDeviceConnected();
        break;
      default:
        if (kDebugMode) {
          print("Ignored device state change: $nextConnectionState");
        }
        break;
    }
  }

  Future<void> _onDeviceConnected() async {
    if (kDebugMode) {
      print("Device connected, discovering services");
    }

    // Descubrir los servicios y luego actualizarlos.
    _onServicesDiscovered(await _underlyingBleDevice.discoverServices());

    if (_hydrationService != null) {
      // Activar las notificaciones en ciertas caracteristicas/
      for (final characteristic in _hydrationService!.characteristics) {

        if (_canSetNotifyValue(characteristic)) {
          await _gattLock.synchronized(() async {
            try {
              await Future.delayed(
                _delayOnSubsequentReads, 
                () => characteristic.setNotifyValue(true)
              );
              
              _onRecordAvailableSubscription ??= characteristic.value.listen(_onHydrationRecordAvailable);

            } on Exception catch (ex) {
              debugPrint("Exepcion al intentar escribir el valor de notify: $ex");
            }
          });
        }
      }
    } else {
      debugPrint("Expected to find a hydration and a battery service, but one of those or both were not found");
    }
  }

  Future<void> _onDeviceDisconnected() async {
    await _onRecordAvailableSubscription?.cancel();
    _onRecordAvailableSubscription = null;
  }

  Future<void> _onHydrationRecordAvailable(List<int> isRecordAvailableBytes) async {

    if (isRecordAvailableBytes.isEmpty) {
      debugPrint("<isRecordAvailableBytes> is empty, no hydration record to sync.");
      return;
    }

    final isRecordAvailable = LittleEndianExtractor.extractUint8(isRecordAvailableBytes) == 1;

    if (!isRecordAvailable) {
      debugPrint("No records available for sync; everything is up to date.");
      return;
    }

    debugPrint("A punto de tomar _gattLock");

    final Map<String, Object?> hydrationRecordData = {};

    await _gattLock.synchronized(() async {

      debugPrint("_gattLock tomado");

      final hydrationData = await _readAttributesFromService(
        _hydrationService!, 
        attributes: {
          _mlAmountCharUUID: (List<int> bytes) {
            return LittleEndianExtractor.extractUint16(bytes);
          },
          _temperatureCharUUID: (List<int> bytes) {
            if (bytes.length == 2) {
              final parsedTemperature = LittleEndianExtractor.extractInt16(bytes);
              return parsedTemperature / 100.0;
            } else {
              return null;
            }
          },  
          _timestampCharUUID: (List<int> bytes) {
            if (bytes.isNotEmpty) {
              final secondsSinceEpoch = LittleEndianExtractor.extractInt64(bytes);

              final msSinceEpoch = min(max((secondsSinceEpoch * 1000), 0), DateTime.now().millisecondsSinceEpoch);

              return DateTime.fromMillisecondsSinceEpoch(msSinceEpoch);
            }
          },
        },
        startWithDelay: false
      );

      hydrationRecordData.addAll(hydrationData);

      final batteryData = await _readAttributesFromService(
        _batteryService!, 
        attributes: {
          _batteryChargeCharUUID: (List<int> bytes) => LittleEndianExtractor.extractUint8(bytes),
        },
        startWithDelay: false
      );
    
      hydrationRecordData.addAll(batteryData);

      final newHydrationRecord = HydrationRecord.fromMap(_transformRxMap(hydrationRecordData));

      await _confirmRecordReceived();

      _latestHydrationRecord = newHydrationRecord;

      _addLatestHydrationRecordToStream();
    });
  }

  // Funciones de utilidad

  void _onServicesDiscovered(List<BluetoothService> services) {
    _hydrationService = null;
    _batteryService = null;

    _allServices.clear();
    _allServices.addAll(services);

    for (final service in services) {
      switch (service.uuid.toString()) {
        case hydrationSvcUUID:
          _hydrationService = service;
          break;
        case _batterySvcUUID:
          _batteryService = service;
          break;
      }
    }
  }

  Future<bool> _confirmRecordReceived() async {

    bool couldConfirm = false;

    for (final characteristic in _hydrationService!.characteristics) {
      if (characteristic.uuid.toString() == _canSyncRecordCharUUID) {
        try {
          await Future.delayed(
            _delayBeforeWriteConfirm,
            () => characteristic.write(<int>[0x00], withoutResponse: false)
          );

          couldConfirm = true;

        } on Exception catch (ex) {
          debugPrint("Error al escribir a la caracteristica con UUID = _canSyncRecordCharUUID: $ex");
          couldConfirm = false;
        }

        break;
      }
    }

    return couldConfirm;
  }

  Future<Map<String, Object?>> _readAttributesFromService(
    BluetoothService service, { 
      required Map<String, Object? Function(List<int>)> attributes,
      bool startWithDelay = false, 
    }
  ) 
  async {

    bool isFirstRead = true;
    final List<int> charValueBytes = <int>[];
    final Map<String, Object?> outputMap = {};

    for (final characteristic in service.characteristics) {
      if (_canReadFromChar(characteristic)) {
        // Solo leer el valor de la caracteristica si esta es soportada.
        charValueBytes.clear();

        try {
          final Iterable<int> bytesRead = await Future.delayed(
            (!isFirstRead || startWithDelay) ? _delayOnSubsequentReads : _immmediateDuration,
            () => characteristic.read()
          );

          charValueBytes.addAll(bytesRead);

        } on Exception catch (ex) {
          debugPrint("Error al leer el valor de una caracteristica (UUID = ${characteristic.uuid}) del servicio (UUID = ${service.uuid}) : $ex");
        }

        final String charUUID = characteristic.uuid.toString();
        if (attributes.containsKey(charUUID)) {
          // Transformar el buffer de bytes leido a un valor para la 
          // caracteristica y almacenarlo en outputMap.
          outputMap[charUUID] = attributes[charUUID]!.call(charValueBytes);
        }
      }  
    }

    return outputMap;
  }

  /// Agrega el valor de [_latestHydrationRecord] a [_hydrationRecordsController],
  /// si [_latestHydrationRecord] no es null.
  void _addLatestHydrationRecordToStream() {
    final record = _latestHydrationRecord;

    debugPrint("About to sync a new record: $record");

    if (record != null) {
      _hydrationRecordsController.sink.add(record);
    }
  }

  bool _canSetNotifyValue(BluetoothCharacteristic characteristic) {
    final charUUID = characteristic.uuid.toString();

    final bool hasSupportedUUID = _charsWithNotifySupport.contains(charUUID);
    final bool isNotNotifying = !characteristic.isNotifying;
    final bool supportsNotify = characteristic.properties.notify;

    return hasSupportedUUID && isNotNotifying && supportsNotify;
  }

  bool _canReadFromChar(BluetoothCharacteristic characteristic) {
    final isCharSupported = _supportedCharsUUIDs.contains(characteristic.uuid.toString());
    final charSupportsRead = characteristic.properties.read;

    return isCharSupported && charSupportsRead;
  }

  Map<String, Object?> _transformRxMap(Map<String, Object?> rxRecordData) {

    final Map<String, Object?> outputMap = {};

    for (final entry in rxRecordData.entries) {
      if (recordUUIDsToAttributes.containsKey(entry.key)) {
        final String attributeKey = recordUUIDsToAttributes[entry.key]!;
        outputMap[attributeKey] = entry.value;
      }
    }

    assert(outputMap.length == rxRecordData.length, "Received map could not be transformed to attribute map properly");

    return outputMap;
  }

  @override
  bool operator==(covariant HydrateDevice other) {
    return identical(this, other) || (deviceId == other.deviceId && _underlyingBleDevice == other._underlyingBleDevice);
  }
  
  @override
  int get hashCode => deviceId.hashCode;
}
