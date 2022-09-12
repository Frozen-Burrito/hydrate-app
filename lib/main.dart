import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/routes/routes.dart';
import 'package:hydrate_app/src/services/activity_service.dart';
import 'package:hydrate_app/src/services/goals_service.dart';
import 'package:hydrate_app/src/services/hydration_record_provider.dart';
import 'package:hydrate_app/src/services/profile_service.dart';
import 'package:hydrate_app/src/services/settings_service.dart';
import 'package:hydrate_app/src/theme/app_themes.dart';
import 'package:hydrate_app/src/utils/background_tasks.dart';

/// El punto de entrada de [HydrateApp]
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar internamente a SettingsService.
  await Future.wait([
    SettingsService.init(),
    ProfileService.init(),
  ]); 

  SettingsService().appStartups++;

  final Map<Permission, PermissionStatus> permissionStatuses = await [
    Permission.locationWhenInUse,
    Permission.bluetooth,
  ].request();

  permissionStatuses.forEach((permission, status) => print("$permission: $status"));

  // Inicializar la instancia de workmanager.
  Workmanager().initialize(
    BackgroundTasks.callbackDispatcher,
    isInDebugMode: true,
  );

  runApp(const HydrateApp());
}

/// La [MaterialApp] que incluye toda la aplicación.
class HydrateApp extends StatelessWidget {

  const HydrateApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProfileService>(
          create: (_) => ProfileService.fromSharedPrefs( createDefaultProfile: true ),
        ),
        ChangeNotifierProvider<SettingsService>(
          create: (_) => SettingsService(),
        ),
        ChangeNotifierProvider<HydrationRecordService>(
          create: (_) => HydrationRecordService(),
        ),
        ChangeNotifierProvider<ActivityService>(
          create: (_) => ActivityService(),
        ),
        ChangeNotifierProvider<GoalsService>(
          create: (_) => GoalsService(),
        ),
      ],
      child: Consumer<ProfileService>(
        builder: (_, profileProvider, __) {
          return Consumer<SettingsService>(
            builder: (context, settingsProvider, __) {

              final activityProvider = Provider.of<ActivityService>(context, listen: false);
              activityProvider.forProfile(profileProvider.profileId);

              final hydrationProvider = Provider.of<HydrationRecordService>(context, listen: false);
              hydrationProvider.forProfile(profileProvider.profileId);

              final goalProvider = Provider.of<GoalsService>(context, listen: false);
              goalProvider.forProfile(profileProvider.profileId);
              
              return MaterialApp(
                title: "Hydrate App",
                initialRoute: (settingsProvider.appStartups > 0)
                  ? RouteNames.home
                  : RouteNames.initialForm,
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
                  Locale("en", " "),
                  Locale("es", " "),
                ],
              );
            }
          );
        }
      ),
    );
  }
}