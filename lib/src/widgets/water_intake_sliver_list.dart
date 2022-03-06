import 'package:flutter/material.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/models/hydration_record.dart';
import 'package:hydrate_app/src/widgets/data_placeholder.dart';

class WaterIntakeSliverList extends StatefulWidget {
  const WaterIntakeSliverList({ Key? key }) : super(key: key);

  @override
  State<WaterIntakeSliverList> createState() => _WaterIntakeSliverListState();
}

class _WaterIntakeSliverListState extends State<WaterIntakeSliverList> {

  List<HydrationRecord> intakeData = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    _getUserGoals();
  }

  void _getUserGoals() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final goals = await SQLiteDB.instance.select<HydrationRecord>(
      HydrationRecord.fromMap, 
      HydrationRecord.tableName, 
      queryManyToMany: true,
      limit: 20,
    );

    if (mounted) {
      setState(() {
        intakeData = goals.toList();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(8.0),
      sliver: Builder(
        builder: (context) {
          String msg = '';
          IconData placeholderIcon = Icons.info;

          if (!isLoading && intakeData.isEmpty) {
            msg = 'Aún no hay registros de hidratación. Toma agua y vuelve más tarde.';
            placeholderIcon = Icons.fact_check_rounded;
          }

          if (isLoading || intakeData.isEmpty) {
            return SliverDataPlaceholder(
              isLoading: isLoading,
              message: msg,
              icon: placeholderIcon,
            );
          } else {
            return SliverPadding(
              padding: const EdgeInsets.all(8.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int i) {
                    return _GoalCard(hydrationRecord: intakeData[i],);
                  },
                  childCount: intakeData.length,
                ),
              ),
            );
          }
        },
      )
    );
  }
}

class _GoalCard extends StatelessWidget {

  final HydrationRecord hydrationRecord;

  const _GoalCard({ required this.hydrationRecord, Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(hydrationRecord.date.toString()),
            subtitle: Text('${hydrationRecord.amount}ml'),
          ),
        ],
      ),
    );
  }
}