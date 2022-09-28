import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/models/enums/notification_types.dart';
import 'package:hydrate_app/src/models/settings.dart';
import 'package:hydrate_app/src/services/profile_service.dart';
import 'package:hydrate_app/src/services/settings_service.dart';

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

    _themeController.stream.listen(_setAppTheme);
    _allowedNotificationsController.stream.listen(_setAllowedNotifications);
    _canContributeDataController.stream.listen(_setDataContribution);
    _canUseWeeklyFormsController.stream.listen(_setWeeklyFormsEnabled);
    _isGoogleFitIntegratedController.stream.listen(_setIsGoogleFitIntegrated);

    _themeController.onListen = () {
      _themeController.add(_settings.appThemeMode);
    };

    _allowedNotificationsController.onListen = () {
      _allowedNotificationsController.add(_settings.allowedNotifications);
    };

    _canContributeDataController.onListen = () {
      _canContributeDataController.add(_settings.shouldContributeData);
    };

    _canUseWeeklyFormsController.onListen = () {
      _canUseWeeklyFormsController.add(_settings.areWeeklyFormsEnabled);
    };

    _isGoogleFitIntegratedController.onListen = () {
      _isGoogleFitIntegratedController.add(_settings.isGoogleFitIntegrated);
    };
  }

  // Streams de salida
  Stream<bool> get isSavePromptActive => _isSavePromptActiveController.stream;

  Stream<ThemeMode> get appThemeMode => _themeController.stream;
  Stream<NotificationTypes> get allowedNotifications => _allowedNotificationsController.stream;
  Stream<bool> get shouldContributeData => _canContributeDataController.stream;
  Stream<bool> get areWeeklyFormsEnabled => _canUseWeeklyFormsController.stream;
  Stream<bool> get isGoogleFitIntegrated => _isGoogleFitIntegratedController.stream;
  
  // Controladores para streams de salida.
  final StreamController<bool> _isSavePromptActiveController = StreamController.broadcast();

  // Sinks de entrada.
  Sink<bool> get isSavePromptActiveSink => _isSavePromptActiveController.sink;

  Sink<ThemeMode> get appThemeModeSink => _themeController.sink;
  Sink<NotificationTypes> get allowedNotificationsSink => _allowedNotificationsController.sink;
  Sink<bool> get shouldContributeDataSink => _canContributeDataController.sink;
  Sink<bool> get areWeeklyFormsEnabledSink => _canUseWeeklyFormsController.sink;
  Sink<bool> get isGoogleFitIntegratedSink => _isGoogleFitIntegratedController.sink;

  // Controladores para sinks de entrada.
  final StreamController<ThemeMode> _themeController = StreamController.broadcast();
  final StreamController<NotificationTypes> _allowedNotificationsController = StreamController.broadcast();
  final StreamController<bool> _canContributeDataController = StreamController.broadcast();
  final StreamController<bool> _canUseWeeklyFormsController = StreamController.broadcast();
  final StreamController<bool> _isGoogleFitIntegratedController = StreamController.broadcast();

  static const Duration savePromptDuration = Duration(seconds: 30);

  bool _isSavePromptActive = false;

  final Settings _settings;
  late final Settings _settingsChanges;

  void saveChanges(BuildContext context) async {

    final settingsProvider = Provider.of<SettingsService>(context, listen: false);
    final profileProvider = Provider.of<ProfileService>(context, listen: false);

    settingsProvider.setCurrentSettings(
      _settingsChanges, 
      profileProvider.profileId,
      userAccountId: profileProvider.linkedAccountId
    );
    
    _isSavePromptActive = false;
    _isSavePromptActiveController.add(_isSavePromptActive);
  } 
  
  void _setAppTheme(ThemeMode themeMode) {
    _settingsChanges.appThemeMode = themeMode;

    final hasChanges = _settingsChanges != _settings;

    _isSavePromptActive = hasChanges;
    _isSavePromptActiveController.add(_isSavePromptActive);  
  }

  void _setAllowedNotifications(NotificationTypes allowedNotifications) {
    _settingsChanges.allowedNotifications = allowedNotifications;

    final hasChanges = _settingsChanges != _settings;

    _isSavePromptActive = hasChanges;
    _isSavePromptActiveController.add(_isSavePromptActive); 
  }

  void _setDataContribution(bool shouldContributeData) {
    _settingsChanges.shouldContributeData = shouldContributeData;

    final hasChanges = _settingsChanges != _settings;

    _isSavePromptActive = hasChanges;
    _isSavePromptActiveController.add(_isSavePromptActive);
  }

  void _setWeeklyFormsEnabled(bool areWeeklyFormsEnabled) {
    _settingsChanges.areWeeklyFormsEnabled = areWeeklyFormsEnabled;

    final hasChanges = _settingsChanges != _settings;

    _isSavePromptActive = hasChanges;
    _isSavePromptActiveController.add(_isSavePromptActive);
  }

  void _setIsGoogleFitIntegrated(bool isGoogleFitIntegrated) {
    _settingsChanges.isGoogleFitIntegrated = isGoogleFitIntegrated;

    final hasChanges = _settingsChanges != _settings;

    _isSavePromptActive = hasChanges;
    _isSavePromptActiveController.add(_isSavePromptActive);
  }
}