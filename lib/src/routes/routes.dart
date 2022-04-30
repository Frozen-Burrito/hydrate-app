import 'dart:collection';
import 'package:flutter/material.dart';

import 'package:hydrate_app/src/pages/main_page.dart';
import 'package:hydrate_app/src/pages/pages.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/widgets/forms/initial_form.dart';
import 'package:hydrate_app/src/widgets/forms/medical_form.dart';
import 'package:hydrate_app/src/widgets/forms/weekly_form.dart';

/// Todas las rutas de la app son registradas en el mapa privado _appRoutes y 
/// accesibles a través del get [appRoutes].
class Routes {

  static final Map<String, WidgetBuilder> _appRoutes = {
    RouteNames.home: (BuildContext context) => const MainPage(),
    RouteNames.config: (BuildContext context) => const SettingsPage(),
    RouteNames.bleConnection: (BuildContext context) => const ConnectionPage(),
    RouteNames.newHydrationGoal: (BuildContext context) => const NewGoalPage(),
    RouteNames.newActivity: (BuildContext context) => const NewGoalPage(),

    RouteNames.initialForm: (BuildContext context) => CommonFormPage(
      formTitle: 'Bienvenido', 
      formLabel: 'Escribe sobre tí para conocerte mejor:',
      formWidget: InitialForm(),
      displayBackAction: false,
    ),

    RouteNames.weeklyForm: (BuildContext context) => const CommonFormPage(
      formTitle: 'Revisión Semanal', 
      formLabel: 'Escribe la cantidad de horas diarias promedio que dedicaste a cada una de las siguientes actividades durante esta semana.',
      formWidget: WeeklyForm()
    ),
    
    RouteNames.medicalForm: (BuildContext context) => const CommonFormPage(
      formTitle: 'Chequeo Médico', 
      formLabel: 'Introduce los siguientes datos con apoyo de tu nefrólogo:',
      formWidget: MedicalForm()
    ),

    RouteNames.authentication: (BuildContext context) => const AuthPage(),
  };

  /// Retorna una vista inmodificable del mapa de rutas de la app.
  static Map<String, WidgetBuilder> get appRoutes => UnmodifiableMapView(_appRoutes);

  static onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (BuildContext context) 
        => const Scaffold( body: Center( child: Text('404: Ruta no encontrada')),)
    );
  }
}