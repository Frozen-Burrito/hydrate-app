import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/bloc/edit_settings_bloc.dart';
import 'package:hydrate_app/src/models/api.dart';
import 'package:hydrate_app/src/models/enums/notification_types.dart';
import 'package:hydrate_app/src/models/settings.dart';
import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/services/profile_service.dart';
import 'package:hydrate_app/src/services/settings_service.dart';
import 'package:hydrate_app/src/utils/launch_url.dart';

class SettingsItems extends StatelessWidget {

  SettingsItems({ 
    Key? key, 
    required this.currentSettings,
  }) : _editSettings = EditSettingsBloc(currentSettings), super(key: key);

  final Settings currentSettings;

  final EditSettingsBloc _editSettings;

  void _toggleSaveSnackbar(BuildContext context, bool isSnackbarActive) {
    if (isSnackbarActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.unsavedChanges),
          duration: EditSettingsBloc.savePromptDuration,
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.save, 
            onPressed: () {
              _editSettings.saveChanges(context);
            },
          ),
        )
      );
    } else {
      // Si no hay ya un Snackbar de confirmación de cambios y el usuario 
      // realizó cambios, mostrar el snackbar.
      ScaffoldMessenger.of(context).clearSnackBars();
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

    final _notifDropdownItems = NotificationTypes.values
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
                child: StreamBuilder<ThemeMode>(
                  stream: _editSettings.appThemeMode,
                  initialData: currentSettings.appThemeMode,
                  builder: (context, snapshot) {

                    final currentTheme = snapshot.data ?? ThemeMode.system;

                    return DropdownButtonFormField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      value: currentTheme.index,
                      items: _themeDropdownItems,
                      onChanged: (int? newValue) {
                        final selectedTheme = ThemeMode.values[newValue ?? 0];
                        _editSettings.appThemeModeSink.add(selectedTheme);
                      },
                    );
                  }
                ),
              ),
            ),
          ),
    
          const Divider( height: 1.0, ),
          
          FutureBuilder<UserProfile?>(
            future: Provider.of<ProfileService>(context).profile,
            builder: (context, snapshot) {

              final userAccountId = snapshot.data?.userAccountID ?? ""; 

              return Tooltip(
                //TODO: Agregar i18n.
                message: userAccountId.isNotEmpty 
                  ? "Envía datos estadísticos semanalmente"
                  : "Necesitas una cuenta de usuario para aportar datos",
                child: Padding(
                  padding: const EdgeInsets.symmetric( vertical: 16.0, ),
                  child: StreamBuilder<bool>(
                    stream: _editSettings.shouldContributeData,
                    initialData: currentSettings.shouldContributeData,
                    builder: (context, snapshot) {

                      final isSharingData = snapshot.data ?? false;

                      return SwitchListTile(
                        secondary: const Icon(
                          Icons.bar_chart, 
                          size: 24.0, 
                        ),
                        title: Text(localizations.contributeData),
                        value: isSharingData,
                        onChanged: userAccountId.isNotEmpty && snapshot.hasData
                        ? (bool value) {
                          _editSettings.shouldContributeDataSink.add(value);
                        }
                        : null,
                      );
                    }
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
                child: StreamBuilder<NotificationTypes>(
                  stream: _editSettings.allowedNotifications,
                  initialData: currentSettings.allowedNotifications,
                  builder: (context, snapshot) {

                    final allowedNotifications = snapshot.data ?? NotificationTypes.disabled;

                    return DropdownButtonFormField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      value: allowedNotifications.index,
                      items: _notifDropdownItems,
                      isExpanded: true,
                      onChanged: (int? newValue) {
                        final selectedNotifications = NotificationTypes.values[newValue ?? 0];
                        _editSettings.allowedNotificationsSink.add(selectedNotifications);
                      },
                    );
                  }
                ),
              ),
            ),
          ),

          const Divider( height: 1.0, ),
          Padding(
            padding: const EdgeInsets.symmetric( vertical: 16.0, ),
            child: StreamBuilder<bool>(
              stream: _editSettings.areWeeklyFormsEnabled,
              initialData: currentSettings.areWeeklyFormsEnabled,
              builder: (context, snapshot) {

                final areWeeklyFormsEnabled = snapshot.data ?? false;

                return SwitchListTile(
                  secondary: const Icon(
                    Icons.event_note, 
                    size: 24.0, 
                  ),
                  title: Text(localizations.weeklyForms),
                  value: areWeeklyFormsEnabled,
                  onChanged: (bool value) {
                    _editSettings.areWeeklyFormsEnabledSink.add(value);
                  },
                );
              }
            ),
          ),

          const Divider( height: 1.0, ),
          _UrlListTile(
            title: localizations.sendComments, 
            leadingIcon: Icons.question_answer,
            uriToLaunch: API.uriFor("comentarios"),
          ),
    
          const Divider( height: 1.0, ),
          _UrlListTile(
            title: localizations.userGuides, 
            leadingIcon: Icons.lightbulb,
            uriToLaunch: API.uriFor("guias"),
          ),
    
          Padding(
            padding: const EdgeInsets.symmetric( horizontal: 24.0, vertical: 8.0,),
            child: Consumer<SettingsService>(
              builder: (_, settingsProvider, __) {
                // Mostrar el identificador de la versión actual.
                final versionText = "${localizations.version}: ${SettingsService.versionName}";

                return Text(
                  versionText,
                  style: const TextStyle(color: Colors.grey),
                );
              }
            ),
          ),
        
          StreamBuilder<bool>(
            stream: _editSettings.isSavePromptActive,
            builder: (_, snapshot) {
              
              _editSettings.isSavePromptActive.listen((isPromptActive) {
                _toggleSaveSnackbar(context, isPromptActive);
              });

              return const SizedBox( height: 0.0 );
            }
          ),
        ],
      ),
    );
  }
}

class _UrlListTile extends StatelessWidget {

  const _UrlListTile({ 
    Key? key, 
    required this.title,
    this.leadingIcon = Icons.question_answer,
    required this.uriToLaunch, 
  }) : super(key: key);

  final String title;

  final IconData leadingIcon;

  final Uri uriToLaunch;

  @override
  Widget build(BuildContext context) {

    return ListTile(
      minVerticalPadding: 24.0,
      leading: Icon(
        leadingIcon, 
        size: 24.0, 
      ),
      title: Text(title),
      trailing: const Icon(
        Icons.arrow_forward,
        size: 24.0,
      ),
      onTap: () => UrlLauncher.launchUrlInBrowser(uriToLaunch),
    );
  }
}
