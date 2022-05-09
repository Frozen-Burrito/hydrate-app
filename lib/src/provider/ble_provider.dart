import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:hydrate_app/src/models/ble_bottle_extension.dart';

class BleProvider extends ChangeNotifier {

  BleBottleExtension? _connectedExtension;

  BleBottleExtension? get connectedExtension => _connectedExtension; 

  final Duration scanDuration = const Duration(seconds: 4);

  final connectedDevices = Stream.periodic(const Duration(seconds: 3))
    .asyncMap((_) => FlutterBlue.instance.connectedDevices);

  final Stream<BluetoothState> state = FlutterBlue.instance.state;

  final Stream<bool> isScanning = FlutterBlue.instance.isScanning;

  BleProvider({ Guid? prevDeviceId });

  Iterable<ScanResult> filterScanResults(List<ScanResult> scanResults) {
    return scanResults.where((result) {
      bool hasService = result.advertisementData.serviceUuids
        .contains(BleBottleExtension.primaryServiceUUID);

      bool isNotCurrentDevice = (_connectedExtension == null ||
        _connectedExtension?.id == result.device.id.toString());

      return hasService && isNotCurrentDevice;
    });
  }
}