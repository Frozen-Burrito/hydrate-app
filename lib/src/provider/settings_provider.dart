import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationSettings {
  disabled,
  goals,
  battery,
  all
}

/// Facilita el acceso y modificación de la configuración de la app en SharedPreferences.
class SettingsProvider with ChangeNotifier {

  static late SharedPreferences? _sharedPreferences;

  factory SettingsProvider() => SettingsProvider._internal();

  SettingsProvider._internal();

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

  bool get isSharingData => _sharedPreferences?.getBool('aportarDatos') ?? false;

  set isSharingData (bool share) => _sharedPreferences?.setBool('aportarDatos', share);

  bool get areWeeklyFormsEnabled => _sharedPreferences?.getBool('formRecurrentes') ?? false;

  set areWeeklyFormsEnabled (bool formsEnabled) => _sharedPreferences?.setBool('formRecurrentes', formsEnabled);

  NotificationSettings get notificationSettings {
    int notif = _sharedPreferences?.getInt('notificaciones') ?? 0;

    int notifIndex = max(min(notif, NotificationSettings.values.length), 0);

    return NotificationSettings.values[notifIndex];
  }

  set notificationSettings (NotificationSettings notifSettings) {

    _sharedPreferences?.setInt('notificaciones', notifSettings.index);
  }

  String get localeCode => _sharedPreferences?.getString('codigoFormato') ?? 'ES';

  set localeCode (String code) {
    _sharedPreferences?.setString('codigoFormato', code.substring(0,2));
  }

  String get deviceId => _sharedPreferences?.getString('idDispositivo') ?? '';

  set deviceId (String newDeviceId) => _sharedPreferences?.setString('idDispositivo', newDeviceId);

  String get authToken => _sharedPreferences?.getString('jwt') ?? '';

  set authToken (String newJwt) => _sharedPreferences?.setString('jwt', authToken);
}