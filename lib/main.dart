import 'package:flutter/material.dart';
import 'package:hydrate_app/src/pages/auth_page.dart';
import 'package:hydrate_app/src/pages/profile_page.dart';
import 'package:hydrate_app/src/provider/hydration_record_provider.dart';
import 'package:hydrate_app/src/provider/profile_provider.dart';

import 'package:provider/provider.dart';

import 'package:hydrate_app/src/pages/common_form_page.dart';
import 'package:hydrate_app/src/pages/settings_page.dart';
import 'package:hydrate_app/src/pages/connection_page.dart';
import 'package:hydrate_app/src/pages/main_page.dart';
import 'package:hydrate_app/src/pages/new_goal_page.dart';
import 'package:hydrate_app/src/provider/settings_provider.dart';
import 'package:hydrate_app/src/theme/app_themes.dart';
import 'package:hydrate_app/src/widgets/forms/initial_form.dart';
import 'package:hydrate_app/src/widgets/forms/medical_form.dart';
import 'package:hydrate_app/src/widgets/forms/weekly_form.dart';

/// El punto de entrada de [HydrateApp]
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SettingsProvider.init();

  runApp(const HydrateApp());
}

/// La [MaterialApp] que incluye toda la aplicación.
class HydrateApp extends StatelessWidget {

  const HydrateApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
        ChangeNotifierProvider<HydrationRecordProvider>(
          create: (_) => HydrationRecordProvider(),
        ),
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(),
        )
      ],
      child: Consumer<SettingsProvider>(
        builder: (_, settingsProvider, __) {
          return MaterialApp(
            title: 'Hydrate App',
            initialRoute: '/',
            // App theme settings.
            theme: AppThemes.appLightTheme,
            darkTheme: AppThemes.appDarkTheme,
            themeMode: settingsProvider.appThemeMode,
            // App routes
            routes: {
              '/': (context) => const MainPage(),
              '/config': (context) => const SettingsPage(),
              '/ble-pair': (context) => const ConnectionPage(),
              '/new-goal': (context) => const NewGoalPage(),
              '/profile': (context) => const ProfilePage(),
              '/form/initial': (context) => CommonFormPage(
                    formTitle: 'Bienvenido', 
                    formLabel: 'Escribe sobre tí para conocerte mejor:',
                    formWidget: InitialForm()
                  ),
              '/form/periodic': (context) => const CommonFormPage(
                    formTitle: 'Revisión Semanal', 
                    formLabel: 'Escribe la cantidad de horas diarias promedio que dedicaste a cada una de las siguientes actividades durante esta semana.',
                    formWidget: WeeklyForm()
                  ),
              '/form/medical': (context) => const CommonFormPage(
                    formTitle: 'Chequeo Médico', 
                    formLabel: 'Introduce los siguientes datos con apoyo de tu nefrólogo:',
                    formWidget: MedicalForm()
                  ),
              'auth': (context) => const AuthPage(),
            },
          );
        }
      ),
    );
  }
}