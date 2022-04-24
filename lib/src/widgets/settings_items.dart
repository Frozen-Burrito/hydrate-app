import 'package:flutter/material.dart';

import 'package:hydrate_app/src/models/api.dart';
import 'package:hydrate_app/src/provider/settings_provider.dart';
import 'package:hydrate_app/src/utils/launch_url.dart';

class SettingsItems extends StatefulWidget {

  final SettingsProvider settingsProvider;

  const SettingsItems(this.settingsProvider, {
    Key? key,
  }) : super(key: key);

  @override
  State<SettingsItems> createState() => _SettingsItemsState();
}

class _SettingsItemsState extends State<SettingsItems> {

  ThemeMode _selectedThemeMode = ThemeMode.system;
  ThemeMode _originalThemeMode = ThemeMode.system;

  NotificationSettings _selectedNotifications = NotificationSettings.disabled;
  NotificationSettings _originalNotifications = NotificationSettings.disabled;

  bool _contributeData = false; 
  bool _originalContributeData = false; 

  bool _weeklyForms = false; 
  bool _originalWeeklyForms = false; 

  bool _isSnackbarActive = false;

  static final _themeLabels = <String>['Sistema','Claro','Oscuro'];

  static final _notifLabels = <String>['Ninguna','Metas','Batería','Todas'];

  final _themeDropdownItems = ThemeMode.values
      .map((option) => DropdownMenuItem(
          value: option.index,
          child: Text(_themeLabels[option.index]),
        ),
      ).toList();

  final _notifDropdownItems = NotificationSettings.values
      .map((option) => DropdownMenuItem(
          value: option.index,
          child: Text(_notifLabels[option.index]),
        ),
      ).toList();

  @override
  void initState() {
    super.initState();

    _originalThemeMode = widget.settingsProvider.appThemeMode;
    _originalContributeData = widget.settingsProvider.isSharingData;
    _originalNotifications = widget.settingsProvider.notificationSettings;
    _originalWeeklyForms = widget.settingsProvider.areWeeklyFormsEnabled;

    _selectedThemeMode = _originalThemeMode;
    _contributeData = _originalContributeData;
    _selectedNotifications = _originalNotifications;
    _weeklyForms = _originalWeeklyForms;
  }

  /// Compara los valores originales con los ajustes modificados. Si son diferentes,
  /// muestra un [SnackBar] para confirmar los cambios.
  void compareChanges(BuildContext context) {
    
    bool hasThemeChanged = _originalThemeMode != _selectedThemeMode;
    bool hasDataContributionChanged = _originalContributeData != _contributeData;
    bool hasNotificationsChanged = _originalNotifications != _selectedNotifications;
    bool hasWeeklyFormsChanged = _originalWeeklyForms != _originalWeeklyForms;

    bool settingsChanged = hasThemeChanged || hasDataContributionChanged || hasNotificationsChanged || hasWeeklyFormsChanged;

    if (!_isSnackbarActive && settingsChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tienes ajustes modificados sin guardar'),
          duration: const Duration(minutes: 30),
          action: SnackBarAction(
            label: 'Guardar', 
            onPressed: () {
              saveChanges();
              _isSnackbarActive = false;
            },
          ),
        )
      );

