import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hydrate_app/src/services/google_fit_service.dart';
import 'package:hydrate_app/src/utils/background_tasks.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydrate_app/src/models/enums/notification_types.dart';
import 'package:hydrate_app/src/models/settings.dart';
import 'package:workmanager/workmanager.dart';

/// Facilita el acceso y modificación de la configuración de la app en Shared Preferences.
class SettingsService with ChangeNotifier {

  static late final SharedPreferences? _sharedPreferences;

  factory SettingsService() => SettingsService._internal();

  SettingsService._internal();

  /// Inicializa y asigna la instancia de Shared Preferences.
  static Future<void> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  static const String versionName = "1.0.0-beta+3";

  static const int appStartupsToShowGuides = 5;

  Settings get currentSettings => Settings(
    appThemeMode,
    notificationSettings,
    isSharingData,
    areWeeklyFormsEnabled,
    isGoogleFitIntegrated,
  );

  void setCurrentSettings(Settings changes, int profileId, { String userAccountId = "" }) {

    final currentSettings = Settings(
      appThemeMode,
      notificationSettings,
      isSharingData,
      areWeeklyFormsEnabled,
      isGoogleFitIntegrated,
    );

    final hasThemeChanged = currentSettings.appThemeMode != changes.appThemeMode;

    if (hasThemeChanged) {
      appThemeMode = changes.appThemeMode;
    }

    final hasNotificationsChanged = currentSettings.allowedNotifications != changes.allowedNotifications;

    if (hasNotificationsChanged) {
      final notifsWereDisabled = changes.allowedNotifications == NotificationTypes.disabled;
      
      Permission.notification.request().isGranted.then((isPermissionGranted) {
        // Si las notificaciones fueron desactivadas, no hay ningún requisito 
        // para el cambio. Si fueron activadas, es necesario que la app tenga 
        // el permiso de recibir notificaciones
        if (notifsWereDisabled || isPermissionGranted) {
          // Actualizar las preferencias de notificaciones.
          notificationSettings = changes.allowedNotifications;
        }
      });
    }

    final hasWeeklyFormsChanged = currentSettings.areWeeklyFormsEnabled != changes.areWeeklyFormsEnabled;

    if (hasWeeklyFormsChanged) {
      areWeeklyFormsEnabled = changes.areWeeklyFormsEnabled;
    }

    final hasIntegrationWithGoogleFitChanged = currentSettings.isGoogleFitIntegrated != changes.isGoogleFitIntegrated;

    if (hasIntegrationWithGoogleFitChanged) {
      isGoogleFitIntegrated = changes.isGoogleFitIntegrated;

      if (changes.isGoogleFitIntegrated) {
        GoogleFitService.instance.signInWithGoogle();
      } else {
        GoogleFitService.instance.disableDataCollection();
      }
    }

    final hasDataContributionChanged = currentSettings.shouldContributeData != changes.shouldContributeData;

    if (hasDataContributionChanged) {
      isSharingData = changes.shouldContributeData;

      // Registrar o eliminar la tarea periodica para aportar datos 
      // estadísticos a la API web.
      if (isSharingData) {
        // Registrar tarea para aportar datos cada semana.
        Workmanager().registerPeriodicTask(
          BackgroundTasks.sendStatsData.uniqueName,
          BackgroundTasks.sendStatsData.taskName,
          frequency: BackgroundTasks.sendStatsData.frequency,
          initialDelay: BackgroundTasks.sendStatsData.initialDelay,
          constraints: BackgroundTasks.sendStatsData.constraints,
          inputData: <String, dynamic>{
            BackgroundTasks.taskInputProfileId: profileId,
            BackgroundTasks.taskInputAccountId: userAccountId,
          },
        );

      } else {
        // Cancelar tarea que aporta datos.
        Workmanager().cancelByUniqueName(BackgroundTasks.sendStatsDataTaskName);
      }
    }

    // Solo notificar a los listeners cuando realmente sucedieron cambios
    // de configuración.
    if (hasThemeChanged || hasNotificationsChanged || 
        hasDataContributionChanged || hasWeeklyFormsChanged || hasIntegrationWithGoogleFitChanged) {
      notifyListeners();
    }
  }

  // SharedPreferences Get/Set

  static const String appThemeModeKey = "tema";
  static const String contributeDataKey = "aportarDatos";
  static const String weeklyFormsEnabledKey = "formRecurrentes";
  static const String allowedNotificationsKey = "notificaciones";
  static const String isIntegratedWithGoogleFitKey = "google_fit_conectado";
  static const String localeCodeKey = "codigoFormato";
  static const String deviceIdKey = "idDispositivo";
  static const String appStartupCountKey = "inicios_app";

  /// Obtiene el [ThemeMode] de la app desde Shared Preferences.
  /// 
  /// Retorna [ThemeMode.system] por defecto.
  ThemeMode get appThemeMode => ThemeMode.values[_sharedPreferences?.getInt(appThemeModeKey) ?? 0];

  /// Guarda el nuevo [themeMode] en Shared Preferences.
  set appThemeMode (ThemeMode themeMode) {
    _sharedPreferences?.setInt(appThemeModeKey, themeMode.index);
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
  set isSharingData (bool share) {
    _sharedPreferences?.setBool(contributeDataKey, share);
  }

  /// La configuración del usuario de los formularios semanales.
  /// 
  /// Es [true] si los formularios están activados, [false] por el contrario. Por defecto
  /// es [false].
  bool get areWeeklyFormsEnabled => _sharedPreferences?.getBool(weeklyFormsEnabledKey) ?? false;

  /// Guarda en Shared Preferences una nueva configuración de formularios semanales.
  set areWeeklyFormsEnabled (bool formsEnabled) {
    _sharedPreferences?.setBool(weeklyFormsEnabledKey, formsEnabled);
  }

  /// La configuración del usuario para la integración de la app con Google Fit.
  /// 
  /// Es [true] si la app está integrada con Google Fit, [false] por el contrario. 
  /// Por defecto es [false].
  bool get isGoogleFitIntegrated => _sharedPreferences?.getBool(isIntegratedWithGoogleFitKey) ?? false;

  /// Guarda en Shared Preferences una nueva configuración para la integración 
  /// de la app con Google Fit.
  set isGoogleFitIntegrated (bool integratedWithFit) {
    _sharedPreferences?.setBool(isIntegratedWithGoogleFitKey, integratedWithFit);
  }

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
    notifyListeners();
  }

  /// El identificador de la botella conectada previamente. Por defecto, es un 
  /// String vacío.
  String get deviceId => _sharedPreferences?.getString(deviceIdKey) ?? '';

  /// Guarda un nuevo ID BLE de una botella.  
  set deviceId (String newDeviceId) {
    _sharedPreferences?.setString(deviceIdKey, newDeviceId);
    notifyListeners();  
  }

  int get appStartups => _sharedPreferences?.getInt(appStartupCountKey) ?? 0;

  set appStartups(int startupCount) => _sharedPreferences?.setInt(appStartupCountKey, startupCount);
}