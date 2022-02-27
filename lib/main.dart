import 'package:flutter/material.dart';

import 'package:hydrate_app/src/pages/common_form_page.dart';
import 'package:hydrate_app/src/pages/config_page.dart';
import 'package:hydrate_app/src/pages/connection_page.dart';
import 'package:hydrate_app/src/pages/main_page.dart';
import 'package:hydrate_app/src/pages/new_goal_page.dart';
import 'package:hydrate_app/src/widgets/forms/initial_form.dart';
import 'package:hydrate_app/src/widgets/forms/medical_form.dart';
import 'package:hydrate_app/src/widgets/forms/weekly_form.dart';

/// El punto de entrada de [HydrateApp]
void main() => runApp(const HydrateApp());

/// La [MaterialApp] que incluye toda la aplicación.
class HydrateApp extends StatelessWidget {

  const HydrateApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hydrate App',
      initialRoute: '/',
      routes: {
        '/': (context) => const MainPage(),
        '/config': (context) => const ConfigPage(),
        '/ble-pair': (context) => const ConnectionPage(),
        '/new-goal': (context) => const NewGoalPage(),
        '/form/initial': (context) => const CommonFormPage(
              formTitle: 'Bienvenido', 
              formWidget: InitialForm()
            ),
        '/form/periodic': (context) => const CommonFormPage(
              formTitle: 'Revisión Semanal', 
              formWidget: WeeklyForm()
            ),
        '/form/medical': (context) => const CommonFormPage(
              formTitle: 'Chequeo Médico', 
              formWidget: MedicalForm()
            ),
      },
    );
  }
}