import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

/// Muestra el [state] actual de BLE en el dispositivo.
class BleOFF extends StatelessWidget {

  final BluetoothState? state;

  const BleOFF({ Key? key, this.state }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.bluetooth_disabled,
            size: 200.0,
            // color: Colors.white54,
          ),

          Text('Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.'),
        ],
      ),
    );
  }
}
