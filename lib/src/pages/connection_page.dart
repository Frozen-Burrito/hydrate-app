import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';
import 'package:hydrate_app/src/widgets/device_list.dart';
import 'package:hydrate_app/src/widgets/ble_off.dart';

class ConnectionPage extends StatelessWidget {
  
  const ConnectionPage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          CustomSliverAppBar(
            title: 'Conecta Tu Botella',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: <Widget> [
              IconButton(
                icon: const Icon(Icons.info),
                onPressed: () {}, 
              )
            ],
          ),
        
          SliverToBoxAdapter(
            child: StreamBuilder<BluetoothState>(
              stream: FlutterBlue.instance.state,
              initialData: BluetoothState.unknown,
              builder: (context, AsyncSnapshot<BluetoothState> stateSnapshot) {
                final state = stateSnapshot.data;
                
                return (state == BluetoothState.on) 
                  ? const BleDeviceList() 
                  : BleOFF(state: state);
              }
            ),
          ),
        ]
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (context, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              child: const Icon(Icons.stop),
              backgroundColor: Theme.of(context).colorScheme.error,
              onPressed: () => FlutterBlue.instance.stopScan(),
            );
          } else {
            return FloatingActionButton(
              child: const Icon(Icons.search),
              backgroundColor: Theme.of(context).colorScheme.primary,
              onPressed: () => FlutterBlue.instance.startScan(timeout: const Duration(seconds: 4)),
            );
          }
        }
      ),
    );
  }
}