      _isSnackbarActive = true;
    }
  }

  /// Guarda los cambios de ajustes en SharedPreferences usando [SettingsProvider].
  /// 
  /// Solo guarda las modificaciones necesarias.
  void saveChanges() {

    bool hasThemeChanged = _originalThemeMode != _selectedThemeMode;
    bool hasDataContributionChanged = _originalContributeData != _contributeData;
    bool hasNotificationsChanged = _originalNotifications != _selectedNotifications;
    bool hasWeeklyFormsChanged = _originalWeeklyForms != _originalWeeklyForms;


    if (hasThemeChanged) {
      print('Theme was modified: de $_originalThemeMode a $_selectedThemeMode');
      widget.settingsProvider.appThemeMode = _selectedThemeMode;
      _originalThemeMode = _selectedThemeMode;
    }

    if (hasDataContributionChanged) {
      widget.settingsProvider.isSharingData = _contributeData;
      _originalContributeData = _contributeData;
    }

    if (hasNotificationsChanged) {
      widget.settingsProvider.notificationSettings = _selectedNotifications;
      _originalNotifications = _selectedNotifications;
    }

    if (hasWeeklyFormsChanged) {
      widget.settingsProvider.areWeeklyFormsEnabled = _weeklyForms;
      _originalWeeklyForms = _weeklyForms;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTileTheme(
      iconColor: Theme.of(context).colorScheme.onBackground,
      textColor: Theme.of(context).colorScheme.onBackground,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        shrinkWrap: true,
        children: <Widget> [
          const SizedBox( height: 24.0, ),
    
          const Divider( height: 1.0, ),
          Padding(
            padding: const EdgeInsets.symmetric( vertical: 16.0, ),
            child: ListTile(
              leading: const Icon(
                Icons.colorize, 
                size: 24.0, 
              ),
              title: const Text('Tema de color'),
              trailing: SizedBox(
                width: MediaQuery.of(context).size.width * 0.35,
                child: DropdownButtonFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedThemeMode.index,
                  items: _themeDropdownItems,
                  onChanged: (int? newValue) {
                    _selectedThemeMode = ThemeMode.values[newValue ?? 0];
                    compareChanges(context);
                  },
                ),
              ),
            ),
          ),
    
          const Divider( height: 1.0, ),
          Padding(
            padding: const EdgeInsets.symmetric( vertical: 16.0, ),
            child: SwitchListTile(
              secondary: const Icon(
                Icons.bar_chart, 
                size: 24.0, 
              ),
              title: const Text('Contribuir a datos abiertos'),
              value: _contributeData,
              onChanged: (bool value) {
                setState(() {
                  _contributeData = value;
                  compareChanges(context);
                });
              },
            ),
          ),
    
          const Divider( height: 1.0, ),
          Padding(
            padding: const EdgeInsets.symmetric( vertical: 16.0, ),
            child: ListTile(
              leading: const Icon(
                Icons.notifications, 
                size: 24.0,
              ),
              title: const Text('Notificaciones'),
              trailing: SizedBox(
                width: MediaQuery.of(context).size.width * 0.35,
                child: DropdownButtonFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedNotifications.index,
                  items: _notifDropdownItems,
                  onChanged: (int? newValue) {
                    _selectedNotifications = NotificationSettings.values[newValue ?? 0];
                    compareChanges(context);
                  },
                ),
              ),
            ),
          ),

          const Divider( height: 1.0, ),
          Padding(
            padding: const EdgeInsets.symmetric( vertical: 16.0, ),
            child: SwitchListTile(
              secondary: const Icon(
                Icons.event_note, 
                size: 24.0, 
              ),
              title: const Text('Formularios semanales'),
              value: _weeklyForms,
              onChanged: (bool value) {
                setState(() {
                  _weeklyForms = value;
                  compareChanges(context);
                });
              },
            ),
          ),

          const Divider( height: 1.0, ),
          ListTile(
            minVerticalPadding: 24.0,
            leading: const Icon(
              Icons.question_answer, 
              size: 24.0, 
            ),
            title: const Text('Enviar comentarios'),
            trailing: const Icon(
              Icons.arrow_forward,
              size: 24.0,
            ),
            onTap: () => UrlLauncher.launchUrlInBrowser(API.uriFor('comentarios')),
          ),
    
          const Divider( height: 1.0, ),
          ListTile(
            minVerticalPadding: 24.0,
            leading: const Icon(
              Icons.lightbulb,
              size: 24.0, 
            ),
            title: const Text('Guías de usuario'),
            trailing: const Icon(
              Icons.arrow_forward,
              size: 24.0,
            ),
            onTap: () => UrlLauncher.launchUrlInBrowser(API.uriFor('guias')),
          ),
    
          const Padding(
            padding: EdgeInsets.symmetric( horizontal: 24.0, vertical: 8.0,),
            child: Text(
              'Versión: 0.0.4+3',
              style: TextStyle(color: Colors.grey),
            ),
          )
        ],
      ),
    );
  }
}