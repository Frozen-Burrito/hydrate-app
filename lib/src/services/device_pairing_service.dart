import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:hydrate_app/src/models/hydrate_device.dart';
import 'package:hydrate_app/src/models/hydration_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef HydrationRecordCallback = void Function(HydrationRecord);

class DevicePairingService extends ChangeNotifier {

  DevicePairingService({ this.autoConnectToBondedDevice = false }) {
    _refreshScanResultsController.stream.listen((refreshRequest) {
      if (refreshRequest) {
        _scanForDevices();
      } else {
        _stopScan();
      }
    });

    _selectedDeviceController.onListen = () {
      _selectedDeviceController.add(_pairedDevice);
    };

    final connectedDevicesStream = Stream.periodic(const Duration( seconds: 3 ))
      .asyncMap((_) => FlutterBlue.instance.connectedDevices);

    connectedDevicesStream.listen((connectedDevices) { 
      if (connectedDevices.isNotEmpty && _pairedDevice == null) {
        debugPrint("Paired device updated from connectedDevices list");
        final hydrateDevice = HydrateDevice.fromBleDevice(
          connectedDevices.first, 
          isAlreadyConnected: true
        );

        setSelectedDevice(hydrateDevice);
      } else if (connectedDevices.isEmpty && _pairedDevice != null && _pairedDevice!.isDisconnected) {
        debugPrint("No devices connected, selectedDevice set to null");
        // setSelectedDevice(null);
      }
    });

    scanResults.listen((scanResults) async {
      final bondedDeviceId = getBondedDeviceId();
      // El dispositivo asociado ya está emparejado.
      if (bondedDeviceId == _pairedDevice?.deviceId || _hasManuallyDisconnectedFromBondedDevice) {
        return;
      }

      final scanResultsMatchingBondedDevice = scanResults
          .where((scanResult) => scanResult.device.id == bondedDeviceId,);

      if (scanResultsMatchingBondedDevice.length == 1) {
        debugPrint("Found a scan result that can be paired, based on user preferences");
        final hydrateDevice = HydrateDevice.fromBleDevice(scanResultsMatchingBondedDevice.first.device);
        await setSelectedDevice(hydrateDevice);
      }
    });
  }

  Stream<BluetoothState> get state => FlutterBlue.instance.state;
  Stream<bool> get isScanInProgress => FlutterBlue.instance.isScanning;

  Stream<HydrateDevice?> get selectedDevice => _selectedDeviceController.stream;

  Stream<List<ScanResult>> get scanResults => _scanResults; 

  final Map<String, StreamSubscription<HydrationRecord>?> _onNewHydrationSubscriptions = {};
  final Map<String, HydrationRecordCallback> _onNewHydrationListeners = {};

  void addOnNewHydrationRecordListener(String listenerKey, HydrationRecordCallback onNewHydrationRecord) {
    _onNewHydrationListeners[listenerKey] = onNewHydrationRecord;

    if (_pairedDevice != null && _pairedDevice!.isConnected) {
      _onNewHydrationSubscriptions[listenerKey] = _pairedDevice?.hydrationRecords
          .listen(onNewHydrationRecord);
    } else {
      _onNewHydrationSubscriptions[listenerKey] = null;
    }

    debugPrint("New hydration record listener (${_onNewHydrationSubscriptions.length} total): $listenerKey");
  }

  void removeHydrationRecordListener(String listenerKey) {
    _onNewHydrationListeners.remove(listenerKey);

    _onNewHydrationSubscriptions[listenerKey]?.cancel();
    _onNewHydrationSubscriptions.remove(listenerKey);
  }

  void refreshScanResults() {
    _refreshScanResultsController.sink.add(true);
  }

  void cancelScanResultsRefresh() {
    _refreshScanResultsController.sink.add(false);
  }

  Future<bool> setSelectedDevice(HydrateDevice? newDevice, { bool saveAsBonded = false, }) async {
    // Ya esta emparejado y seleccionado newDevice, no es necesario hacer nada
    // mas.
    if (newDevice == _pairedDevice) return true;

    bool wasDeviceSet = false; 

    try {
      // Cancelar todas las subcripciones a eventos de nuevos registros de 
      // hidratacion con el dipositivo anterior.
      for (final hydrationRecordListener in _onNewHydrationSubscriptions.entries) { 
        final listenerKey = hydrationRecordListener.key;

        debugPrint("Cancelling subscription of hydration records listener: $listenerKey");
        _onNewHydrationSubscriptions[listenerKey]?.cancel();
        _onNewHydrationSubscriptions[listenerKey] = null;
      }

      _hasManuallyDisconnectedFromBondedDevice = _pairedDevice?.deviceId == getBondedDeviceId();

      await _pairedDevice?.disconnect();

      if (newDevice != null && newDevice.isDisconnected) {
        await newDevice.connect();
      }

      _pairedDevice = newDevice;

      _selectedDeviceController.sink.add(_pairedDevice);

      _scanResultsFilter.currentConnectedDeviceId = _pairedDevice?.deviceId;
      refreshScanResults();

      debugPrint("New paired device: $_pairedDevice");

      if (_pairedDevice != null) {
        for (final hydrationRecordListener in _onNewHydrationSubscriptions.entries) { 
          final listenerKey = hydrationRecordListener.key;

          debugPrint("Adding hydration records listener: $listenerKey");
          _onNewHydrationSubscriptions[listenerKey] = _pairedDevice?.hydrationRecords
              .listen(_onNewHydrationListeners[listenerKey]!);
        }
      }

      wasDeviceSet = true;

    } on PlatformException catch (ex) {
      debugPrint("Error al definir el dispositivo conectado: $ex");
    }

    return wasDeviceSet;
  }

