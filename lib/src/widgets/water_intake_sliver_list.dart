import 'package:flutter/material.dart';
import 'package:hydrate_app/src/db/sqlite_db.dart';

import 'package:hydrate_app/src/models/goal.dart';
import 'package:hydrate_app/src/widgets/data_placeholder.dart';

class WaterIntakeSliverList extends StatefulWidget {
  const WaterIntakeSliverList({ Key? key }) : super(key: key);

  @override
  State<WaterIntakeSliverList> createState() => _WaterIntakeSliverListState();
}

class _WaterIntakeSliverListState extends State<WaterIntakeSliverList> {

  //TODO: Crear modelo de registro de hidratacion y usarlo
  List<Goal> intakeData = [];
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

    //TODO: obtener registros de hidratacion.
    final goals = await SQLiteDB.instance.select<Goal>(
      Goal.fromMap, 
      'meta', 
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
                    return _GoalCard(goal: intakeData[i],);
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
            child: Column(
              children: [
                goal.tags.isNotEmpty 
                ? SizedBox(
                  height: 48.0,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: goal.tags.length,
                    itemBuilder: (BuildContext context, int i) {
                      return Container(
                        margin: const EdgeInsets.only( right: 8.0 ),
                        child: Chip(
                          key: Key(goal.tags[i].id.toString()),
                          label: Text(goal.tags[i].value),
                        ),
                      );
                    }
                  ),
                )
                : Container(),
                
                Text(
                  '${goal.startDate.toString()} hasta ${goal.endDate.toString()}', 
                  textAlign: TextAlign.start
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}