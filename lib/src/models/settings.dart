import 'package:flutter/material.dart';
import 'package:hydrate_app/src/models/enums/notification_types.dart';

class Settings {

  Settings(
    this.appThemeMode, 
    this.allowedNotifications, 
    this.shouldContributeData, 
    this.areWeeklyFormsEnabled
  ); 

  factory Settings.defaults() {
    return Settings(
      ThemeMode.light,
      NotificationTypes.disabled,
      false, 
      false
    );
  }

  factory Settings.from(Settings other) => Settings(
    other.appThemeMode,
    other.allowedNotifications, 
    other.shouldContributeData, 
    other.areWeeklyFormsEnabled,
  );

  ThemeMode appThemeMode;
  NotificationTypes allowedNotifications;
  bool shouldContributeData; 
  bool areWeeklyFormsEnabled;

  @override
  String toString() {
    // Usar un StringBuffer para formar la representación en String de este 
    // objeto.
    StringBuffer strBuf = StringBuffer("[Settings]: {");

    strBuf.writeAll(["appThemeMode: ", appThemeMode, ", "]);
    strBuf.writeAll(["allowedNotifications: ", allowedNotifications, ", "]);
    strBuf.writeAll(["shouldContributeData: ", shouldContributeData, ", "]);
    strBuf.writeAll(["areWeeklyFormsEnabled: ", areWeeklyFormsEnabled, ", "]);

    strBuf.write("}");

    return strBuf.toString();
  }

  @override
  bool operator==(covariant Settings other) {

    final areThemesEqual = appThemeMode == other.appThemeMode;
    final areNotifsEqual = allowedNotifications == other.allowedNotifications;
    final areDataContributionsEqual = shouldContributeData == other.shouldContributeData;
    final bothHaveWeeklyForms = areWeeklyFormsEnabled == other.areWeeklyFormsEnabled;

    return areThemesEqual && areNotifsEqual && areDataContributionsEqual 
        && bothHaveWeeklyForms;
  }

  @override 
  int get hashCode => Object.hashAll([
    appThemeMode,
    allowedNotifications,
    shouldContributeData,
    areWeeklyFormsEnabled,
  ]);
}