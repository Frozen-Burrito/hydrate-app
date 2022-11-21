import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/models/activity_record.dart';
import 'package:hydrate_app/src/models/activity_type.dart';
import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/services/activity_service.dart';
import 'package:hydrate_app/src/services/google_fit_service.dart';
import 'package:hydrate_app/src/services/profile_service.dart';

class SyncGoogleFitButton extends StatelessWidget {

  const SyncGoogleFitButton({
    this.tooltip = "Sync Google Fit",
    this.shouldPersistGoogleFitData = false,
    Key? key,
  }) : super(key: key);

  final String tooltip;

  final bool shouldPersistGoogleFitData;

  Future<bool> _syncProfileWithGoogleFit({
    DateTime? latestSyncWithGoogleFit,
    Map<int, ActivityType> supportedActivityTypes = const {},
    required Future Function(Iterable<ActivityRecord>) persistActivityRecords,
    required Future<bool> Function() updateDateOfLatestSyncWithGoogleFit,
  }) async {

    final fetchedActivityRecords = await GoogleFitService.instance.syncActivitySessions(
      startTime: latestSyncWithGoogleFit,
      endTime: DateTime.now(),
      supportedGoogleFitActTypes: supportedActivityTypes,
    );

    updateDateOfLatestSyncWithGoogleFit();

    final persistenceResults = await persistActivityRecords(fetchedActivityRecords);
    final wereAllActivityRecordsSaved = persistenceResults.length == fetchedActivityRecords.length;

    return fetchedActivityRecords.isNotEmpty && wereAllActivityRecordsSaved;
  }

  Future<void> _manuallySyncGoogleFit(
    BuildContext context, 
    Future<bool> Function() updateDateOfLatestSyncWithGoogleFit,
    DateTime? latestSyncWithGoogleFit
  ) async {

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final activityService = Provider.of<ActivityService>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;

    final activityTypes = (await activityService.activityTypes) ?? const <ActivityType>[];

    final syncedNewData = await _syncProfileWithGoogleFit(
      latestSyncWithGoogleFit: latestSyncWithGoogleFit,
      supportedActivityTypes: Map.fromEntries(activityTypes.map((activityType) => MapEntry(activityType.googleFitActivityType, activityType))),
      persistActivityRecords: activityService.saveActivityRecords,
      updateDateOfLatestSyncWithGoogleFit: updateDateOfLatestSyncWithGoogleFit,
    );
                      
    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(SnackBar(
      content: Text(syncedNewData 
        ? localizations.googleFitUpdated
        : localizations.googleFitAlreadyUpToDate
      ),
      duration: const Duration( seconds: 2 ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Consumer<ProfileService>(
        builder: (context, profileService, _) {
          return FutureBuilder<UserProfile?>(
            future: profileService.profile,
            builder: (context, snapshot) {

              final profile = snapshot.data;

              return IconButton(
                onPressed: snapshot.hasData 
                  ? () => _manuallySyncGoogleFit(
                    context, 
                    profileService.updateGoogleFitSyncDate, 
                    profile!.latestSyncWithGoogleFit
                  ) 
                  : null, 
                icon: const Icon(Icons.sync_alt),
              );
            }
          );
        }
      ),
    );
  }
}