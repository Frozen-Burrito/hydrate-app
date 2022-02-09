import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class ScanResultTile extends StatelessWidget {

  final ScanResult result;
  final VoidCallback onTap;

  const ScanResultTile({ 
    Key? key, 
    required this.result, 
    required this.onTap 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(result.rssi.toString()),
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[

          (result.device.name.isNotEmpty) ? Text(result.device.name) : Container(),

          Text(result.device.id.toString()),
        ],
      ),
      trailing: ElevatedButton(
        child: const Icon(Icons.phonelink_ring),
        onPressed: (result.advertisementData.connectable) ? onTap : null,
      ),
    );
  }
}