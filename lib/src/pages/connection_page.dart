import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'package:hydrate_app/src/widgets/custom_toolbar.dart';
import 'package:hydrate_app/src/widgets/device_list.dart';
import 'package:hydrate_app/src/widgets/ble_off.dart';

class ConnectionPage extends StatelessWidget {
  
  const ConnectionPage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView( //TODO: Implementar CustomScrollView con slivers.
        child: Column(
          children: <Widget> [
            CustomToolbar(
              title: 'Conecta Tu Botella',
              startActions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                )
              ],
              endActions: <Widget> [
                IconButton(
                  icon: const Icon(Icons.info),
                  onPressed: () {}, 
                )
              ],
            ),
          
            StreamBuilder<BluetoothState>(
              stream: FlutterBlue.instance.state,
              initialData: BluetoothState.unknown,
              builder: (context, AsyncSnapshot<BluetoothState> stateSnapshot) {
                final state = stateSnapshot.data;
      
                return (state == BluetoothState.on) 
                  ? const BleDeviceList() 
                  : BleOFF(state: state);
              }
            )
          ],
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (context, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              child: const Icon(Icons.stop),
              backgroundColor: Colors.red[400],
              onPressed: () => FlutterBlue.instance.stopScan(),
            );
          } else {
            return FloatingActionButton(
              child: const Icon(Icons.search),
              onPressed: () => FlutterBlue.instance.startScan(timeout: const Duration(seconds: 4)),
            );
          }
        }
      ),
    );
  }
}