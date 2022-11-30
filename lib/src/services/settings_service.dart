import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydrate_app/src/api/config_api.dart';
import 'package:hydrate_app/src/exceptions/api_exception.dart';
import 'package:hydrate_app/src/models/activity_type.dart';
import 'package:hydrate_app/src/models/enums/notification_source.dart';
import 'package:hydrate_app/src/models/settings.dart';
import 'package:hydrate_app/src/services/activity_service.dart';
import 'package:hydrate_app/src/services/device_pairing_service.dart';
import 'package:hydrate_app/src/services/google_fit_service.dart';
import 'package:hydrate_app/src/services/notification_service.dart';
import 'package:hydrate_app/src/services/profile_service.dart';
import 'package:hydrate_app/src/utils/background_tasks.dart';
import 'package:hydrate_app/src/utils/jwt_parser.dart';

/// Facilita el acceso y modificación de la configuración de la app en Shared Preferences.
class SettingsService with ChangeNotifier {

  static late final SharedPreferences? _sharedPreferences;

  factory SettingsService() => SettingsService._internal();

  SettingsService._internal();

  /// Inicializa y asigna la instancia de Shared Preferences.
  static Future<void> init({ bool recordAppStartup = false }) async {
    _sharedPreferences = await SharedPreferences.getInstance();

    if (recordAppStartup) {
      int currentStartupCount = _sharedPreferences?.getInt(appStartupCountKey) ?? 0;
      currentStartupCount++;
      _sharedPreferences?.setInt(appStartupCountKey, currentStartupCount);
    }
  }

  static const String versionName = "1.0.0+1";

  static const int appStartupsToShowGuides = 5;

  Settings get currentSettings => _getCurrentSettings();

  Future<Settings> fecthSettingsForAccount(String authToken) async {

    Settings settings = _getCurrentSettings(); 
    
    if (authToken.isNotEmpty) {
      try {
        final settingsForAccount = await ConfigApi.instance.fetchSettings(authToken);

        await updateLocalSettings(settingsForAccount);

        settings = settingsForAccount;
      } on ApiException catch (ex) {
        debugPrint("Error while fetching user configuration ($ex)");
      }
    }

    return settings;
  }

  Future<void> syncSettingsWithLocalChanges(String authToken) async {

    try {
      final localSettings = _getCurrentSettings();

      await ConfigApi.instance.updateSettings(authToken, localSettings);
      
    //TODO: notificar al usuario que su perfil no pudo ser sincronizado.
    } on ApiException catch (ex) {
      debugPrint("Error while updating user configuration ($ex)");
    } on SocketException catch (ex) {
      debugPrint("Error al sincronizar cambios a perfil, el dispositivo tiene conexion? ($ex)");
    } on IOException catch (ex) {
      debugPrint("Error al sincronizar cambios a perfil, el dispositivo tiene conexion? ($ex)");
    }
  }

