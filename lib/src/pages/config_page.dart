import 'package:flutter/material.dart';
import 'package:hydrate_app/src/widgets/custom_toolbar.dart';

class ConfigPage extends StatelessWidget {
  const ConfigPage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget> [
          CustomToolbar(
            title: 'Configuración',
            startActions: <Widget> [
              IconButton( 
                icon: const Icon(Icons.arrow_back), 
                onPressed: () => Navigator.pop(context)
              ),
            ],
            endActions: <Widget> [
              IconButton(
                icon: const Icon(Icons.phonelink_ring),
                onPressed: () => Navigator.pushNamed(context, '/ble-pair'),
              )
            ],
          )
        ],
      ),
    );
  }
}