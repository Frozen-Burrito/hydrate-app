
import 'package:flutter_blue/flutter_blue.dart';

class BleBottleExtension {

  // static final Guid primaryServiceUUID = Guid("0000d7f0-1100-1000-8000-00805f9b34fb");
  static final Guid primaryServiceUUID = Guid("000019f5-0000-1000-8000-00805f9b34fb");

  final BluetoothDevice _device;

  BleBottleExtension(this._device);

  BluetoothDevice get device => _device; 

  String get id => _device.id.toString();
}