import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydrate_app/src/models/enums/notification_types.dart';
import 'package:hydrate_app/src/models/settings.dart';
import 'package:hydrate_app/src/utils/jwt_parser.dart';

/// Facilita el acceso y modificación de la configuración de la app en Shared Preferences.
class SettingsProvider with ChangeNotifier {

  static late SharedPreferences? _sharedPreferences;

  factory SettingsProvider() => SettingsProvider._internal();

  SettingsProvider._internal();

  /// Inicializa y asigna la instancia de Shared Preferences.
  static Future<void> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  final String versionName = "1.0.0-beta+2";

  Settings get currentSettings => Settings(
    appThemeMode,
    notificationSettings,
    isSharingData,
    areWeeklyFormsEnabled,
  );

  // SharedPreferences Get/Set

  static const String appThemeModeKey = "tema";
  static const String contributeDataKey = "aportarDatos";
  static const String weeklyFormsEnabledKey = "formRecurrentes";
  static const String allowedNotificationsKey = "notificaciones";
  static const String localeCodeKey = "codigoFormato";
  static const String deviceIdKey = "idDispositivo";
  static const String authTokenKey = "jwt";
  static const String currentProfileIdKey = "perfil_actual";
  static const String appStartupCountKey = "inicios_app";

  /// Obtiene el [ThemeMode] de la app desde Shared Preferences.
  /// 
  /// Retorna [ThemeMode.system] por defecto.
  ThemeMode get appThemeMode => ThemeMode.values[_sharedPreferences?.getInt(appThemeModeKey) ?? 0];

  /// Guarda el nuevo [themeMode] en Shared Preferences.
  set appThemeMode (ThemeMode themeMode) {
    _sharedPreferences?.setInt(appThemeModeKey, themeMode.index);
    
    notifyListeners();
  }

  /// Obtiene de Shared Preferences la configuración de aporte a datos abiertos.
  /// 
  /// Es [true] si el usuario desea aportar sus datos de hidratación y [false]
  /// si no desea compartirlos. El valor por defecto es [false].
  bool get isSharingData => _sharedPreferences?.getBool(contributeDataKey) ?? false;

  /// Guarda en Shared Preferences la configuración de aporte a datos abiertos.
  /// 
  /// [share] es [true] si el usuario desea aportar sus datos de hidratación y [false]
  /// si no desea compartirlos. El valor por defecto es [false].
  set isSharingData (bool share) => _sharedPreferences?.setBool(contributeDataKey, share);

  /// La configuración del usuario de los formularios semanales.
  /// 
  /// Es [true] si los formularios están activados, [false] por el contrario. Por defecto
  /// es [false].
  bool get areWeeklyFormsEnabled => _sharedPreferences?.getBool(weeklyFormsEnabledKey) ?? false;

  /// Guarda en Shared Preferences una nueva configuración de formularios semanales.
  set areWeeklyFormsEnabled (bool formsEnabled) => _sharedPreferences?.setBool(weeklyFormsEnabledKey, formsEnabled);

  /// Obtiene de Shared Preferences los tipos de notificaciones que ha activado 
  /// el usuario.
  NotificationTypes get notificationSettings {
    int notif = _sharedPreferences?.getInt(allowedNotificationsKey) ?? 0;

    int notifIndex = max(min(notif, NotificationTypes.values.length), 0);

    return NotificationTypes.values[notifIndex];
  }

  /// Guarda la configuración de notificaciones del usuario.
  set notificationSettings (NotificationTypes notifSettings) {

    _sharedPreferences?.setInt(allowedNotificationsKey, notifSettings.index);
  }

  /// El código de dos letras de la región del usuario para localizar el contenido.
  String get localeCode => _sharedPreferences?.getString(localeCodeKey) ?? 'ES';

  /// Guarda un nuevo código de región del usuario.
  set localeCode (String code) {
    _sharedPreferences?.setString(localeCodeKey, code.substring(0,2));
  }

  /// El identificador de la botella conectada previamente. Por defecto, es un 
  /// String vacío.
  String get deviceId => _sharedPreferences?.getString(deviceIdKey) ?? '';

  /// Guarda un nuevo ID BLE de una botella.  
  set deviceId (String newDeviceId) => _sharedPreferences?.setString(deviceIdKey, newDeviceId);

  /// El JsonWebToken de autenticación del usuario. Es posible que ya haya expirado.
  String get authToken {
    final String token = _sharedPreferences?.getString(authTokenKey) ?? '';

    if (token.isNotEmpty && isTokenExpired(token)) {
      _sharedPreferences?.setString(authTokenKey, '');
      return '';
    }

    return token;
  }

  /// Guarda un nuevo JWT de autenticación en Shared Preferences.
  set authToken (String newJwt) {
    if (newJwt.isNotEmpty && !isTokenExpired(newJwt)) {
      _sharedPreferences?.setString(authTokenKey, newJwt);
      notifyListeners();
    }
  }

  Future<void> logOut() async {
    await _sharedPreferences?.setString(authTokenKey, '');
    notifyListeners();
  }

  int get currentProfileId => _sharedPreferences?.getInt(currentProfileIdKey) ?? -1;

  set currentProfileId(int profileId) => _sharedPreferences?.setInt(currentProfileIdKey, profileId);

  int get appStartups => _sharedPreferences?.getInt(appStartupCountKey) ?? 0;

  set appStartups(int startupCount) => _sharedPreferences?.setInt(appStartupCountKey, startupCount);
}