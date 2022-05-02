import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/db/where_clause.dart';
import 'package:hydrate_app/src/models/habits.dart';

class ActivityTimeBrief extends StatefulWidget {

  final int userProfileId;
  
  const ActivityTimeBrief(this.userProfileId, { Key? key }) : super(key: key);

  @override
  State<ActivityTimeBrief> createState() => _ActivityTimeBriefState();
}

class _ActivityTimeBriefState extends State<ActivityTimeBrief> {

  Habits? userHabits;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    _getMostRecentHabits();
  }

  void _getMostRecentHabits() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final results = await SQLiteDB.instance.select<Habits>(
        Habits.fromMap, 
        Habits.tableName, 
        where: [ WhereClause('id_perfil', widget.userProfileId.toString()) ],
        orderByColumn: 'fecha',
        orderByAsc: false,
        limit: 1
      );

      if (results.isNotEmpty) {
        userHabits = results.first;
      }

    } on Exception catch (e) {
      print('Error obteniendo tiempos de actividades: $e');
    
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          AppLocalizations.of(context)!.hoursOfActivity,
          style: Theme.of(context).textTheme.subtitle1,
        ),

        const SizedBox(height: 8.0,),

        Row(
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
                  (isLoading || userHabits == null) ? '-' : '${userHabits?.hoursOfSleep} h',
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
                  (isLoading || userHabits == null) ? '-' : '${userHabits?.hoursOfOccupation} h',
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
                  (isLoading || userHabits == null) ? '-' : '${userHabits?.hoursOfActivity} h',
                  style: Theme.of(context).textTheme.headline6
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
