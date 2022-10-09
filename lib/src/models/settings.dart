import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hydrate_app/src/models/enums/notification_source.dart';
import 'package:hydrate_app/src/utils/numbers_common.dart';

class Settings {

  Settings(
    this.id,
    this.appThemeMode, 
    this.notificationPreferences, 
    this.shouldContributeData, 
    this.areWeeklyFormsEnabled,
    this.isGoogleFitIntegrated,
    this.bondedDeviceId,
    this.localeCode,
  ); 

  Settings.withNotifBits(
    this.id,
    this.appThemeMode, 
    int notificationPreferences, 
    this.shouldContributeData, 
    this.areWeeklyFormsEnabled,
    this.isGoogleFitIntegrated, {
    this.bondedDeviceId = "",
    this.localeCode = "en-US",
  }) : notificationPreferences = NotificationSourceExtension.notificationSourceFromBits(notificationPreferences); 

  factory Settings.defaults() {
    return Settings(
      "",
      ThemeMode.light,
      { NotificationSource.disabled },
      false, 
      false,
      false,
      "",
      "",
    );
  }

  factory Settings.from(Settings other) => Settings(
    other.id,
    other.appThemeMode,
    other.notificationPreferences, 
    other.shouldContributeData, 
    other.areWeeklyFormsEnabled,
    other.isGoogleFitIntegrated,
    other.bondedDeviceId,
    other.localeCode,
  );

  final String id;
  ThemeMode appThemeMode;
  Set<NotificationSource> notificationPreferences;
  bool shouldContributeData; 
  bool areWeeklyFormsEnabled;
  bool isGoogleFitIntegrated;
  String bondedDeviceId;
  String localeCode;

  bool get areNotificationsEnabled => !(notificationPreferences.contains(NotificationSource.disabled));

  set notificationPreferencesBits(int bits) {
    notificationPreferences = NotificationSourceExtension.notificationSourceFromBits(bits); 
  }

  int get notificationPreferencesBits {

    int bits = 0x00;

    for (final notificationTypeEnabled in notificationPreferences) {
      bits = bits | notificationTypeEnabled.bits;
    }

    return bits;
  }

  static const Map<String, String> _jsonAttributeNames = {
    "id": "id", 
    "appThemeMode": "temaDeColor", 
    "shouldContributeData": "aportaDatosAbiertos", 
    "areRecurrentFormsEnabled": "formulariosRecurrentesActivados", 
    "isGoogleFitIntegrated": "integradoConGoogleFit", 
    "notificationPreferences": "notificacionesPermitidas",
    "deviceId": "idDispositivo",
    "localeCode": "codigoLocalizacion",
  };

  factory Settings.fromJson(String jsonString) {

    final map = json.decode(jsonString);

    if (map is! Map<String, Object?>) return Settings.defaults();

    final String parsedId = map[_jsonAttributeNames["id"]].toString();

    final int parsedThemeModeIndex = int.tryParse(map[_jsonAttributeNames["appThemeMode"]].toString()) ?? 0;

    final bool parsedContributeData = map[_jsonAttributeNames["shouldContributeData"]].toString() == "true";
    final bool parsedRecurrentFormsEnabled = map[_jsonAttributeNames["areRecurrentFormsEnabled"]] == "true";
    final bool parsedGoogleFitIntegrated = map[_jsonAttributeNames["isGoogleFitIntegrated"]]  == "true";

    final int parsedNotificationPreferencesBitmask = int.tryParse(map[_jsonAttributeNames["notificationPreferences"]].toString()) ?? 0; 
    final String parsedDeviceId = map[_jsonAttributeNames["deviceId"]].toString();
    final String parsedLocaleCode = map[_jsonAttributeNames["localeCode"]].toString();

    final ThemeMode appThemeMode = ThemeMode.values[constrain(
      parsedThemeModeIndex,
      min: 0,
      max: ThemeMode.values.length
    )];

    return Settings.withNotifBits(
      parsedId,
      appThemeMode, 
      parsedNotificationPreferencesBitmask, 
      parsedContributeData, 
      parsedRecurrentFormsEnabled, 
      parsedGoogleFitIntegrated,
      bondedDeviceId: parsedDeviceId,
      localeCode: parsedLocaleCode,
    );
  }

  Map<String, Object?> toJson() {
    
    final Map<String, Object?> jsonMap = {};

    jsonMap[_jsonAttributeNames["id"]!] = id;
    jsonMap[_jsonAttributeNames["appThemeMode"]!] = appThemeMode.index;
    jsonMap[_jsonAttributeNames["shouldContributeData"]!] = shouldContributeData;
    jsonMap[_jsonAttributeNames["areRecurrentFormsEnabled"]!] = areWeeklyFormsEnabled;
    jsonMap[_jsonAttributeNames["isGoogleFitIntegrated"]!] = isGoogleFitIntegrated;
    jsonMap[_jsonAttributeNames["notificationPreferences"]!] = notificationPreferencesBits;
    jsonMap[_jsonAttributeNames["deviceId"]!] = bondedDeviceId;
    jsonMap[_jsonAttributeNames["localeCode"]!] = localeCode;

    return jsonMap;
  }

  @override
  String toString() {
    // Usar un StringBuffer para formar la representación en String de este 
    // objeto.
    StringBuffer strBuf = StringBuffer("[Settings]: {");

    strBuf.writeAll(["id: ", id, ", "]);
    strBuf.writeAll(["appThemeMode: ", appThemeMode, ", "]);
    strBuf.writeAll(["allowedNotifications: ", notificationPreferences, ", "]);
    strBuf.writeAll(["shouldContributeData: ", shouldContributeData, ", "]);
    strBuf.writeAll(["areWeeklyFormsEnabled: ", areWeeklyFormsEnabled, ", "]);
    strBuf.writeAll(["isGoogleFitIntegrated: ", isGoogleFitIntegrated, ", "]);
    strBuf.writeAll(["bondedDeviceId: ", bondedDeviceId, ", "]);
    strBuf.writeAll(["localeCode: ", localeCode, ", "]);

    strBuf.write("}");

    return strBuf.toString();
  }

  @override
  bool operator==(covariant Settings other) {

    final areIdsEqual = id == other.id;
    final areThemesEqual = appThemeMode == other.appThemeMode;
    final areNotifSourcesEqual = setEquals(notificationPreferences, other.notificationPreferences);
    final areDataContributionsEqual = shouldContributeData == other.shouldContributeData;
    final bothHaveWeeklyForms = areWeeklyFormsEnabled == other.areWeeklyFormsEnabled;
    final bothAreIntegratedWithFit = isGoogleFitIntegrated == other.isGoogleFitIntegrated;
    final areBondedDeviceIdsEqual = bondedDeviceId == other.bondedDeviceId;
    final areLocaleCodesEqual = localeCode == other.localeCode;

    return areIdsEqual && areThemesEqual && areNotifSourcesEqual && 
        areDataContributionsEqual  && bothHaveWeeklyForms && 
        bothAreIntegratedWithFit && areBondedDeviceIdsEqual && areLocaleCodesEqual;
  }

  @override 
  int get hashCode => Object.hashAll([
    id,
    appThemeMode,
    notificationPreferences,
    shouldContributeData,
    areWeeklyFormsEnabled,
    isGoogleFitIntegrated,
    bondedDeviceId,
    localeCode,
  ]);
}