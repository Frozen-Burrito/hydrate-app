import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:hydrate_app/src/models/hydrate_device.dart';
import 'package:hydrate_app/src/models/hydration_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        setSelectedDevice(HydrateDevice.fromBleDevice(connectedDevices.first));
      }
    });
  }

  Stream<BluetoothState> get state => FlutterBlue.instance.state;
  Stream<bool> get isScanInProgress => FlutterBlue.instance.isScanning;

  Stream<HydrateDevice?> get selectedDevice => _selectedDeviceController.stream;

  Stream<List<ScanResult>> get scanResults 
      => FlutterBlue.instance.scanResults.transform(_scanResultsFilter);

  final List<void Function(HydrationRecord)> _onNewHydrationListeners = [];

  void addOnNewHydrationRecordListener(void Function(HydrationRecord) hydrationRecordListener) {
    _onNewHydrationListeners.add(hydrationRecordListener);
  }

  void refreshScanResults() {
    _refreshScanResultsController.sink.add(true);
  }

  void cancelScanResultsRefresh() {
    _refreshScanResultsController.sink.add(false);
  }

  Future<bool> setSelectedDevice(HydrateDevice? newDevice, { bool saveAsBonded = false, }) async {

    bool wasDeviceSet = false; 

    try {
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
        for (final onHydrationRecordCallback in _onNewHydrationListeners) { 
          debugPrint("Adding hydration records listener: $onHydrationRecordCallback");
          _pairedDevice!.hydrationRecords.listen(onHydrationRecordCallback);
        }
      }

      wasDeviceSet = true;

    } on Exception catch (ex) {
      debugPrint("Error al definir el dispositivo conectado: $ex");
    }

    return wasDeviceSet;
  }

  final StreamController<HydrateDevice?> _selectedDeviceController = StreamController.broadcast();
  final StreamController<bool> _refreshScanResultsController = StreamController.broadcast();

  final ScanResultsTransformer _scanResultsFilter = ScanResultsTransformer();

  final bool autoConnectToBondedDevice;

  HydrateDevice? _pairedDevice;

  final Duration _scanDuration = const Duration(seconds: 4);

  Future<void> _scanForDevices() async {
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

  DeviceIdentifier _getBondedDeviceId() {
    final deviceUUID = _sharedPreferences?.getString(_bondedDeviceIdKey) ?? "";

    return DeviceIdentifier(deviceUUID);
  }

  Future<bool> _setBondedDeviceId(DeviceIdentifier bondedDeviceId) async {
    final savedBondedId = await _sharedPreferences?.setString(_bondedDeviceIdKey, bondedDeviceId.toString());
    return savedBondedId ?? false;
  }

  Future<bool> _clearBondedDeviceId() => _setBondedDeviceId(const DeviceIdentifier(""));

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