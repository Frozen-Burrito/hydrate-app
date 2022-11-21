import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/models/enums/notification_source.dart';

class NotificationSelectDialog extends StatefulWidget {

  NotificationSelectDialog({
    Key? key,
    required Set<NotificationSource> enabledNotificationSources,
  }) : currentNotificationSources = UnmodifiableSetView(enabledNotificationSources),
       super(key: key);

  final Set<NotificationSource> currentNotificationSources;

  @override
  State<NotificationSelectDialog> createState() => _NotificationSelectDialogState();
}

class _NotificationSelectDialogState extends State<NotificationSelectDialog> {

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
      localizations.notifyRest,
      localizations.notifOptAll,
    ];

    return AlertDialog(
      title: Text(localizations.notifications),
      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(localizations.setupNotifyDetails),

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
          child: Text(localizations.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, changedNotificationSources), 
          child: Text(localizations.confirmAction),
        ),
      ],
    );
  }
}