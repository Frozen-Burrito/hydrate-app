import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/models/api.dart';
import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/provider/profile_provider.dart';
import 'package:hydrate_app/src/provider/settings_provider.dart';
import 'package:hydrate_app/src/utils/launch_url.dart';
import 'package:hydrate_app/src/utils/background_tasks.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

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

  bool _shouldContributeData = false; 
  bool _originalContributeData = false;
  String _userAccountId = ""; 

  bool _weeklyForms = false; 
  bool _originalWeeklyForms = false; 

  bool _isSnackbarActive = false;

  @override
  void initState() {
    super.initState();

    _originalThemeMode = widget.settingsProvider.appThemeMode;
    _originalContributeData = widget.settingsProvider.isSharingData;
    _originalNotifications = widget.settingsProvider.notificationSettings;
    _originalWeeklyForms = widget.settingsProvider.areWeeklyFormsEnabled;

    _selectedThemeMode = _originalThemeMode;
    _shouldContributeData = _originalContributeData;
    _selectedNotifications = _originalNotifications;
    _weeklyForms = _originalWeeklyForms;
  }

  /// Compara los valores originales con los ajustes modificados. Si son diferentes,
  /// muestra un [SnackBar] para confirmar los cambios.
  void compareChanges(BuildContext context) {
    
    // Determinar si hay campos que han sido modificados por el usuario.
    bool hasThemeChanged = _originalThemeMode != _selectedThemeMode;
    bool hasDataContributionChanged = _originalContributeData != _shouldContributeData;
    bool hasNotificationsChanged = _originalNotifications != _selectedNotifications;
    bool hasWeeklyFormsChanged = _originalWeeklyForms != _weeklyForms;

    bool settingsChanged = hasThemeChanged || hasDataContributionChanged || hasNotificationsChanged || hasWeeklyFormsChanged;

    if (!_isSnackbarActive && settingsChanged) {
      // Si no hay ya un Snackbar de confirmación de cambios y el usuario 
      // realizó cambios, mostrar el snackbar.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.unsavedChanges),
          duration: const Duration(minutes: 30),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.save, 
            onPressed: () {
              saveChanges( userAccountId: _userAccountId );
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
  void saveChanges({ String? userAccountId }) {

    bool hasThemeChanged = _originalThemeMode != _selectedThemeMode;
    bool hasDataContributionChanged = _originalContributeData != _shouldContributeData;
    bool hasNotificationsChanged = _originalNotifications != _selectedNotifications;
    bool hasWeeklyFormsChanged = _originalWeeklyForms != _weeklyForms;

    if (hasThemeChanged) {
      widget.settingsProvider.appThemeMode = _selectedThemeMode;
      _originalThemeMode = _selectedThemeMode;
    }

    if (hasDataContributionChanged) {
      widget.settingsProvider.isSharingData = _shouldContributeData;
      _originalContributeData = _shouldContributeData;

      // Registrar o eliminar la tarea periodica para aportar datos 
      // estadísticos a la API web.
      if (_shouldContributeData) {
        // Registrar tarea para aportar datos cada semana.
        Workmanager().registerPeriodicTask(
          BackgroundTasks.sendStatsData.uniqueName,
          BackgroundTasks.sendStatsData.taskName,
          frequency: BackgroundTasks.sendStatsData.frequency,
          initialDelay: BackgroundTasks.sendStatsData.initialDelay,
          constraints: BackgroundTasks.sendStatsData.constraints,
          inputData: <String, dynamic>{
            BackgroundTasks.taskInputProfileId: widget.settingsProvider.currentProfileId,
            BackgroundTasks.taskInputAccountId: userAccountId,
          },
        );

      } else {
        // Cancelar tarea que aporta datos.
        Workmanager().cancelByUniqueName(BackgroundTasks.sendStatsDataTaskName);
      }
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

    final localizations = AppLocalizations.of(context)!;

    final themeLabels = [
      localizations.themeOptSys,
      localizations.themeOptLight,
      localizations.themeOptDark,
    ];

    final notifLabels = [
      localizations.notifOptNone,
      localizations.notifOptGoals,
      localizations.notifOptBattery,
      localizations.notifOptActivity,
      localizations.notifOptAll,
    ];

    final _themeDropdownItems = ThemeMode.values
      .map((option) => DropdownMenuItem(
          value: option.index,
          child: Text(
            themeLabels[option.index],
            overflow: TextOverflow.ellipsis
          ),
        ),
      ).toList();

    final _notifDropdownItems = NotificationSettings.values
      .map((option) => DropdownMenuItem(
          value: option.index,
          child: Text(
            notifLabels[option.index],
            overflow: TextOverflow.ellipsis
          ),
        ),
      ).toList();

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
              title: Text(localizations.theme),
              trailing: SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: DropdownButtonFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
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
          
          FutureBuilder<UserProfile?>(
            future: Provider.of<ProfileProvider>(context).profile,
            builder: (context, snapshot) {

              final userAccountId = snapshot.data?.userAccountID ?? ""; 

              return Tooltip(
                //TODO: Agregar i18n.
                message: userAccountId.isNotEmpty 
                  ? "Envía datos estadísticos semanalmente"
                  : "Necesitas una cuenta de usuario para aportar datos",
                child: Padding(
                  padding: const EdgeInsets.symmetric( vertical: 16.0, ),
                  child: SwitchListTile(
                    secondary: const Icon(
                      Icons.bar_chart, 
                      size: 24.0, 
                    ),
                    title: Text(localizations.contributeData),
                    
                    value: _shouldContributeData,
                    onChanged: userAccountId.isNotEmpty
                    ? (bool value) {
                        setState(() {
                          _shouldContributeData = value;
                          _userAccountId = userAccountId;
                          compareChanges(context);
                        });
                      }
                    : null,
                  ),
                ),
              );
            }
          ),
    
          const Divider( height: 1.0, ),
          Padding(
            padding: const EdgeInsets.symmetric( vertical: 16.0, ),
            child: ListTile(
              leading: const Icon(
                Icons.notifications, 
                size: 24.0,
              ),
              title: Text(localizations.notifications),
              trailing: SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: DropdownButtonFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedNotifications.index,
                  items: _notifDropdownItems,
                  isExpanded: true,
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
              title: Text(localizations.weeklyForms),
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
            title: Text(localizations.sendComments),
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
            title: Text(localizations.userGuides),
            trailing: const Icon(
              Icons.arrow_forward,
              size: 24.0,
            ),
            onTap: () => UrlLauncher.launchUrlInBrowser(API.uriFor('guias')),
          ),
    
          Padding(
            padding: const EdgeInsets.symmetric( horizontal: 24.0, vertical: 8.0,),
            child: Text(
              '${localizations.version}: ${widget.settingsProvider.versionName}',
              style: const TextStyle(color: Colors.grey),
            ),
          )
        ],
      ),
    );
  }
}