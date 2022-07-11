import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/db/where_clause.dart';
import 'package:hydrate_app/src/models/habits.dart';
import 'package:hydrate_app/src/provider/goals_provider.dart';
import 'package:provider/provider.dart';

class ActivityTimeBrief extends StatelessWidget {

  const ActivityTimeBrief({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final progressProvider = Provider.of<GoalProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          AppLocalizations.of(context)!.hoursOfActivity,
          style: Theme.of(context).textTheme.subtitle1,
        ),

        const SizedBox(height: 8.0,),

        FutureBuilder<Habits?>(
          future: progressProvider.lastPeriodicReport,
          builder: (context, snapshot) {

            final lastReport = snapshot.data;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.nightlight,
                      size: 32.0,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),

                    Text(
                      (lastReport != null) ? '${lastReport.hoursOfSleep} h' : '-',
                      style: Theme.of(context).textTheme.headline6
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.work,
                      size: 32.0,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),

                    Text(
                      (lastReport != null) ? '${lastReport.hoursOfOccupation} h' : '-',
                      style: Theme.of(context).textTheme.headline6
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.directions_run,
                      size: 32.0,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),

                    Text(
                      (lastReport != null) ? '${lastReport.hoursOfActivity} h' : '-',
                      style: Theme.of(context).textTheme.headline6
                    ),
                  ],
                ),
              ],
            );
          }
        ),
      ],
    );
  }
}
