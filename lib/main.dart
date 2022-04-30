import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<HydrationRecordProvider>(
                create: (_) => HydrationRecordProvider(),
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
            )
          );
        }
      ),
    );
  }
}