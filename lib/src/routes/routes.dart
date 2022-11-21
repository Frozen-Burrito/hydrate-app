import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/views/views.dart';
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
  /// Retorna una vista inmodificable del mapa de rutas de la app.
  static Map<String, WidgetBuilder> buildAppRoutes(BuildContext context) {

    final Map<String, WidgetBuilder> routes = {
      RouteNames.home: (BuildContext context) => const MainView(),
      RouteNames.config: (BuildContext context) => const SettingsView(),
      RouteNames.bleConnection: (BuildContext context) => const ConnectionView(),
      RouteNames.authentication: (BuildContext context) => const AuthView(),
    };

    // final localizations = AppLocalizations.of(context)!;

    // routes[RouteNames.newHydrationGoal] = (context) => CommonFormView(
    //   formTitle: localizations.setGoalFormTitle,
    //   formLabel: localizations.setGoalFormDetails,
    //   formWidget: const CreateGoalForm(),
    //   shapeDecoration: const WaveShape(),
    // );

    // routes[RouteNames.newActivity] = (context) => CommonFormView(
    //   formTitle: localizations.newActivityFormTitle, 
    //   formLabel: localizations.newActivityFormDetails, 
    //   formWidget: const NewActivityForm(),
    //   shapeDecoration: const WaveShape(),
    // );

    // routes[RouteNames.initialForm] = (BuildContext context) => CommonFormView(
    //   formTitle: localizations.initialFormTitle, 
    //   formLabel: localizations.initialFormDetails,
    //   formWidget: const ProfileForm(),
    //   displayBackAction: false,
    //   backgroundColor: Theme.of(context).colorScheme.primary,
    // );

    // routes[RouteNames.weeklyForm] = (BuildContext context) => CommonFormView(
    //   formTitle: localizations.weeklyFormTitle, 
    //   formLabel: localizations.weeklyFormDetails,
    //   formWidget: const WeeklyForm(),
    //   backgroundColor: Theme.of(context).colorScheme.primary,
    // );
    
    // routes[RouteNames.medicalForm] = (BuildContext context) => CommonFormView(
    //   formTitle: localizations.medicalFormTitle, 
    //   formLabel: localizations.medicalFormDetails,
    //   formWidget: const MedicalForm(),
    //   backgroundColor: Theme.of(context).colorScheme.primary,
    // );

    return UnmodifiableMapView(routes);
  }

  static onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (BuildContext context) {
        final localizations = AppLocalizations.of(context)!;
        return Scaffold( 
          body: Center( 
            child: Text(localizations.viewNotFound),
          ),
        );
      }
    );
  }
}