  /// Actualiza la configuración local de la app con los [changes] 
  /// especificados.
  /// 
  /// Retorna un conjunto con los nombres de todos los ajustes modificados
  /// (aquellos donde el valor actual y el descrito en changes son diferentes).
  Future<Set<String>> updateLocalSettings(Settings changes) async {

    final currentSettings = _getCurrentSettings();
    final modifiedAttributes = <String>{};

    final bool hasSettingsIdChanged = currentSettings.id != changes.id;

    if (hasSettingsIdChanged) {
      settingsId = changes.id;
    }

    final hasThemeChanged = currentSettings.appThemeMode != changes.appThemeMode;

    if (hasThemeChanged) {
      appThemeMode = changes.appThemeMode;
      modifiedAttributes.add(appThemeModeKey);
    }

    final hasNotificationsChanged = currentSettings.notificationPreferences != changes.notificationPreferences;

    if (hasNotificationsChanged) {
      final bool wereNotificationsDisabled = changes.notificationPreferences
        .contains(NotificationSource.disabled);
      
      final bool canNotificationPrefsBeChanged;

      // Si las notificaciones fueron desactivadas, no hay ningún requisito 
      // para el cambio. Si fueron activadas, es necesario que la app tenga 
      // el permiso de recibir notificaciones.
      if (wereNotificationsDisabled) {
        canNotificationPrefsBeChanged = true;
      } else {
        if (await Permission.notification.isDenied) {
          final wasSettingsPageOpened = await openAppSettings();
          canNotificationPrefsBeChanged = wasSettingsPageOpened && !(await Permission.notification.isDenied);
        } else {
          canNotificationPrefsBeChanged = true;
        }
      }

      if (canNotificationPrefsBeChanged) {
        enabledNotificationSources = changes.notificationPreferences;
        modifiedAttributes.add(notificationPreferencesKey);
      }
    }

    final hasWeeklyFormsChanged = currentSettings.areWeeklyFormsEnabled != changes.areWeeklyFormsEnabled;

    if (hasWeeklyFormsChanged) {
      areWeeklyFormsEnabled = changes.areWeeklyFormsEnabled;
      modifiedAttributes.add(weeklyFormsEnabledKey);
    }

    final hasIntegrationWithGoogleFitChanged = currentSettings.isGoogleFitIntegrated != changes.isGoogleFitIntegrated;

    if (hasIntegrationWithGoogleFitChanged) {
      isGoogleFitIntegrated = changes.isGoogleFitIntegrated;
      modifiedAttributes.add(isIntegratedWithGoogleFitKey);
    }

    final hasDataContributionChanged = currentSettings.shouldContributeData != changes.shouldContributeData;

    if (hasDataContributionChanged) {
      isSharingData = changes.shouldContributeData;
      modifiedAttributes.add(contributeDataKey);
    }

    return modifiedAttributes;
  }

