import 'package:flutter/material.dart';

import 'package:hydrate_app/src/pages/main_page.dart';
import 'package:hydrate_app/src/pages/config_page.dart';
import 'package:hydrate_app/src/pages/connection_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {

  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hydrate App',
      initialRoute: '/',
      routes: {
        '/': (context) => const MainPage(),
        '/config': (context) => const ConfigPage(),
        '/ble-pair': (context) => const ConnectionPage(),
      },
    );
  }
}