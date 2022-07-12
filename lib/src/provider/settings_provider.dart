import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hydrate_app/src/utils/jwt_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Describe las notificaciones enviadas por la app.
enum NotificationSettings {
  /// Las notificaciones están desactivadas. La app no enviará ninguna notificación.
  disabled,

  /// La app enviará notificaciones sobre las metas del usuario. 
  goals,

  /// La app enviará notificaciones con el nivel de batería de la botella.
  battery,

  /// La app enviará notificaciones con recordatorios de actividad y rutinas.
  activity,

  /// La app enviará notificaciones de metas y de nivel de batería.
  all
}

/// Facilita el acceso y modificación de la configuración de la app en Shared Preferences.
class SettingsProvider with ChangeNotifier {

  static late SharedPreferences? _sharedPreferences;

  factory SettingsProvider() => SettingsProvider._internal();

  SettingsProvider._internal();

  /// Inicializa y asigna la instancia de Shared Preferences.
  static Future<void> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  // SharedPreferences Get/Set

  /// Obtiene el [ThemeMode] de la app desde Shared Preferences.
  /// 
  /// Retorna [ThemeMode.system] por defecto.
  ThemeMode get appThemeMode => ThemeMode.values[_sharedPreferences?.getInt('tema') ?? 0];

  /// Guarda el nuevo [themeMode] en Shared Preferences.
  set appThemeMode (ThemeMode themeMode) {
    _sharedPreferences?.setInt('tema', themeMode.index);
    
    notifyListeners();
  }

  /// Obtiene de Shared Preferences la configuración de aporte a datos abiertos.
  /// 
  /// Es [true] si el usuario desea aportar sus datos de hidratación y [false]
  /// si no desea compartirlos. El valor por defecto es [false].
  bool get isSharingData => _sharedPreferences?.getBool('aportarDatos') ?? false;

  /// Guarda en Shared Preferences la configuración de aporte a datos abiertos.
  /// 
  /// [share] es [true] si el usuario desea aportar sus datos de hidratación y [false]
  /// si no desea compartirlos. El valor por defecto es [false].
  set isSharingData (bool share) => _sharedPreferences?.setBool('aportarDatos', share);

  /// La configuración del usuario de los formularios semanales.
  /// 
  /// Es [true] si los formularios están activados, [false] por el contrario. Por defecto
  /// es [false].
  bool get areWeeklyFormsEnabled => _sharedPreferences?.getBool('formRecurrentes') ?? false;

  /// Guarda en Shared Preferences una nueva configuración de formularios semanales.
  set areWeeklyFormsEnabled (bool formsEnabled) => _sharedPreferences?.setBool('formRecurrentes', formsEnabled);

  /// Obtiene de Shared Preferences los tipos de notificaciones que ha activado 
  /// el usuario.
  NotificationSettings get notificationSettings {
    int notif = _sharedPreferences?.getInt('notificaciones') ?? 0;

    int notifIndex = max(min(notif, NotificationSettings.values.length), 0);

    return NotificationSettings.values[notifIndex];
  }

  /// Guarda la configuración de notificaciones del usuario.
  set notificationSettings (NotificationSettings notifSettings) {

    _sharedPreferences?.setInt('notificaciones', notifSettings.index);
  }

  /// El código de dos letras de la región del usuario para localizar el contenido.
  String get localeCode => _sharedPreferences?.getString('codigoFormato') ?? 'ES';

  /// Guarda un nuevo código de región del usuario.
  set localeCode (String code) {
    _sharedPreferences?.setString('codigoFormato', code.substring(0,2));
  }

  /// El identificador de la botella conectada previamente. Por defecto, es un 
  /// String vacío.
  String get deviceId => _sharedPreferences?.getString('idDispositivo') ?? '';

  /// Guarda un nuevo ID BLE de una botella.  
  set deviceId (String newDeviceId) => _sharedPreferences?.setString('idDispositivo', newDeviceId);

  /// El JsonWebToken de autenticación del usuario. Es posible que ya haya expirado.
  String get authToken {
    final String token = _sharedPreferences?.getString('jwt') ?? '';

    print('Token obtenido de SP: $token');

    if (token.isNotEmpty && isTokenExpired(token)) {
      _sharedPreferences?.setString('jwt', '');
      return '';
    }

    return token;
  }

  /// Guarda un nuevo JWT de autenticación en Shared Preferences.
  set authToken (String newJwt) {
    if (newJwt.isNotEmpty && !isTokenExpired(newJwt)) {
      _sharedPreferences?.setString('jwt', newJwt);
      notifyListeners();
    }
  }

  Future<void> logOut() async {
    await _sharedPreferences?.setString('jwt', '');
    notifyListeners();
  }

  int get currentProfileId => _sharedPreferences?.getInt('perfil_actual') ?? -1;

  set currentProfileId(int profileId) => _sharedPreferences?.setInt('perfil_actual', profileId);

  int get appStartups => _sharedPreferences?.getInt('inicios_app') ?? 0;

  set appStartups(int startupCount) => _sharedPreferences?.setInt('inicios_app', startupCount);
}