import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import 'package:hydrate_app/src/models/enums/notification_types.dart';
import 'package:hydrate_app/src/models/settings.dart';
import 'package:hydrate_app/src/provider/settings_provider.dart';
import 'package:hydrate_app/src/utils/background_tasks.dart';

/// Un componente que controla los cambios de ajustes a la app y permite 
/// al usuario confirmarlos o descartarlos. 
/// 
/// Esta clase sigue el patrón BLoC. 
class EditSettingsBloc {

  EditSettingsBloc(Settings currentSettings) 
    : _settings = currentSettings {

    _settingsChanges = Settings.from(currentSettings);

    _isSavePromptActiveController.onListen = () {
      _isSavePromptActiveController.add(_isSavePromptActive);
    };

    _userAccountIdController.stream.listen(_setAccountId);

    _themeController.stream.listen(_setAppTheme);
    _allowedNotificationsController.stream.listen(_setAllowedNotifications);
    _canContributeDataController.stream.listen(_setDataContribution);
    _canUseWeeklyFormsController.stream.listen(_setWeeklyFormsEnabled);
  }

  // Streams de salida
  Stream<bool> get isSavePromptActive => _isSavePromptActiveController.stream;

  Stream<ThemeMode> get appThemeMode => _themeController.stream;
  Stream<NotificationTypes> get allowedNotifications => _allowedNotificationsController.stream;
  Stream<bool> get shouldContributeData => _canContributeDataController.stream;
  Stream<bool> get areWeeklyFormsEnabled => _canUseWeeklyFormsController.stream;
  
  // Controladores para streams de salida.
  final StreamController<bool> _isSavePromptActiveController = StreamController.broadcast();

  // Sinks de entrada.
  Sink<bool> get isSavePromtActiveSink => _isSavePromptActiveController.sink;
  Sink<String> get userAccountIdSink => _userAccountIdController.sink;

  Sink<ThemeMode> get appThemeModeSink => _themeController.sink;
  Sink<NotificationTypes> get allowedNotificationsSink => _allowedNotificationsController.sink;
  Sink<bool> get shouldContributeDataSink => _canContributeDataController.sink;
  Sink<bool> get areWeeklyFormsEnabledSink => _canUseWeeklyFormsController.sink;

  // Controladores para sinks de entrada.
  final StreamController<String> _userAccountIdController = StreamController();

  final StreamController<ThemeMode> _themeController = StreamController.broadcast();
  final StreamController<NotificationTypes> _allowedNotificationsController = StreamController.broadcast();
  final StreamController<bool> _canContributeDataController = StreamController.broadcast();
  final StreamController<bool> _canUseWeeklyFormsController = StreamController.broadcast();

  static const Duration savePromptDuration = Duration(seconds: 30);

  bool _isSavePromptActive = false;
  String _userAccountId = "";

  final Settings _settings;
  late final Settings _settingsChanges;

  void saveChanges(BuildContext context) {

    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    bool hasThemeChanged = _settings.appThemeMode != _settingsChanges.appThemeMode;
    bool hasDataContributionChanged = _settings.allowedNotifications != _settingsChanges.allowedNotifications;
    bool hasNotificationsChanged = _settings.shouldContributeData != _settingsChanges.shouldContributeData;
    bool hasWeeklyFormsChanged = _settings.areWeeklyFormsEnabled != _settingsChanges.areWeeklyFormsEnabled;

    if (hasThemeChanged) {
      settingsProvider.appThemeMode = _settingsChanges.appThemeMode;
      _settings.appThemeMode = _settingsChanges.appThemeMode;
    }

    if (hasDataContributionChanged) {
      settingsProvider.isSharingData = _settingsChanges.shouldContributeData;
      _settings.shouldContributeData = _settingsChanges.shouldContributeData;

      // Registrar o eliminar la tarea periodica para aportar datos 
      // estadísticos a la API web.
      if (_settingsChanges.shouldContributeData) {
        // Registrar tarea para aportar datos cada semana.
        Workmanager().registerPeriodicTask(
          BackgroundTasks.sendStatsData.uniqueName,
          BackgroundTasks.sendStatsData.taskName,
          frequency: BackgroundTasks.sendStatsData.frequency,
          initialDelay: BackgroundTasks.sendStatsData.initialDelay,
          constraints: BackgroundTasks.sendStatsData.constraints,
          inputData: <String, dynamic>{
            BackgroundTasks.taskInputProfileId: settingsProvider.currentProfileId,
            BackgroundTasks.taskInputAccountId: _userAccountId,
          },
        );

      } else {
        // Cancelar tarea que aporta datos.
        Workmanager().cancelByUniqueName(BackgroundTasks.sendStatsDataTaskName);
      }
    }

    if (hasNotificationsChanged) {
      settingsProvider.notificationSettings = _settingsChanges.allowedNotifications;
      _settings.allowedNotifications = _settingsChanges.allowedNotifications;
    }

    if (hasWeeklyFormsChanged) {
      settingsProvider.areWeeklyFormsEnabled = _settingsChanges.areWeeklyFormsEnabled;
      _settings.areWeeklyFormsEnabled = _settingsChanges.areWeeklyFormsEnabled;
    }

    _isSavePromptActive = false;
    _isSavePromptActiveController.add(_isSavePromptActive);
  } 

  void _setAccountId(String userAccountId) {
    _userAccountId = userAccountId;
  }
  
  void _setAppTheme(ThemeMode themeMode) {
    _settingsChanges.appThemeMode = themeMode;

    final hasChanges = _settingsChanges != _settings;

    _isSavePromptActive = hasChanges;
    _isSavePromptActiveController.add(_isSavePromptActive);  
  }

  void _setAllowedNotifications(NotificationTypes allowedNotifications) {
    _settingsChanges.allowedNotifications = allowedNotifications;
  }

  void _setDataContribution(bool shouldContributeData) {
    _settingsChanges.shouldContributeData = shouldContributeData;
  }

  void _setWeeklyFormsEnabled(bool areWeeklyFormsEnabled) {
    _settingsChanges.areWeeklyFormsEnabled = areWeeklyFormsEnabled;
  }
}