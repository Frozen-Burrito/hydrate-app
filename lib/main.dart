import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';

import 'package:hydrate_app/src/api/api_client.dart';
import 'package:hydrate_app/src/api/data_api.dart';
import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/routes/routes.dart';
import 'package:hydrate_app/src/services/activity_service.dart';
import 'package:hydrate_app/src/services/device_pairing_service.dart';
import 'package:hydrate_app/src/services/goals_service.dart';
import 'package:hydrate_app/src/services/hydration_record_service.dart';
import 'package:hydrate_app/src/services/profile_service.dart';
import 'package:hydrate_app/src/services/settings_service.dart';
import 'package:hydrate_app/src/theme/app_themes.dart';
import 'package:hydrate_app/src/utils/background_tasks.dart';
import 'package:hydrate_app/src/utils/jwt_parser.dart';

/// El punto de entrada de [HydrateApp]
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar los servicios de configuración, perfil y notificaciones 
  // (incluyendo la app de Firebase) antes de iniciar la app.
  await Future.wait([
    SettingsService.init( recordAppStartup: true ),
    ProfileService.init(),
    DevicePairingService.init(),
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    ),
  ]);

  final Map<Permission, PermissionStatus> permissionStatuses = await [
    // Permission.locationWhenInUse,
    Permission.bluetooth,
  ].request();

  permissionStatuses.forEach((permission, status) => print("$permission: $status"));

  runApp(const HydrateApp());
}

/// La [MaterialApp] que incluye toda la aplicación.
class HydrateApp extends StatelessWidget {

  const HydrateApp({Key? key}) : super(key: key);

  String _getInitialAppRoute(int appStartupCount, bool doesDefaultProfileRequireSignIn) {
    if (appStartupCount <= 0) {
      return RouteNames.initialForm;
    } else if (doesDefaultProfileRequireSignIn) {
      return RouteNames.authentication;
    } else {
      return RouteNames.home;
    }
  }

  void _onProfileChanged(UserProfile? currentProfile, String? authToken) {

    if (currentProfile == null) return;
    
    final isProfileAuthenticated = authToken != null && !isTokenExpired(authToken);

    if (isProfileAuthenticated) {
      DataApi.instance.authenticateClient(
        authToken: authToken!, 
        authType: ApiAuthType.bearerToken
      );
    } else {
      DataApi.instance.clearClientAuthentication();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProfileService>(
          create: (_) => ProfileService.fromSharedPrefs( 
            createDefaultProfile: true,
            onProfileChanged: _onProfileChanged,
          ),
        ),
        ChangeNotifierProvider<DevicePairingService>(
          create: (_) => DevicePairingService(),
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
        builder: (_, profileService, __) {
          return Consumer<SettingsService>(
            builder: (context, settingsService, __) {

              final activityService = Provider.of<ActivityService>(context, listen: false);
              activityService.forProfile(profileService.profileId);

              final hydrationService = Provider.of<HydrationRecordService>(context, listen: false);
              hydrationService.forProfile(profileService.profileId);

              final goalService = Provider.of<GoalsService>(context, listen: false);
              goalService.forProfile(profileService.profileId);

              final devicePairingService = Provider.of<DevicePairingService>(context, listen: false);
              devicePairingService.addOnNewHydrationRecordListener("save_records", (hydrationRecord) async {
                await hydrationService.saveHydrationRecord(
                  hydrationRecord, 
                  refreshImmediately: false
                );

                await hydrationService.syncLocalHydrationRecordsWithAccount();
              });

              settingsService.applyCurrentSettings(
                userAuthToken: profileService.authToken,
                activityService: activityService,
                profileService: profileService,
                devicePairingService: devicePairingService,
              );

              return MaterialApp(
                title: "Hydrate App",
                initialRoute: _getInitialAppRoute(
                  settingsService.appStartups, 
                  false,
                ),
                // Configuracion del tema de color.
                theme: AppThemes.appLightTheme,
                darkTheme: AppThemes.appDarkTheme,
                themeMode: settingsService.appThemeMode,
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