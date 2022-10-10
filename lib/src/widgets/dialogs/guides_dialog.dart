import 'package:flutter/material.dart';
import 'package:hydrate_app/src/api/api_client.dart';

import 'package:hydrate_app/src/utils/launch_url.dart';

class GuidesDialog extends StatelessWidget {
  const GuidesDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: const [
          Icon( Icons.tips_and_updates ),

          //TODO: agregar i18n.
          Text('Primeros Pasos'),
        ],
      ),
      //TODO: agregar i18n.
      content: const Text('Las guías de usuario son un recurso que te puede ayudar a usar esta app y tu extensión para botellas. ¿Te gustaría revisarlas?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
          }, 
          //TODO: agregar i18n.
          child: const Text('No Volver a Mostrar'),
        ),
        TextButton(
          onPressed: () {
            final url = ApiClient.urlForPage("guias");
            UrlLauncher.launchUrlInBrowser(url);
            Navigator.pop(context, true);
          },
          //TODO: agregar i18n.
          child: const Text('Ir a Guías'),
        ),
      ],
    );
  }
}