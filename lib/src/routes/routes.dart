import 'dart:collection';
import 'package:flutter/material.dart';

import 'package:hydrate_app/src/pages/pages.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/widgets/forms/create_goal_form.dart';
import 'package:hydrate_app/src/widgets/forms/profile_form.dart';
import 'package:hydrate_app/src/widgets/forms/medical_form.dart';
import 'package:hydrate_app/src/widgets/forms/new_activity_form.dart';
import 'package:hydrate_app/src/widgets/forms/weekly_form.dart';
import 'package:hydrate_app/src/widgets/shapes.dart';

/// Todas las rutas de la app son registradas en el mapa privado _appRoutes y 
/// accesibles a través del get [appRoutes].
class Routes {

  static final Map<String, WidgetBuilder> _appRoutes = {
    RouteNames.home: (BuildContext context) => const MainPage(),
    RouteNames.config: (BuildContext context) => const SettingsPage(),
    RouteNames.bleConnection: (BuildContext context) => const ConnectionPage(),

    //TODO: agregar i18n
    RouteNames.newHydrationGoal: (context) => const CommonFormPage(
      formTitle: 'Nueva Meta',
      formLabel: 'Escribe los detalles de tu nueva meta:',
      formWidget: CreateGoalForm(),
      shapeDecoration: WaveShape(),
    ),
    RouteNames.newActivity: (context) => const CommonFormPage(
      formTitle: 'Registra una Actividad', 
      formLabel: 'Escribe los detalles de la actividad física realizada.', 
      formWidget: NewActivityForm(),
      shapeDecoration: WaveShape(),
    ),

    RouteNames.initialForm: (BuildContext context) => CommonFormPage(
      formTitle: 'Bienvenido', 
      formLabel: 'Escribe sobre tí para conocerte mejor:',
      formWidget: const ProfileForm(),
      displayBackAction: false,
      backgroundColor: Theme.of(context).colorScheme.primary,
    ),

    RouteNames.weeklyForm: (BuildContext context) => CommonFormPage(
      formTitle: 'Revisión Semanal', 
      formLabel: 'Escribe la cantidad de horas diarias promedio que dedicaste a cada una de las siguientes actividades durante esta semana.',
      formWidget: const WeeklyForm(),
      backgroundColor: Theme.of(context).colorScheme.primary,
    ),
    
    RouteNames.medicalForm: (BuildContext context) => CommonFormPage(
      formTitle: 'Chequeo Médico', 
      formLabel: 'Introduce los siguientes datos con apoyo de tu nefrólogo:',
      formWidget: const MedicalForm(),
      backgroundColor: Theme.of(context).colorScheme.primary,
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