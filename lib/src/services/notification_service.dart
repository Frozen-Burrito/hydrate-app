import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:hydrate_app/firebase_options.dart';
import 'package:hydrate_app/src/api/config_api.dart';
import 'package:hydrate_app/src/exceptions/api_exception.dart';
import 'package:hydrate_app/src/utils/jwt_parser.dart';

typedef MessageHandler = Future<void> Function(RemoteMessage);

typedef MessageErrorHandler = void Function(Object);

/// Mantiene toda la información y funciones para usar el plugin de Firebase Cloud 
/// Messaging (FCM) en la app.
class NotificationService {

  NotificationService._();

  static final NotificationService instance = NotificationService._(); 

  /// El número máximo de handlers de segundo plano que puede haber registrados.
  static const maxBackgroundHandlers = 3;

  static StreamSubscription<String>? _onTokenRefreshSubscription;

  static final List<StreamSubscription<RemoteMessage>> _foregroundMessageHandlers = [];

  /// Una colección de funciones que son ejecutadas cuando la app recibe
  /// un mensaje mientras está en segundo plano.
  static final List<StreamSubscription<RemoteMessage>> _backgroundHandlers = [];

  static FirebaseApp? _firebaseApp;

  /// Inicializa la aplicación de [Firebase] invocando [Firebase.initializeApp()].
  /// 
  /// Firebase debe ser inicializado antes de intentar usar cualquiera de sus
  /// servicios, como FCM, en la app. Puede inicializarse con este método o en
  /// alguno otro de los servicios de Firebase.
  /// 
  /// Si [firebaseOptions] es nulo, usa [DefaultFirebaseOptions.currentPlatform]
  /// por defecto.
  Future<void> init({
    void Function(String?)? onTokenRefresh,
    String authToken = "",
    bool isInDebugMode = false,
  }) async {
    // Inicializar app de Firebase para tener acceso a FCM.
    _firebaseApp ??= await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Registrar handlers para responder a cambios en el token de FCM.
    _onTokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
      .listen((String? newFcmToken) {
        _sendTokenToServer(newFcmToken, authToken);
      });
    
    _onTokenRefreshSubscription?.onError(_onTokenRefreshError);

    if (isInDebugMode) {
      addForegroundHandler((RemoteMessage message) async {debugPrint("Se recibió un mensaje estando en foreground!");
        debugPrint("Datos del mensaje: ${message.data}");

        if (message.notification != null) {
          debugPrint("El mensaje tambien contiene una notificacion: ${message.notification}");
        }
      });

      FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
    }
  }

  Future<void> sendFcmTokenToServer(String userAuthToken) async {
    final bool isUserAuthenticated = userAuthToken.isNotEmpty && !isTokenExpired(userAuthToken);

    if (isUserAuthenticated) {

      final String? currentFcmToken = await FirebaseMessaging.instance.getToken();

      await _sendTokenToServer(currentFcmToken, userAuthToken);
    }
  }

  Future<void> clearFcmToken(String userAuthToken) async {
    final bool isUserAuthenticated = userAuthToken.isNotEmpty && !isTokenExpired(userAuthToken);

    if (isUserAuthenticated) {
      await _sendTokenToServer(null, userAuthToken);
    }
  }

  void disable() {

    _cancelForegroundHandlers();

    _onTokenRefreshSubscription?.cancel();
    _onTokenRefreshSubscription = null;
  }

  void _cancelForegroundHandlers() {
    for (final foregroundHandler in _foregroundMessageHandlers) {
      foregroundHandler.cancel();
    }

    _foregroundMessageHandlers.clear();
  }

  Future<void> _sendTokenToServer(String? newFcmToken, String authToken) async {
    debugPrint("FCM registration token ($newFcmToken)");
    if (newFcmToken != null && authToken.isNotEmpty) {
      try {
        await ConfigApi.instance.refreshFcmToken(authToken, newFcmToken);

      } on ApiException catch (ex) {
        debugPrint("Error while sending FCM token for storage ($ex)");
      } on SocketException catch (ex) {
        debugPrint("No hay conexión a internet, no se puede enviar token FCM (${ex.message})");
      }
    }
  }

  static void _onTokenRefreshError(error) {
    // Error obteniendo el token.
    debugPrint(error);
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
    MessageHandler onForegroundData,
    { MessageErrorHandler? onErrorHandler }
  ) {

    final foregroundHandlerSubscription = FirebaseMessaging.onMessage.listen(
      onForegroundData,
      onError: onErrorHandler
    );

    _foregroundMessageHandlers.add(foregroundHandlerSubscription);
  }
}

Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  
  await Firebase.initializeApp();

  print("Manejando un mensaje en el background: ${message.messageId}");
}
