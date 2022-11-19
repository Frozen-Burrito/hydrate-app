import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:synchronized/synchronized.dart';

import 'package:hydrate_app/src/models/hydration_record.dart';
import 'package:hydrate_app/src/utils/little_endian_extractor.dart';

class HydrateDevice {

  /// Crea una nueva instancia de [HydrateDevice] a partir de un 
  /// [BluetoothDevice].
  HydrateDevice._internal(BluetoothDevice device, { bool isAlreadyConnected = false }) 
    : deviceId = device.id,
      name = device.name,
      _underlyingBleDevice = device {
    _deviceState = isAlreadyConnected 
      ? BluetoothDeviceState.connected 
      : BluetoothDeviceState.disconnected;

    _hydrationRecordsController.onListen = _addLatestHydrationRecordToStream;
  }

  factory HydrateDevice.fromBleDevice(BluetoothDevice device, { bool isAlreadyConnected = false }) {
    return _bleDevices.putIfAbsent(
      device.id, 
      () => HydrateDevice._internal(device, isAlreadyConnected: isAlreadyConnected),
    );
  }

  /// El identificador único del dispositivo. Está basado en el ID de BLE.
  final DeviceIdentifier deviceId;
  /// El nombre del dispositivo.
  final String name;
  /// La implementación subyacente del dispositivo, como un dispositivo BLE central.
  final BluetoothDevice _underlyingBleDevice;

  Stream<HydrationRecord> get hydrationRecords => _hydrationRecordsController.stream;

  Stream<BluetoothDeviceState> get connectionState => _underlyingBleDevice.state;

  bool get isConnected => _deviceState == BluetoothDeviceState.connected;
  bool get isDisconnected => _deviceState == BluetoothDeviceState.disconnected;

  Stream<int> get maxTransmissionUnit => _underlyingBleDevice.mtu;

  /// Retorna los UUID de 128 bits de cada servicio soportado por este dispositivo.
  Set<String> get supportedServicesUUIDs => <String>{ hydrationSvcUUID, _batterySvcUUID };

  /// Retorna los UUID de 128 bits de cada atributo soportado por este dispositivo.
  Set<String> get supportedAttributesUUIDs => _supportedCharsUUIDs;

  Future<void> connect() async {
    if (_deviceState == BluetoothDeviceState.disconnected) {
      _deviceStateSubscription = _underlyingBleDevice.state.listen(_handleDeviceStateChange);
      await _underlyingBleDevice.connect();
    }
  }

  Future<void> disconnect() async {
    if (_deviceState == BluetoothDeviceState.connected) {
      await _underlyingBleDevice.disconnect();
      _deviceStateSubscription?.cancel();
      _deviceState = BluetoothDeviceState.disconnected;
    }
  }

  Future<void> changeMaxTransmissionUnit(int newMtu) async {
    try {
      await _underlyingBleDevice.requestMtu(newMtu);
    } on Exception catch(ex) {
      debugPrint("Error al solicitar un MTU diferente ($newMtu): $ex");
    }
  }

  // UUIDs del servicio de hidratación y sus características.
  static const String hydrationSvcUUID = "000019f5-0000-1000-8000-00805f9b34fb";

  static const String _mlAmountCharUUID = "0faf892c-0000-1000-8000-00805f9b34fb";
  static const String _temperatureCharUUID = "00002a6e-0000-1000-8000-00805f9b34fb";
  static const String _timestampCharUUID = "00000fff-0000-1000-8000-00805f9b34fb";
  static const String _canSyncRecordCharUUID = "0faf892f-0000-1000-8000-00805f9b34fb";

  // UUIDs del servicio de batería y sus características.
  static const String _batterySvcUUID = "0000180f-0000-1000-8000-00805f9b34fb";

  static const String _batteryChargeCharUUID = "00002a19-0000-1000-8000-00805f9b34fb";

  // UUIDs del servicio de fecha del dispositivo y sus características.
  static const String _deviceTimeSvcUUID = "00001847-0000-1000-8000-00805f9b34fb";

  static const String _deviceTimeCharUUID = "00002b90-0000-1000-8000-00805f9b34fb";

  static const Map<String, String> recordUUIDsToAttributes = {
    _mlAmountCharUUID: HydrationRecord.amountAttribute,
    _temperatureCharUUID: HydrationRecord.temperatureAttribute,
    _timestampCharUUID: HydrationRecord.dateAttribute,
    _batteryChargeCharUUID: HydrationRecord.batteryChargeAttribute,
  };

