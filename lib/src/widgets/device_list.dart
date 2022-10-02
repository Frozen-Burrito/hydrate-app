import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hydrate_app/src/models/hydrate_device.dart';
import 'package:hydrate_app/src/services/device_pairing_service.dart';
import 'package:hydrate_app/src/widgets/data_placeholder.dart';

import 'package:hydrate_app/src/widgets/scan_result_tile.dart';
import 'package:provider/provider.dart';

/// Un widget con una lista de dispositivos conectados y otra de dispositivos 
/// descubiertos.
class BleDeviceList extends StatelessWidget {

  const BleDeviceList({ Key? key }) : super(key: key);

  Future<bool> _handleConnectToDevice(BuildContext context, HydrateDevice device) async {
    final devicePairingService = Provider.of<DevicePairingService>(context, listen: false);

    final deviceIsSelected = await devicePairingService.setSelectedDevice(device);

    // Si el usuario se conectó a un dispositivo diferente, y la app tiene 
    // permiso de administrar Bluetooth sin interacción del usuario, perguntarle
    // usando un Dialog si desea configurar el emparejamiento automático.
    if (devicePairingService.getBondedDeviceId() != device.deviceId) {
      
      final shouldSetUpAutoconnect = await showDialog(
        context: context, 
        builder: (context) => const _PromptAutoconnectDialog()
      ); 

      if (shouldSetUpAutoconnect) {
        // El usuario desea activar el emparejamiento automático.
        devicePairingService.enableAutoBondingToPairedDevice();
      }
    }

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
                  initialData: devicePairingService.latestSelectedDevice,
                  builder: (context, snapshot) {

                    if (snapshot.hasData) {
                      // Hay un dispositivo emparejado actual.
                      final device = snapshot.data!;

                      return _DeviceTile(
                        device: device,
                        onDisconnect: () => devicePairingService.setSelectedDevice(null),
                        onConnect: () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(context);

                          final snackBar = await _handleDeviceConnectTap(context, device);

                          scaffoldMessenger.removeCurrentSnackBar();
                          scaffoldMessenger.showSnackBar(snackBar);
                        },
                      );
                    } else {
                      return const Center(
                        child: DataPlaceholder(
                          message: "No has emparejado una extensión Hydrate. Revisa la lista inferior para descubrir dispositivos cercanos.",
                          icon: Icons.link_off,
                        ),
                      );
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
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Consumer<DevicePairingService>(
                builder: (_, devicePairingService, __) {

                  final bondedDeviceId = devicePairingService.getBondedDeviceId();
                  final bondedDeviceIsThisDevice = device.deviceId == bondedDeviceId;

                  if (bondedDeviceIsThisDevice) {
                    return Tooltip(
                      message: "Olvidar dispositivo",
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: Colors.orangeAccent.shade400,
                        ),
                        onPressed: () => devicePairingService.clearBondedDeviceId(), 
                        child: const Icon(Icons.highlight_off),
                      ),
                    );
                  } else {
                    return Tooltip(
                      message: "Activar conexión automática",
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: Colors.green.shade400,
                        ),
                        onPressed: () => devicePairingService.setBondedDeviceId(device.deviceId),
                        child: const Icon(Icons.auto_awesome),
                      ),
                    );
                  }
                }
              ),

              const SizedBox( width: 8.0, ),

              _ConnectDisconnectButton(
                deviceState: snapshot.data ?? BluetoothDeviceState.disconnected,
                onConnect: onConnect,
                onDisconnect: onDisconnect,
              ),
            ],
          );
        },
      ),
    );
  }
} 

class _ConnectDisconnectButton extends StatelessWidget {

  const _ConnectDisconnectButton({
    Key? key,
    required this.deviceState, 
    this.onConnect, 
    this.onDisconnect,
  }) : super(key: key);

  final BluetoothDeviceState deviceState;

  final void Function()? onConnect;
  final void Function()? onDisconnect;

  @override
  Widget build(BuildContext context) {
    //TODO: Agregar i18n
    if (deviceState == BluetoothDeviceState.connected) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: Colors.red.shade400
        ),
        child: const Icon(Icons.phonelink_erase),
        onPressed: onDisconnect, 
      );
    } else if (deviceState == BluetoothDeviceState.disconnected) {
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
  }
}

class _PromptAutoconnectDialog extends StatelessWidget {

  const _PromptAutoconnectDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //TODO: Agregar i18n.
    return AlertDialog(
      title: const Text("¿Configurar conexión automática?"),
      content: const Text("El dispositivo ha sido emparejado. ¿Deseas que la app intente conectarse a él de manera automática en el futuro?"),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text("No"),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: const Text("Sí"),
        ),
      ],
    );
  }
}