import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/api/api_client.dart';
import 'package:hydrate_app/src/bloc/edit_settings_bloc.dart';
import 'package:hydrate_app/src/models/enums/notification_source.dart';
import 'package:hydrate_app/src/models/settings.dart';
import 'package:hydrate_app/src/services/google_fit_service.dart';
import 'package:hydrate_app/src/services/profile_service.dart';
import 'package:hydrate_app/src/services/settings_service.dart';
import 'package:hydrate_app/src/widgets/dialogs/notification_select_dialog.dart';
import 'package:hydrate_app/src/widgets/sync_google_fit_button.dart';
import 'package:hydrate_app/src/widgets/url_list_tile.dart';

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

  int _getEnabledNotificationSourcesCount(Set<NotificationSource> enabledSources) {
    if (enabledSources.contains(NotificationSource.disabled)) {
      assert(enabledSources.length == 1);

      return 0;
    } else if (enabledSources.contains(NotificationSource.all)) {
      return NotificationSource.values.length - 2;
    } else {
      return enabledSources.length;
    }
  }

  void _onGoogleFitIntegratedChanged(bool value) {
    _editSettings.isGoogleFitIntegratedSink.add(value);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final themeLabels = [
      localizations.themeOptSys,
      localizations.themeOptLight,
      localizations.themeOptDark,
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

    return ListTileTheme(
      iconColor: Theme.of(context).colorScheme.onBackground,
      textColor: Theme.of(context).colorScheme.onBackground,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        shrinkWrap: true,
        children: <Widget> [
          const SizedBox( height: 24.0, ),
    
          const Divider( height: 1.0, ),
          ListTile(
            leading: const Icon(
              Icons.colorize, 
              size: 24.0, 
            ),
            title: Text(localizations.theme),
            contentPadding: const EdgeInsets.all( 16.0, ),
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

          const Divider( height: 1.0, ),
          
          Consumer<ProfileService>(
            builder: (context, profileService, _) {
              return Tooltip(
                message: profileService.isAuthenticated
                  ? localizations.contributeDataTooltipSignedIn
                  : localizations.contributeDataTooltipSignedOut,
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
                      contentPadding: const EdgeInsets.all( 16.0, ),
                      value: isSharingData,
                      onChanged: profileService.isAuthenticated && snapshot.hasData
                      ? (bool value) {
                        _editSettings.shouldContributeDataSink.add(value);
                      }
                      : null,
                    );
                  }
                ),
              );
            }
          ),
    
          const Divider( height: 1.0, ),
          ListTile(
            leading: const Icon(
              Icons.notifications, 
              size: 24.0,
            ),
            title: Text(localizations.notifications),
            contentPadding: const EdgeInsets.all( 16.0, ),
            trailing: StreamBuilder<Set<NotificationSource>>(
              stream: _editSettings.enabledNotificationSources,
              initialData: currentSettings.notificationPreferences,
              builder: (context, snapshot) {

                final int enabledCount = snapshot.hasData 
                  ? _getEnabledNotificationSourcesCount(snapshot.data!)
                  : 0;

                return SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: OutlinedButton(
                    onPressed: snapshot.hasData 
                      ? () async {
                        final enabledNotifSources = await showDialog<Set<NotificationSource>>(
                          context: context, 
                          builder: (_) => NotificationSelectDialog(
                            enabledNotificationSources: snapshot.data!,
                          ),
                        );

                        if (enabledNotifSources != null) {
                          _editSettings.notificationSourcesSink.add(enabledNotifSources);
                        }
                      }
                      : null, 
                    child: Text("$enabledCount ${localizations.notifCountActive}"),
                  ),
                );
              }
            ),
          ),

          const Divider( height: 1.0, ),
          StreamBuilder<bool>(
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
                contentPadding: const EdgeInsets.all( 16.0, ),
                value: areWeeklyFormsEnabled,
                onChanged: (bool value) {
                  _editSettings.areWeeklyFormsEnabledSink.add(value);
                },
              );
            }
          ),

          const Divider( height: 1.0, ),
          StreamBuilder<bool>(
            stream: _editSettings.isGoogleFitIntegrated,
            initialData: currentSettings.isGoogleFitIntegrated,
            builder: (context, snapshot) {

              final isGoogleFitIntegrationEnabled = snapshot.data ?? false;

              return Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric( vertical: 16.0, horizontal: 16.0 ),
                  leading: const Icon(
                    Icons.fitness_center, 
                    size: 24.0, 
                  ),
                  title: Text(localizations.integrateHealthApps),
                  textColor: Theme.of(context).colorScheme.onBackground,
                  subtitle: Text(localizations.integrateGoogleFit),
                  initiallyExpanded: isGoogleFitIntegrationEnabled,
                  maintainState: true,
                  onExpansionChanged: _onGoogleFitIntegratedChanged,
                  trailing: IgnorePointer(
                    child: Switch(
                      value: isGoogleFitIntegrationEnabled, 
                      onChanged: (_) {},
                    ),
                  ),
                  childrenPadding: const EdgeInsets.symmetric( 
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
              
                        (GoogleFitService.instance.isSignedInWithGoogle
                        ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Chip(
                              avatar: CircleAvatar(
                                foregroundImage: NetworkImage(
                                  GoogleFitService.instance.googleAccountPhotoUrl ?? "",
                                ),
                                child: Text(
                                  GoogleFitService.instance.googleAccountInitials,
                                ),
                              ),
                              label: Text(
                                GoogleFitService.instance.googleAccountDisplayName ?? 
                                GoogleFitService.instance.googleAccountEmail,
                              ),
                            ),
              
                            const SizedBox( width: 8.0, ),
              
                            Tooltip(
                              message: localizations.signOutWithGoogle,
                              child: IconButton(
                                onPressed: () {
                                  GoogleFitService.instance.signOut();
                                }, 
                                icon: const Icon(Icons.logout),
                              ),
                            ),
                          ],
                        )
                        : TextButton(
                            onPressed: () {
                              GoogleFitService.instance.signInWithGoogle();
                            },
                            child: Text(localizations.signInWithGoogle), 
                          )
                        ),
              
                        SyncGoogleFitButton(
                          tooltip: localizations.fetchGoogleFit,
                          shouldPersistGoogleFitData: true,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }
          ),

          const Divider( height: 1.0, ),
          UrlListTile(
            title: localizations.sendComments, 
            leadingIcon: Icons.question_answer,
            uriToLaunch: ApiClient.urlForPage("comentarios"),
          ),
    
          const Divider( height: 1.0, ),
          UrlListTile(
            title: localizations.userGuides, 
            leadingIcon: Icons.lightbulb,
            uriToLaunch: ApiClient.urlForPage("guias"),
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
