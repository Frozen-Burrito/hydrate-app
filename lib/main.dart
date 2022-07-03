import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hydrate_app/src/provider/notifications_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
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

  // Inicializar el proveedor de configuracion y la app de Firebase, al mismo tiempo.
  await Future.wait([
    SettingsProvider.init(), 
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
  ]);

  final fcmToken = await FirebaseMessaging.instance.getToken();

  print('Token de FCM: $fcmToken');

  FirebaseMessaging.instance.onTokenRefresh
    .listen((fcmToken) {
      //TODO: Enviar token al servidor, si es necesario.

      // Este callback es invocado cuando la app inicia y cada vez que 
      // se genera un nuevo token.
    })
    .onError((e) {
      // Error obteniendo el token.
    });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Se recibió un mensaje estando en foreground!');
    print('Datos del mensaje: ${message.data}');

    if (message.notification != null) {
      print('El mensaje tambien contiene una notificacion: ${message.notification}');
    }
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const HydrateApp());
}

//TODO: Esto es temporal, ver mejor manera de hacerlo.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  
  await Firebase.initializeApp();

  print("Manejando un mensaje en el background: ${message.messageId}");
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