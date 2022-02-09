import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:hydrate_app/src/widgets/scan_result_tile.dart';

class BleDeviceList extends StatelessWidget {
  const BleDeviceList({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => FlutterBlue.instance.startScan(timeout: const Duration(seconds: 4)),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget> [
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