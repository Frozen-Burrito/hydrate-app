import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hydrate_app/firebase_options.dart';

class NotificationsService {

  static Future<FirebaseApp> init() async {
    return Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  static void registerHandlers(void Function(RemoteMessage)? onForegroundData) {

    FirebaseMessaging.onMessage.listen(onForegroundData);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<String?> getToken() async {
    return await FirebaseMessaging.instance.getToken();
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    
    await Firebase.initializeApp();

    print("Manejando un mensaje en el background: ${message.messageId}");
  }
}