  static final Map<String, BytesToValueMapper> _hydrationSvcAttributeMappers = {
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
      } else {
        return null;
      }
    },
  };

  static final Map<String, BytesToValueMapper> _batterySvcAttributeMappers = {
    _batteryChargeCharUUID: (List<int> bytes) => LittleEndianExtractor.extractUint8(bytes),
  };

  static final Map<String, BytesToValueMapper> _deviceTimeSvcAttributeMappers = {
    _deviceTimeCharUUID: (List<int> bytes) {
      if (bytes.isNotEmpty) {
        final secondsSinceEpoch = LittleEndianExtractor.extractInt64(bytes);

        final msSinceEpoch = max((secondsSinceEpoch * 1000), 0);

        return DateTime.fromMillisecondsSinceEpoch(msSinceEpoch);
      } else {
        return null;
      }
    },
  };

  final Set<String> _supportedCharsUUIDs = <String>{ 
    _mlAmountCharUUID,
    _temperatureCharUUID,
    _timestampCharUUID,
    _canSyncRecordCharUUID,
    _batteryChargeCharUUID,
    _deviceTimeCharUUID,
  };

  final Set<String> _charsWithNotifySupport = <String>{ _canSyncRecordCharUUID };

  // El controlador para el Stream que contiene los HydrationRecord obtenidos
  // por BLE desde _underlyingDevice.
  final StreamController<HydrationRecord> _hydrationRecordsController = StreamController.broadcast(); 
  StreamSubscription<List<int>>? _onRecordAvailableSubscription;

  BluetoothDeviceState _deviceState = BluetoothDeviceState.disconnected;

  StreamSubscription<BluetoothDeviceState>? _deviceStateSubscription;

  HydrationRecord? _latestHydrationRecord;

  final List<BluetoothService> _allServices = <BluetoothService>[];

  BluetoothService? _hydrationService;
  BluetoothService? _batteryService;
  BluetoothService? _deviceTimeService;

  final Lock _gattLock = Lock();

  static final Map<DeviceIdentifier, HydrateDevice> _bleDevices = {};

  static const Duration _minDiffToAdjustDevicetime = Duration( seconds: 10 );

  static const Duration _immmediateDuration = Duration( milliseconds: 0 );
  static const Duration _delayOnSubsequentReads = Duration( milliseconds: 400 );
  static const Duration _delayBeforeWriteConfirm = Duration( milliseconds: 400 );

  static const String gattReadErrCode = "read_characteristic_error";
  static const String gattWriteErrCode = "write_characteristic_error";

  void _handleDeviceStateChange(BluetoothDeviceState nextConnectionState) {

    if (_deviceState == nextConnectionState) {
      debugPrint("Ignoring state transition, state and new state are the same.");
      return;
    }

    print("New device state (deviceId = $deviceId): $nextConnectionState");

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

    if (_deviceTimeService != null) {
      await _adjustDeviceTime();
    }

    if (_hydrationService != null) {
      // Activar las notificaciones en ciertas caracteristicas/
      for (final characteristic in _hydrationService!.characteristics) {

        if (_canSetNotifyValue(characteristic)) {
          debugPrint("About to take lock ${_gattLock.hashCode} to set notify value");
          await _gattLock.synchronized(() async {
            debugPrint("gattLock taken to set notify value");
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

  Future<void> _adjustDeviceTime() async {
    DateTime? now;
    final Map<String, Object?> deviceTimeData = {};

    debugPrint("About to take lock ${_gattLock.hashCode} to adjust device time");

    await _gattLock.synchronized(() async {

      debugPrint("gattLock taken to adjust device time");

      try {
        final deviceTimeValues = await _readAttributesFromService(
          _deviceTimeService!, 
          attributes: _deviceTimeSvcAttributeMappers,
          startWithDelay: true
        );

        now = DateTime.now();

        deviceTimeData.addAll(deviceTimeValues);

      } on PlatformException catch (ex) {
        if (ex.code == gattReadErrCode) {
          // La conexión con el dispositivo fue perdida, o el dispositivo fue 
          // desconectado. No es posible sincronizar el registro de hidratación.
          debugPrint("Connection lost, unable to obtain device time");
          return;

        } else {
          debugPrint("""
            Excepcion no manejada leer el valor de una caracteristica del 
            servicio (UUID = ${_hydrationService!.uuid}) : $ex
          """);
        }
      }

      debugPrint("Device time data: $deviceTimeData");

      if (deviceTimeData.containsKey(_deviceTimeCharUUID) && now != null) {
        final DateTime? deviceTime = (deviceTimeData[_deviceTimeCharUUID] as DateTime?);

        final absDeviceTimeDiff = deviceTime?.difference(now!).inSeconds.abs() ?? 0;

        if (absDeviceTimeDiff >= _minDiffToAdjustDevicetime.inSeconds) {
          // Es necesario ajustar la fecha del dispositivo Hydrate.
          for (final characteristic in _deviceTimeService!.characteristics) {
            if (characteristic.uuid.toString() == _deviceTimeCharUUID) {

              final int secondsSinceEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
              final List<int> secondsSinceEpochBytes = LittleEndianExtractor.int64ToBytes(secondsSinceEpoch);

              debugPrint("Seconds since unix epoch: $secondsSinceEpoch, byte value: $secondsSinceEpochBytes");

              try {
                await Future.delayed(
                  _delayOnSubsequentReads,
                  () => characteristic.write(
                    secondsSinceEpochBytes, 
                    withoutResponse: false
                  ),
                );

              } on PlatformException catch (ex) {
                if (ex.code == gattWriteErrCode) {
                  debugPrint("Error al intentar ajustar la fecha del dispositivo: $ex");
                } else {
                  debugPrint("Excepcion inesperada al escribir a la caracteristica con UUID = _deviceTimeCharUUID: $ex");
                }
              }
              break;
            }
          }
        }
      }

      debugPrint("gattLock about to be released");
    });
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

      try {
        final hydrationData = await _readAttributesFromService(
          _hydrationService!, 
          attributes: _hydrationSvcAttributeMappers,
          startWithDelay: true
        );

        hydrationRecordData.addAll(hydrationData);

      } on PlatformException catch (ex) {
        if (ex.code == gattReadErrCode) {
          // La conexión con el dispositivo fue perdida, o el dispositivo fue 
          // desconectado. No es posible sincronizar el registro de hidratación.
          debugPrint("Connection lost, can't sync hydration");
          return;

        } else {
          debugPrint("""
            Excepcion no manejada leer el valor de una caracteristica del 
            servicio (UUID = ${_hydrationService!.uuid}) : $ex
          """);
        }
      }

      try {
        final batteryData = await _readAttributesFromService(
          _batteryService!, 
          attributes: _batterySvcAttributeMappers,
          startWithDelay: true
        );
      
        hydrationRecordData.addAll(batteryData);

      } on PlatformException catch (ex) {
        if (ex.code == gattReadErrCode) {
          // La conexión con el dispositivo fue perdida, o el dispositivo fue 
          // desconectado. No es posible sincronizar el registro de hidratación.
          debugPrint("Connection lost, can't sync hydration");
          return;

        } else {
          debugPrint("""
            Excepcion no manejada leer el valor de una caracteristica del 
            servicio (UUID = ${_hydrationService!.uuid}) : $ex
          """);
        }
      }

      final int expectedAttributeCount = _hydrationSvcAttributeMappers.length + _batterySvcAttributeMappers.length;

      if (hydrationRecordData.length == expectedAttributeCount) {
        final newHydrationRecord = HydrationRecord.fromMap(_transformRxMap(hydrationRecordData));

        await _confirmRecordReceived();

        _latestHydrationRecord = newHydrationRecord;

        _addLatestHydrationRecordToStream();
      } else {
        debugPrint("""
          Warning: missing/exceeding attributes read from services (expected 
          $expectedAttributeCount, got ${hydrationRecordData.length}
        """);
      }
    });
  }

  // Funciones de utilidad

  void _onServicesDiscovered(List<BluetoothService> services) {
    _hydrationService = null;
    _batteryService = null;
    _deviceTimeService = null;

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
        case _deviceTimeSvcUUID:
          _deviceTimeService = service;
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

        } on PlatformException catch (ex) {
          if (ex.code != gattWriteErrCode) {
            debugPrint("Excepcion inesperada al escribir a la caracteristica con UUID = _canSyncRecordCharUUID: $ex");
          }
          debugPrint("Error al intentar confirmar sincronizacion.");
          couldConfirm = false;
        }

        break;
      }
    }

    return couldConfirm;
  }

  Future<Map<String, Object?>> _readAttributesFromService(
    BluetoothService service, { 
      required Map<String, BytesToValueMapper> attributes,
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

        final Iterable<int> bytesRead = await Future.delayed(
          (!isFirstRead || startWithDelay) ? _delayOnSubsequentReads : _immmediateDuration,
          () => characteristic.read()
        );

        charValueBytes.addAll(bytesRead);

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

    if (record != null && record.id < 0) {
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
  int get hashCode => Object.hashAll([
    deviceId,
    _gattLock,
  ]);
}

class DeviceStateSink implements EventSink<BluetoothDeviceState> {

  DeviceStateSink(this._outputSink);
  
  final EventSink<BluetoothDeviceState> _outputSink;

  BluetoothDeviceState? _previousDeviceState;

  @override
  void add(BluetoothDeviceState newDeviceState) {
    if (newDeviceState != _previousDeviceState) {
      _previousDeviceState = newDeviceState;
      _outputSink.add(newDeviceState);
    }
  }

  @override
  void addError(e, [st]) { _outputSink.addError(e, st); }
  @override
  void close() { _outputSink.close(); }
}

class DeviceStateTransformer extends StreamTransformerBase<BluetoothDeviceState, BluetoothDeviceState> {

  @override
  Stream<BluetoothDeviceState> bind(Stream<BluetoothDeviceState> stream) => Stream<BluetoothDeviceState>.eventTransformed(
      stream,
      (EventSink<BluetoothDeviceState> sink) => DeviceStateSink(sink));
}