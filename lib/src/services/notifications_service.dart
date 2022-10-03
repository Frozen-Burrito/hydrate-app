import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hydrate_app/firebase_options.dart';

/// Mantiene toda la información y funciones para usar el plugin de Firebase Cloud 
/// Messaging (FCM) en la app.
class NotificationsService {

  NotificationsService._();

  static final NotificationsService instance = NotificationsService._(); 

  /// El número máximo de handlers de segundo plano que puede haber registrados.
  static const maxBackgroundHandlers = 3;

  /// Una colección de funciones que son ejecutadas cuando la app recibe
  /// un mensaje mientras está en segundo plano.
  static final List<Future<void> Function(RemoteMessage)> _backgroundActions = [];

  /// Inicializa la aplicación de [Firebase] invocando [Firebase.initializeApp()].
  /// 
  /// Firebase debe ser inicializado antes de intentar usar cualquiera de sus
  /// servicios, como FCM, en la app. Puede inicializarse con este método o en
  /// alguno otro de los servicios de Firebase.
  /// 
  /// Si [firebaseOptions] es nulo, usa [DefaultFirebaseOptions.currentPlatform]
  /// por defecto.
  Future<void> init({
    required void Function(String?) onTokenRefresh,
    FirebaseOptions? firebaseOptions,
    bool isInDebugMode = false,
  }) async {
    // Inicializar app de Firebase para tener acceso a FCM.
    await Firebase.initializeApp(options: firebaseOptions);

    // Registrar handlers para responder a cambios en el token de FCM.
    FirebaseMessaging.instance.onTokenRefresh
      .listen(onTokenRefresh)
      .onError(_onTokenRefreshError);

    if (isInDebugMode) {
      addForegroundHandler((RemoteMessage message) {
        debugPrint("Se recibió un mensaje estando en foreground!");
        debugPrint("Datos del mensaje: ${message.data}");

        if (message.notification != null) {
          debugPrint("El mensaje tambien contiene una notificacion: ${message.notification}");
        }
      });

      addBackgroundHandler((RemoteMessage message) {
        debugPrint("Ejecutando handler para mensajes en segundo plano.");

        return Future.value();
      });
    }
  }

  /// Obtiene el token de registro en FCM de esta instancia de la app. Este token
  /// debe ser actualizado con regularidad en el backend, incluyendo un timestamp.
  Future<String?> get registrationToken async {

    final fcmToken = await FirebaseMessaging.instance.getToken();
    
    print('Token de FCM: $fcmToken');

    return fcmToken;
  }

  static void _onTokenRefreshError(error) {
    // Error obteniendo el token.
    throw UnimplementedError();
  }

  /// Registra un handler que responde a eventos de FCM, que incluyen un [RemoteMessage].
  /// [onForegroundData] será invocado en cada evento de datos producido por FCM,
  /// cuando la app esté en el foreground.
  /// 
  /// Opcionalmente, se puede incluir una función que será invocada cuando ocurra
  /// un error con un mensaje de FCM, asignándola a [onErrorHandler].
  /// 
  /// Para registrar un handler de eventos FCM cuando la app esté en segundo 
  /// plano, se puede usar [NotificationsService.addBackgroundHandler()] 
  static void addForegroundHandler(
    void Function(RemoteMessage)? onForegroundData,
    { void Function()? onErrorHandler }
  ) {

    FirebaseMessaging.onMessage.listen(
      onForegroundData,
      // onError: onErrorHandler 
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Registra una función __[handler]__ específica para que FCM ejecute cuando 
  /// reciba un mensaje mientras la app está en segundo plano.
  /// 
  /// El __[handler]__ debe ser breve, asíncrono e independiente de la inicialización
  /// de una clase.
  void addBackgroundHandler(Future<void> Function(RemoteMessage) handler) {

    if (_backgroundActions.length < maxBackgroundHandlers) {
      _backgroundActions.add(handler);
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    
    await Firebase.initializeApp();

    print("Manejando un mensaje en el background: ${message.messageId}");

    for (var handler in _backgroundActions) {
      // Ejecutar cada handler registrado, si es que los hay.
      handler(message);
    }
  }
}