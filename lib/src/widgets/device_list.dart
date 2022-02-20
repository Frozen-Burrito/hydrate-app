import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:hydrate_app/src/widgets/scan_result_tile.dart';

/// Un widget con una lista de dispositivos conectados y otra de dispositivos 
/// descubiertos.
class BleDeviceList extends StatelessWidget {
  const BleDeviceList({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => FlutterBlue.instance.startScan(timeout: const Duration(seconds: 4)),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget> [

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Botella conectada',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),

            const Divider(height: 10,),

            StreamBuilder<List<BluetoothDevice>>(
              stream: Stream.periodic( const Duration(seconds: 2))
                            .asyncMap((_) => FlutterBlue.instance.connectedDevices),
              initialData: [],
              builder: (BuildContext context, AsyncSnapshot<List<BluetoothDevice>> snapshot) => Column(
                children: snapshot.data! //TODO: Buscar una forma mas eficiente
                    .map((device) => ListTile(
                      title: Text(device.name),
                      subtitle: Text(device.id.toString()),
                      trailing: StreamBuilder<BluetoothDeviceState>(
                        stream: device.state,
                        initialData: BluetoothDeviceState.disconnected,
                        builder: (context, snapshot) {
                          if (snapshot.data == BluetoothDeviceState.connected) {
                            return ElevatedButton(
                              // style: ButtonStyle(backgroundColor: MaterialColor),
                              child: const Icon(Icons.phonelink_erase),
                              onPressed: () => device.disconnect(), 
                            );
                          } else {
                            return const CircularProgressIndicator();
                          }
                        },
                      ),
                    ))
                    .toList(),
              )
            ),

            const SizedBox( height: 32,),

            StreamBuilder<List<ScanResult>> (
              stream: FlutterBlue.instance.scanResults,
              initialData: const [],
              builder: (context, snapshot) => Column(
                children: snapshot.data!.map((scanResult) => ScanResultTile(
                  result: scanResult,
                  onTap: () => scanResult.device.connect(),
                )).toList(),
              )
            ),
          ],
        ),
      ),
    );
  }
}