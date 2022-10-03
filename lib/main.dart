import 'package:flutter/material.dart';
import 'package:hydrate_app/src/models/enums/notification_source.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';

import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/routes/routes.dart';
import 'package:hydrate_app/src/services/activity_service.dart';
import 'package:hydrate_app/src/services/device_pairing_service.dart';
import 'package:hydrate_app/src/services/goals_service.dart';
import 'package:hydrate_app/src/services/google_fit_service.dart';
import 'package:hydrate_app/src/services/hydration_record_provider.dart';
import 'package:hydrate_app/src/services/notifications_service.dart';
import 'package:hydrate_app/src/services/profile_service.dart';
import 'package:hydrate_app/src/services/settings_service.dart';
import 'package:hydrate_app/src/theme/app_themes.dart';
import 'package:hydrate_app/src/utils/background_tasks.dart';

/// El punto de entrada de [HydrateApp]
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar los servicios de configuración, perfil y notificaciones 
  // (incluyendo la app de Firebase) antes de iniciar la app.
  await Future.wait([
    SettingsService.init(),
    ProfileService.init(),
    DevicePairingService.init(),
    Workmanager().initialize(
      BackgroundTasks.callbackDispatcher,
      isInDebugMode: true,
    ),
  ]);

  SettingsService().appStartups++;

  final Map<Permission, PermissionStatus> permissionStatuses = await [
    Permission.locationWhenInUse,
    Permission.bluetooth,
  ].request();

  permissionStatuses.forEach((permission, status) => print("$permission: $status"));

  runApp(const HydrateApp());
}

/// La [MaterialApp] que incluye toda la aplicación.
class HydrateApp extends StatelessWidget {

  const HydrateApp({Key? key}) : super(key: key);

  void _setupNotifications(Set<NotificationSource> enabledNotifications, String authToken, int profileId) {

    if (authToken.isNotEmpty && !enabledNotifications.contains(NotificationSource.disabled)) {
      // Configurar las notificaciones.
      NotificationsService.instance.init(
        onTokenRefresh: (String? newFcmToken) {
          //TODO: Enviar el token refrescado al servidor.
        },
        isInDebugMode: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProfileService>(
          create: (_) => ProfileService.fromSharedPrefs( createDefaultProfile: true ),
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

              final bool isGoogleFitIntegrated = settingsService.isGoogleFitIntegrated && 
                  profileService.profileId != UserProfile.defaultProfileId;

              final activityProvider = Provider.of<ActivityService>(context, listen: false);
              activityProvider.forProfile(profileService.profileId);

              final hydrationProvider = Provider.of<HydrationRecordService>(context, listen: false);
              hydrationProvider.forProfile(profileService.profileId);

              final goalProvider = Provider.of<GoalsService>(context, listen: false);
              goalProvider.forProfile(profileService.profileId);

              final devicePairingService = Provider.of<DevicePairingService>(context, listen: false);
              devicePairingService.addOnNewHydrationRecordListener("save_records", (hydrationRecord) {
                hydrationProvider.saveHydrationRecord(hydrationRecord, refreshImmediately: true);
              });

              if (isGoogleFitIntegrated) {
                GoogleFitService.instance.hydrateProfileId = profileService.profileId;

                if (!GoogleFitService.instance.isSigningIn && !GoogleFitService.instance.isSignedInWithGoogle) {
                  GoogleFitService.instance.signInWithGoogle().then((wasSignInSuccessful) {

                    if (wasSignInSuccessful) {
                      devicePairingService.addOnNewHydrationRecordListener(
                        "sync_hydration_to_fit", 
                        GoogleFitService.instance.addHydrationRecordToSyncQueue
                      );

                      GoogleFitService.instance.syncActivitySessions().then((totalSyncSessions) {
                        debugPrint("$totalSyncSessions sessions were synchronized with Google Fit");
                      });
                    }
                  });
                }
              }

              _setupNotifications(
                settingsService.enabledNotificationSources,
                profileService.authToken,
                profileService.profileId,
              );

              return MaterialApp(
                title: "Hydrate App",
                initialRoute: (settingsService.appStartups > 0)
                  ? RouteNames.home
                  : RouteNames.initialForm,
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