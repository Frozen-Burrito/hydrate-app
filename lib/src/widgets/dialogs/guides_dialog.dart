import 'package:flutter/material.dart';
import 'package:hydrate_app/src/models/api.dart';
import 'package:hydrate_app/src/provider/settings_provider.dart';
import 'package:hydrate_app/src/utils/launch_url.dart';
import 'package:provider/provider.dart';

class GuidesDialog extends StatelessWidget {
  const GuidesDialog({Key? key}) : super(key: key);

  //TODO: Agregar localizaciones. 
  @override
  Widget build(BuildContext context) {

    final settingsProvider = Provider.of<SettingsProvider>(context);

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: const [
          Icon( Icons.tips_and_updates ),

          Text('Primeros Pasos'),
        ],
      ),
      content: const Text('Las guías de usuario son un recurso que te puede ayudar a usar esta app y tu extensión para botellas. ¿Te gustaría revisarlas?'),
      actions: [
        TextButton(
          onPressed: () {
            settingsProvider.appStartups = 5;
            Navigator.pop(context);
          }, 
          child: const Text('No Volver a Mostrar'),
        ),
        TextButton(
          onPressed: () {
            UrlLauncher.launchUrlInBrowser(API.uriFor('guias'));
            Navigator.pop(context);
          },
          child: const Text('Ir a Guías'),
        ),
      ],
    );
  }
}