import 'package:flutter/material.dart';
import 'package:hydrate_app/src/widgets/custom_toolbar.dart';

class ConnectionPage extends StatelessWidget {
  const ConnectionPage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget> [
          CustomToolbar(
            title: 'Conecta Tu Botella',
            startActions: <Widget>[
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            ],
            endActions: <Widget> [
              IconButton(
                icon: const Icon(Icons.info),
                onPressed: () {}, 
              )
            ],
          )
        ],
      ),
    );
  }
}