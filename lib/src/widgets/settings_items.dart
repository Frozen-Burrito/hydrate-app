import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hydrate_app/src/services/google_fit_service.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/bloc/edit_settings_bloc.dart';
import 'package:hydrate_app/src/models/api.dart';
import 'package:hydrate_app/src/models/enums/notification_source.dart';
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
          
          FutureBuilder<UserProfile?>(
            future: Provider.of<ProfileService>(context).profile,
            builder: (context, snapshot) {

              final userAccountId = snapshot.data?.userAccountID ?? ""; 

              return Tooltip(
                //TODO: Agregar i18n.
                message: userAccountId.isNotEmpty 
                  ? "Envía datos estadísticos semanalmente"
                  : "Necesitas una cuenta de usuario para aportar datos",
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
                      onChanged: userAccountId.isNotEmpty && snapshot.hasData
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
                          builder: (_) => _NotificationSelectDialog(
                            enabledNotificationSources: snapshot.data!,
                          ),
                        );

                        if (enabledNotifSources != null) {
                          _editSettings.notificationSourcesSink.add(enabledNotifSources);
                        }
                      }
                      : null, 
                    child: Text("$enabledCount activadas"),
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
                  //TODO: agregar i18n.
                  title: Text("Conectar apps de salud"),
                  textColor: Theme.of(context).colorScheme.onBackground,
                  subtitle: Text("Integra Hydrate con Google Fit"),
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
                              message: "Cerrar sesión de la cuenta de Google",
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
                            //TODO: agregar i18n.
                            child: const Text("Inicia Sesión con Google"), 
                          )
                        ),
              
                        Tooltip(
                          message: "Actualizar datos de Google Fit",
                          child: IconButton(
                            onPressed: () async {
                              // Actualizar los datos de Google Fit manualmente.
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              await GoogleFitService.instance.syncActivitySessions();
                                                
                              scaffoldMessenger.clearSnackBars();
                              scaffoldMessenger.showSnackBar(const SnackBar(
                                content: Text("Google Fit sincronizado"),
                                duration: Duration( seconds: 2 ),
                              ));
                            }, 
                            icon: const Icon(Icons.sync_alt),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }
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
      contentPadding: const EdgeInsets.all( 16.0, ),
      trailing: const Icon(
        Icons.arrow_forward,
        size: 24.0,
      ),
      onTap: () => UrlLauncher.launchUrlInBrowser(uriToLaunch),
    );
  }
}

class _NotificationSelectDialog extends StatefulWidget {

  _NotificationSelectDialog({
    Key? key,
    required Set<NotificationSource> enabledNotificationSources,
  }) : currentNotificationSources = UnmodifiableSetView(enabledNotificationSources),
       super(key: key);

  final Set<NotificationSource> currentNotificationSources;

  @override
  State<_NotificationSelectDialog> createState() => _NotificationSelectDialogState();
}

class _NotificationSelectDialogState extends State<_NotificationSelectDialog> {

  late final Set<NotificationSource> changedNotificationSources = Set.of(widget.currentNotificationSources);

  bool _isNotificationSourceEnabled(NotificationSource notificationSource,) {
    return changedNotificationSources.contains(notificationSource);
  }

  void _toggleNotificationSource(NotificationSource notificationSource, bool isEnabled) {
    // Determinar si la fuente de notificaciones fue activada o desactivada.
    if (isEnabled) {
      if (notificationSource == NotificationSource.disabled) {
        changedNotificationSources.clear();
        changedNotificationSources.add(NotificationSource.disabled);

      } else if (notificationSource == NotificationSource.all) {
        changedNotificationSources.remove(NotificationSource.disabled);
        changedNotificationSources.addAll([
          NotificationSource.goals,
          NotificationSource.battery,
          NotificationSource.activity,
          NotificationSource.rest,
          NotificationSource.all,
        ]);
      } else {
        changedNotificationSources.remove(NotificationSource.disabled);
        changedNotificationSources.add(notificationSource);

        if (changedNotificationSources.length == NotificationSource.values.length - 2) {
          changedNotificationSources.add(NotificationSource.all);
        }
      }
    } else {
      if (notificationSource != NotificationSource.all) {
        changedNotificationSources.remove(NotificationSource.all);
      }

      changedNotificationSources.remove(notificationSource);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;
    
    final List<String> notifLabels = [
      localizations.notifOptNone,
      localizations.notifOptGoals,
      localizations.notifOptBattery,
      localizations.notifOptActivity,
      "Descanso",
      localizations.notifOptAll,
    ];

    return AlertDialog(
      title: const Text("Notificaciones"),
      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //TODO: agregar i18n.
            const Text("Selecciona los tipos de notificaciones que deseas recibir:"),

            const SizedBox(height: 8.0,),

            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemBuilder: (context, i) {                
                  return CheckboxListTile(
                    value: _isNotificationSourceEnabled(NotificationSource.values[i],),
                    onChanged: (isEnabled) => _toggleNotificationSource(
                      NotificationSource.values[i], 
                      isEnabled ?? false
                    ),
                    title: Text(notifLabels[i]),
                  );
                },
                itemCount: NotificationSource.values.length,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, null), 
          child: const Text("Cancelar"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, changedNotificationSources), 
          child: const Text("Confirmar"),
        ),
      ],
    );
  }
}