  void applyCurrentSettings({ 
    String userAuthToken = "",
    bool notify = false,
    final DevicePairingService? devicePairingService,
    final ProfileService? profileService,
    final ActivityService? activityService,
  }) {

    final settings = _getCurrentSettings();
    final bool isUserAuthenticated = userAuthToken.isNotEmpty && !isTokenExpired(userAuthToken);

    // Registrar o eliminar la tarea periodica para aportar datos 
    // estadísticos a la API web.
    if (settings.shouldContributeData) {
      // Registrar tarea para aportar datos cada semana.
      BackgroundTasks.instance.enableDataContribution(userAuthToken);
    } else {
      // Cancelar tarea que aporta datos.
      BackgroundTasks.instance.cancelOpenDataContributions();
    }

    if (settings.isGoogleFitIntegrated) {
      GoogleFitService.instance.signInWithGoogle();

    } else if (GoogleFitService.instance.isUserSignedInWithGoogle) {
      GoogleFitService.instance.signOut();
    }

    if (isUserAuthenticated) {
      if (settings.areNotificationsEnabled) {
        NotificationService.instance.init(
          isInDebugMode: true,
          authToken: userAuthToken,
        ).then((_) {
          NotificationService.instance.sendFcmTokenToServer(userAuthToken);
        });

      } else {
        NotificationService.instance.clearFcmToken(userAuthToken)
          .then((_) => NotificationService.instance.disable());
      }
    } 
    
    if (!settings.areNotificationsEnabled) {
      NotificationService.instance.disable();
    }

    if (devicePairingService != null && activityService != null && profileService != null) {
      _setIntegrationWithGoogleFit(
        settings: settings, 
        authToken: userAuthToken,
        devicePairingService: devicePairingService,
        profileService: profileService,
        activityService: activityService,
      );
    }

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _setIntegrationWithGoogleFit({
    required Settings settings, 
    required String authToken,
    bool notify = false,
    required DevicePairingService devicePairingService,
    required ProfileService profileService,
    required ActivityService activityService,
  }) async {
    // Aplicar configuracion de sincronizacion con Google Fit.
    if (settings.isGoogleFitIntegrated && authToken.isNotEmpty) {
      GoogleFitService.instance.hydrateProfileId = getProfileIdFromJwt(authToken);

      bool isSignedInWithGoogle = GoogleFitService.instance.isUserSignedInWithGoogle;

      final requiresGoogleSignIn = !(GoogleFitService.instance.isSigningIn || isSignedInWithGoogle);

      if (requiresGoogleSignIn) {
        isSignedInWithGoogle = await GoogleFitService.instance.signInWithGoogle();
      }

      if (isSignedInWithGoogle) {
        devicePairingService.addOnNewHydrationRecordListener(
          GoogleFitService.onSyncHydrationRecordListenerName, 
          GoogleFitService.instance.addHydrationRecordToSyncQueue
        );

        final activityTypes = (await activityService.activityTypes) ?? const <ActivityType>[];
        final latestSyncWithGoogleFit = (await profileService.profile)?.latestSyncWithGoogleFit;

        final newActivityRecords = await GoogleFitService.instance.syncActivitySessions(
          startTime: latestSyncWithGoogleFit,
          endTime: DateTime.now(),
          supportedGoogleFitActTypes: Map.fromEntries(activityTypes.map((activityType) => MapEntry(activityType.googleFitActivityType, activityType))),
        );

        final activityPersistenceResults = await activityService.saveActivityRecords(newActivityRecords);

        final wasSyncSuccessful = newActivityRecords.length == activityPersistenceResults.length;

        if (wasSyncSuccessful) {
          await profileService.updateGoogleFitSyncDate();
        }
      }
    } else {
      devicePairingService.removeHydrationRecordListener(GoogleFitService.onSyncHydrationRecordListenerName);
    }

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> resetToDefaults() async {

    if (_sharedPreferences == null) return;

    final defaultSettings = Settings.defaults();

    final SharedPreferences sharedPreferences = _sharedPreferences!;

    await Future.wait<bool>([
      sharedPreferences.setInt(appThemeModeKey, defaultSettings.appThemeMode.index),
      sharedPreferences.setBool(contributeDataKey, defaultSettings.shouldContributeData),
      sharedPreferences.setBool(weeklyFormsEnabledKey, defaultSettings.areWeeklyFormsEnabled),
      sharedPreferences.setBool(isIntegratedWithGoogleFitKey, defaultSettings.isGoogleFitIntegrated),
      sharedPreferences.setInt(notificationPreferencesKey, defaultSettings.notificationPreferencesBits),
      sharedPreferences.setString(localeCodeKey, defaultSettings.localeCode),
      sharedPreferences.setString(deviceIdKey, defaultSettings.bondedDeviceId),
    ]);
  }

  // SharedPreferences Get/Set
  
  static const String settingsIdKey = "id_configuracion";
  static const String appThemeModeKey = "tema";
  static const String contributeDataKey = "aportarDatos";
  static const String weeklyFormsEnabledKey = "formRecurrentes";
  static const String notificationPreferencesKey = "notificaciones";
  static const String isIntegratedWithGoogleFitKey = "google_fit_conectado";
  static const String localeCodeKey = "codigoFormato";
  static const String deviceIdKey = "idDispositivo";
  static const String appStartupCountKey = "inicios_app";

  Settings _getCurrentSettings() => Settings(
    settingsId,
    appThemeMode,
    enabledNotificationSources,
    isSharingData,
    areWeeklyFormsEnabled,
    isGoogleFitIntegrated,
    deviceId,
    localeCode,
  );

  String get settingsId => _sharedPreferences?.getString(settingsIdKey) ?? "";

  set settingsId(String newSettingsId) => _sharedPreferences?.setString(settingsIdKey, newSettingsId);

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
  Set<NotificationSource> get enabledNotificationSources {
    int notifTypesBitmask = _sharedPreferences?.getInt(notificationPreferencesKey) ?? 0;

    final notificationSet = NotificationSourceExtension.notificationSourceFromBits(notifTypesBitmask);

    return notificationSet;
  }

  bool get areNotificationsEnabled => !enabledNotificationSources.contains(NotificationSource.disabled);

  /// Guarda la configuración de notificaciones del usuario.
  set enabledNotificationSources (Set<NotificationSource> notificationSettings) {
    int notifSettingsBits = 0x00;

    if (!notificationSettings.contains(NotificationSource.disabled)) {
      for (final enabledNotifType in notificationSettings) {
        notifSettingsBits = notifSettingsBits | enabledNotifType.bits;
      }
    }

    _sharedPreferences?.setInt(notificationPreferencesKey, notifSettingsBits);
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