  Future<void> enableAutoBondingToPairedDevice() async {

    final deviceId = _pairedDevice?.deviceId;

    if (deviceId != null) {
      await setBondedDeviceId(deviceId);
    }
  }

  final StreamController<HydrateDevice?> _selectedDeviceController = StreamController.broadcast();
  final StreamController<bool> _refreshScanResultsController = StreamController.broadcast();

  final Stream<List<ScanResult>> _scanResults = FlutterBlue.instance.scanResults.transform(_scanResultsFilter);

  static final ScanResultsTransformer _scanResultsFilter = ScanResultsTransformer();

  final bool autoConnectToBondedDevice;
  bool _hasManuallyDisconnectedFromBondedDevice = false;

  HydrateDevice? _pairedDevice;

  static const Duration _automaticScanInterval = Duration(seconds: 10);
  static const Duration _scanDuration = Duration(seconds: 4);

  Future<void> _scanForDevices() async {
    await FlutterBlue.instance.stopScan();
    await FlutterBlue.instance.startScan(timeout: _scanDuration);
  }

  Future<void> _stopScan() async {
    await FlutterBlue.instance.stopScan();
  }

  static const String _bondedDeviceIdKey = "bondend_device_id";

  static late final SharedPreferences? _sharedPreferences;

  /// Inicializa y asigna la instancia de Shared Preferences.
  static Future<void> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  DeviceIdentifier? getBondedDeviceId() {
    final deviceUUID = _sharedPreferences?.getString(_bondedDeviceIdKey) ?? "";

    return deviceUUID.isNotEmpty ? DeviceIdentifier(deviceUUID) : null;
  }

  Future<bool> setBondedDeviceId(DeviceIdentifier bondedDeviceId) async {
    final savedBondedId = await _sharedPreferences
      ?.setString(_bondedDeviceIdKey, bondedDeviceId.toString()) ?? false;


    if (savedBondedId) {
      notifyListeners();
    }
    return savedBondedId;
  }

  Future<bool> clearBondedDeviceId() => setBondedDeviceId(const DeviceIdentifier(""));

  @override
  bool operator==(covariant DevicePairingService other) {

    final hasSamePairedDevice = _pairedDevice == other._pairedDevice;
    final hasSamePairedDeviceController = _selectedDeviceController == other._selectedDeviceController;

    return hasSamePairedDevice && hasSamePairedDeviceController;
  }
  
  @override
  int get hashCode => Object.hashAll([ _pairedDevice, _selectedDeviceController ]);
}

class SupportedDeviceFilterSink implements EventSink<List<ScanResult>> {

  SupportedDeviceFilterSink(this._outputSink, this._currentConnectedDeviceId);
  
  final EventSink<List<ScanResult>> _outputSink;

  final DeviceIdentifier? _currentConnectedDeviceId;
  static const List<String> supportedDeviceNames = [ "Hydrate" ];
  static final List<String> supportedAdvertisedServices = [ 
    HydrateDevice.hydrationSvcUUID
  ];

  @override
  void add(List<ScanResult> scanResults) {

    final List<ScanResult> filteredScanResults = <ScanResult>[];

    for (final scanResult in scanResults) {
      final hasSupportedName = supportedDeviceNames.any(
        (deviceName) => scanResult.device.name.contains(deviceName)
      );
      final hasSupportedServices = scanResult.advertisementData.serviceUuids.any(
        (serviceUuid) => supportedAdvertisedServices.contains(serviceUuid)
      );

      final isNotCurrentlyConnectedDevice = scanResult.device.id != _currentConnectedDeviceId;

      if (hasSupportedName && hasSupportedServices && isNotCurrentlyConnectedDevice) {
        filteredScanResults.add(scanResult);
      }
    }
    _outputSink.add(filteredScanResults);
  }

  @override
  void addError(e, [st]) { _outputSink.addError(e, st); }
  @override
  void close() { _outputSink.close(); }
}

class ScanResultsTransformer extends StreamTransformerBase<List<ScanResult>, List<ScanResult>> {

  DeviceIdentifier? _currentConnectedDeviceId;

  set currentConnectedDeviceId(DeviceIdentifier? newConnectedDeviceId) => _currentConnectedDeviceId = newConnectedDeviceId;

  @override
  Stream<List<ScanResult>> bind(Stream<List<ScanResult>> stream) => Stream<List<ScanResult>>.eventTransformed(
      stream,
      (EventSink<List<ScanResult>> sink) => SupportedDeviceFilterSink(sink, _currentConnectedDeviceId));
}