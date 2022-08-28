import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/models/api.dart';
import 'package:hydrate_app/src/utils/launch_url.dart';
import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';
import 'package:hydrate_app/src/widgets/data_placeholder.dart';
import 'package:hydrate_app/src/widgets/device_list.dart';

class ConnectionPage extends StatelessWidget {
  
  const ConnectionPage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;

    return StreamBuilder<BluetoothState>(
      stream: FlutterBlue.instance.state,
      initialData: BluetoothState.unknown,
      builder: (context, AsyncSnapshot<BluetoothState> stateSnapshot) {
        final state = stateSnapshot.data;

        return  Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              CustomSliverAppBar(
                title: localizations.pairDevice,
                leading: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.arrow_back), 
                    onPressed: () => Navigator.pop(context)
                  ),
                ],
                actions: <Widget> [
                  IconButton(
                    icon: const Icon(Icons.help),
                    onPressed: () => UrlLauncher.launchUrlInBrowser(API.uriFor('guias-conexion')), 
                  )
                ],
              ),

              (state == BluetoothState.on) 
                ? const SliverToBoxAdapter(
                  child: BleDeviceList()
                ) 
                : SliverToBoxAdapter(
                  child: DataPlaceholder(
                    message: localizations.bleNotAvailable + '\n' + localizations.tryLocAndBt,
                    //TODO: Eliminar los detalles.
                    details: '(state is "${state != null ? state.toString().substring(15) : 'not available'}")',
                    icon: Icons.bluetooth_disabled
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
                  tooltip: localizations.scan,
                  child: const Icon(Icons.search),
                  backgroundColor: (state == BluetoothState.on) ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor,
                  onPressed: (state == BluetoothState.on) 
                      ? () => FlutterBlue.instance.startScan(timeout: const Duration(seconds: 4))
                      : null,
                );
              }
            }
          ),
        );
      }
    );
  }
}