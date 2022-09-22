import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hydrate_app/src/models/hydrate_device.dart';
import 'package:hydrate_app/src/services/device_pairing_service.dart';
import 'package:hydrate_app/src/services/hydration_record_provider.dart';

import 'package:hydrate_app/src/widgets/scan_result_tile.dart';
import 'package:provider/provider.dart';

/// Un widget con una lista de dispositivos conectados y otra de dispositivos 
/// descubiertos.
class BleDeviceList extends StatelessWidget {

  const BleDeviceList({ Key? key }) : super(key: key);

  Future<bool> _handleConnectToDevice(BuildContext context, HydrateDevice device) async {
    final devicePairingService = Provider.of<DevicePairingService>(context, listen: false);
    final hydrationRecordService = Provider.of<HydrationRecordService>(context, listen: false);

    devicePairingService.addOnNewHydrationRecordListener(hydrationRecordService.saveHydrationRecord);

    final deviceIsSelected = await devicePairingService.setSelectedDevice(device);

    return deviceIsSelected;
  }

  Future<SnackBar> _handleDeviceConnectTap(BuildContext context, HydrateDevice device) async {

    final deviceWasConnected = await _handleConnectToDevice(context, device);

    final String confirmationMsg = deviceWasConnected
      ? "Dispositivo conectado"
      : "No se pudo conectar el dispositivo";

    return SnackBar(content: Text(confirmationMsg));
  }

  Future<SnackBar> _handleScanResultTap(BuildContext context, ScanResult scanResult) async {

    final hydrateDevice = HydrateDevice.fromBleDevice(scanResult.device);

    final deviceWasConnected = await _handleConnectToDevice(context, hydrateDevice);

    final String confirmationMsg = deviceWasConnected
      ? "Dispositivo conectado"
      : "No se pudo conectar el dispositivo";

    return SnackBar(content: Text(confirmationMsg));
  }

  Future<void> _handleListRefresh(BuildContext context) async {
    final devicePairingService = Provider.of<DevicePairingService>(context, listen: false);

    devicePairingService.refreshScanResults();

    await devicePairingService.isScanInProgress.firstWhere((scanning) => !scanning);
  }

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: () async => await _handleListRefresh(context),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget> [

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                localizations.connectedDevice,
                style: Theme.of(context).textTheme.bodyText1,
              ),
            ),

            const Divider(height: 10,),

            Consumer<DevicePairingService>(
              builder: (_, devicePairingService, __) {
                return StreamBuilder<HydrateDevice?>(
                  stream: devicePairingService.selectedDevice,
                  builder: (context, snapshot) {

                    final device = snapshot.data;

                    if (device != null) {
                      return _DeviceTile(
                        device: device,
                        onDisconnect: () {
                          devicePairingService.setSelectedDevice(null);
                        },
                        onConnect: () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(context);

                          final snackBar = await _handleDeviceConnectTap(context, device);

                          scaffoldMessenger.removeCurrentSnackBar();
                          scaffoldMessenger.showSnackBar(snackBar);
                        },
                      );
                    } else {
                      return const SizedBox( height: 0.0, );
                    }
                  }
                );
              }
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                localizations.availableDevices,
                style: Theme.of(context).textTheme.bodyText1,
              ),
            ),

            const Divider(height: 10,),

            Consumer<DevicePairingService>(
              builder: (_, devicePairingService, __) {
                return StreamBuilder<List<ScanResult>> (
                  stream: devicePairingService.scanResults,
                  initialData: const [],
                  builder: (context, snapshot) {
                    return Column(
                      children: snapshot.data!.map((scanResult) => ScanResultTile(
                        result: scanResult,
                        onTap: () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(context);

                          final snackBar = await _handleScanResultTap(context, scanResult);

                          scaffoldMessenger.removeCurrentSnackBar();
                          scaffoldMessenger.showSnackBar(snackBar);
                        },
                      )).toList(),
                    );
                  }
                );
              }
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {

  const _DeviceTile({
    Key? key,
    required this.device,
    this.onConnect,
    this.onDisconnect,
  }) : super(key: key);

  final HydrateDevice device;

  final void Function()? onConnect;
  final void Function()? onDisconnect;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(device.name),
      subtitle: Text(device.deviceId.toString()),
      trailing: StreamBuilder<BluetoothDeviceState>(
        stream: device.connectionState,
        initialData: BluetoothDeviceState.disconnected,
        builder: (context, snapshot) {
          if (snapshot.data == BluetoothDeviceState.connected) {
            return ElevatedButton(
              child: const Icon(Icons.phonelink_erase),
              onPressed: onDisconnect, 
            );
          } else if (snapshot.data == BluetoothDeviceState.disconnected) {
            return Tooltip(
              message: "Reconectar dispositivo",
              child: ElevatedButton(
                child: const Icon(Icons.phonelink_ring),
                onPressed: onConnect, 
              ),
            );
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}