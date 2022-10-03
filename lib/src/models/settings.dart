import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hydrate_app/src/models/enums/notification_source.dart';

class Settings {

  Settings(
    this.appThemeMode, 
    this.allowedNotifications, 
    this.shouldContributeData, 
    this.areWeeklyFormsEnabled,
    this.isGoogleFitIntegrated,
  ); 

  Settings.withNotifBits(
    this.appThemeMode, 
    int notificationPreferences, 
    this.shouldContributeData, 
    this.areWeeklyFormsEnabled,
    this.isGoogleFitIntegrated,
  ) : allowedNotifications = NotificationSourceExtension.notificationSourceFromBits(notificationPreferences); 

  factory Settings.defaults() {
    return Settings(
      ThemeMode.light,
      { NotificationSource.disabled },
      false, 
      false,
      false,
    );
  }

  factory Settings.from(Settings other) => Settings(
    other.appThemeMode,
    other.allowedNotifications, 
    other.shouldContributeData, 
    other.areWeeklyFormsEnabled,
    other.isGoogleFitIntegrated,
  );

  ThemeMode appThemeMode;
  Set<NotificationSource> allowedNotifications;
  bool shouldContributeData; 
  bool areWeeklyFormsEnabled;
  bool isGoogleFitIntegrated;

  set notificationPreferencesBits(int bits) {
    allowedNotifications = NotificationSourceExtension.notificationSourceFromBits(bits); 
  }

  int get notificationPreferencesBits {

    int bits = 0x00;

    for (final notificationTypeEnabled in allowedNotifications) {
      bits = bits | notificationTypeEnabled.bits;
    }

    return bits;
  }

  @override
  String toString() {
    // Usar un StringBuffer para formar la representación en String de este 
    // objeto.
    StringBuffer strBuf = StringBuffer("[Settings]: {");

    strBuf.writeAll(["appThemeMode: ", appThemeMode, ", "]);
    strBuf.writeAll(["allowedNotifications: ", allowedNotifications, ", "]);
    strBuf.writeAll(["shouldContributeData: ", shouldContributeData, ", "]);
    strBuf.writeAll(["areWeeklyFormsEnabled: ", areWeeklyFormsEnabled, ", "]);
    strBuf.writeAll(["isGoogleFitIntegrated: ", isGoogleFitIntegrated, ", "]);

    strBuf.write("}");

    return strBuf.toString();
  }

  @override
  bool operator==(covariant Settings other) {

    final areThemesEqual = appThemeMode == other.appThemeMode;
    final areNotifSourcesEqual = setEquals(allowedNotifications, other.allowedNotifications);
    final areDataContributionsEqual = shouldContributeData == other.shouldContributeData;
    final bothHaveWeeklyForms = areWeeklyFormsEnabled == other.areWeeklyFormsEnabled;
    final bothAreIntegratedWithFit = isGoogleFitIntegrated == other.isGoogleFitIntegrated;

    return areThemesEqual && areNotifSourcesEqual && areDataContributionsEqual 
        && bothHaveWeeklyForms && bothAreIntegratedWithFit;
  }

  @override 
  int get hashCode => Object.hashAll([
    appThemeMode,
    allowedNotifications,
    shouldContributeData,
    areWeeklyFormsEnabled,
    isGoogleFitIntegrated,
  ]);
}