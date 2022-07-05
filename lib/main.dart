import 'package:flutter/material.dart';
import 'package:hydrate_app/src/provider/goals_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/provider/activity_provider.dart';
import 'package:hydrate_app/src/provider/hydration_record_provider.dart';
import 'package:hydrate_app/src/provider/profile_provider.dart';
import 'package:hydrate_app/src/provider/settings_provider.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/routes/routes.dart';
import 'package:hydrate_app/src/theme/app_themes.dart';

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
    return ChangeNotifierProvider<SettingsProvider>(
      create: (_) => SettingsProvider(),
      child: Consumer<SettingsProvider>(
        builder: (_, settingsProvider, __) {
          // Configurar las rutas para el perfil actual.
          Routes.currentProfileId = settingsProvider.currentProfileId;

          return MultiProvider(
            providers: [
              ChangeNotifierProvider<HydrationRecordProvider>(
                create: (_) => HydrationRecordProvider(),
              ),
              ChangeNotifierProvider<ActivityProvider>(
                create: (_) => ActivityProvider(),
              ),
              ChangeNotifierProvider<GoalProvider>(
                create: (_) => GoalProvider(),
              ),
              ChangeNotifierProvider<ProfileProvider>(
                create: (_) => ProfileProvider(
                  profileId: settingsProvider.currentProfileId,
                  authToken: settingsProvider.authToken
                ),
              )
            ],
            child: MaterialApp(
              title: 'Hydrate App',
              initialRoute: settingsProvider.currentProfileId < 0
                ? RouteNames.initialForm
                : RouteNames.home,
              // Configuracion del tema de color.
              theme: AppThemes.appLightTheme,
              darkTheme: AppThemes.appDarkTheme,
              themeMode: settingsProvider.appThemeMode,
              // Rutas de la app
              routes: Routes.appRoutes,
              onUnknownRoute: (RouteSettings settings) => Routes.onUnknownRoute(settings),
              // Localización e internacionalización
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en', ' '),
                Locale('es', ' '),
              ],
            )
          );
        }
      ),
    );
  }
}