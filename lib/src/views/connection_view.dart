import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/models/api.dart';
import 'package:hydrate_app/src/services/device_pairing_service.dart';
import 'package:hydrate_app/src/utils/launch_url.dart';
import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';
import 'package:hydrate_app/src/widgets/data_placeholder.dart';
import 'package:hydrate_app/src/widgets/device_list.dart';
import 'package:provider/provider.dart';

class ConnectionView extends StatelessWidget {
  
  const ConnectionView({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final _ = Provider.of<DevicePairingService>(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
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

          SliverToBoxAdapter(
            child: Consumer<DevicePairingService>(
              builder: (_, devicePairingService, __) {
                return StreamBuilder<BluetoothState>(
                  stream: devicePairingService.state,
                  initialData: BluetoothState.unknown,
                  builder: (context, snapshot) {
          
                    final bleIsOn = snapshot.data == BluetoothState.on;
          
                    if (bleIsOn) {
                      return const BleDeviceList();
                    } else {
                      return DataPlaceholder(
                        message: localizations.bleNotAvailable + "\n" + localizations.tryLocAndBt,
                        icon: Icons.bluetooth_disabled
                      );
                    }
                  }
                );
              },
            ),
          ),
        ]
      ),
      floatingActionButton: Consumer<DevicePairingService>(
        builder: (_, devicePairingService, __) {

          return StreamBuilder<BluetoothState>(
            stream: devicePairingService.state,
            builder: (context, snapshot) {

              final bleIsOn = snapshot.data == BluetoothState.on;

              return StreamBuilder<bool>(
                stream: devicePairingService.isScanInProgress,
                initialData: false,
                builder: (context, snapshot) {

                  final isScanInProgress = snapshot.data ?? false;

                  if (isScanInProgress) {
                    return FloatingActionButton(
                      child: const Icon(Icons.stop),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      onPressed: devicePairingService.cancelScanResultsRefresh,
                    );
                    
                  } else {
                    return FloatingActionButton(
                      tooltip: localizations.scan,
                      child: const Icon(Icons.search),
                      backgroundColor: (bleIsOn) ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor,
                      onPressed: (bleIsOn) 
                          ? () => devicePairingService.refreshScanResults()
                          : null,
                    );
                  }
                }
              );
            }
          );
        }
      ),
    );
  }
}