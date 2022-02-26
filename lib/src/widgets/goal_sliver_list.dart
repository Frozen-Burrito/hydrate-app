import 'package:flutter/material.dart';
import 'package:hydrate_app/src/db/sqlite_db.dart';

import 'package:hydrate_app/src/models/goal.dart';

class GoalSliverList extends StatefulWidget {
  const GoalSliverList({ Key? key }) : super(key: key);

  @override
  State<GoalSliverList> createState() => _GoalSliverListState();
}

class _GoalSliverListState extends State<GoalSliverList> {

  List<Goal> userGoals = [];
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

    final goals = await SQLiteDB.db.select<Goal>(Goal.fromMap, 'meta');

    if (mounted) {
      setState(() {
        userGoals = goals.toList();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(8.0),
      sliver: isLoading 
        ? const SliverToBoxAdapter(child: Text('Cargando metas del usuario...'))
        : SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int i) {
              return _GoalCard(goal: userGoals[i],);
            },
            childCount: userGoals.length,
          ),
        ),
    );
  }
}

class _GoalCard extends StatelessWidget {

  final Goal goal;

  //TODO: Agregar traducciones reales, centralizadas.
  static const termLabels = <String>['Diario','Semanal','Mensual'];

  const _GoalCard({ required this.goal, Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(goal.notes ?? 'Meta'),
            subtitle: Text(termLabels[goal.term.index]),
            trailing: Column(
              children: <Widget> [
                Text('${goal.quantity.toString()}ml'),
                Text(goal.reward.toString()),
              ],
            )
          ),

          Padding(
            padding: const EdgeInsets.only( left: 16.0, right: 16.0, bottom: 16.0),
            child: Text(
              '${goal.startDate.toString()} hasta ${goal.endDate.toString()}', 
              textAlign: TextAlign.start
            ),
          ),
        ],
      ),
    );
  }
}