import 'package:flutter/material.dart';
import 'package:hydrate_app/src/db/sqlite_db.dart';

import 'package:hydrate_app/src/models/goal.dart';
import 'package:hydrate_app/src/widgets/data_placeholder.dart';
import 'package:hydrate_app/src/widgets/shapes.dart';

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

    final goals = await SQLiteDB.instance.select<Goal>(
      Goal.fromMap,
      Goal.tableName,
      queryManyToMany: true,
      limit: 20,
    );

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
        ? const SliverDataPlaceholder( isLoading: true, )
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: Text(
                    goal.notes ?? 'Meta', 
                    style: Theme.of(context).textTheme.headline6,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox( width: 8.0 ),

                Column(
                  children: <Widget> [
                    Text(
                      '${goal.quantity.toString()}ml',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: CoinShape(radius: 8.0,),
                          ),
                
                          const SizedBox( width: 4.0,),
                
                          Text(
                            goal.reward.toString(),
                            style: Theme.of(context).textTheme.bodyText2,
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              ]
            ),

            const SizedBox( height: 8.0, ),

            Text(
              termLabels[goal.term.index],
              style: Theme.of(context).textTheme.subtitle1?.copyWith(
                color: Theme.of(context).colorScheme.primary
              )
            ),

            ( goal.tags.isNotEmpty)
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
                        label: Text(
                          goal.tags[i].value,
                          style: Theme.of(context).textTheme.bodyText2?.copyWith(
                            fontWeight: FontWeight.w500
                          ),
                        ),
                      ),
                    );
                  }
                ),
              )
            : const SizedBox( width: 0.0,),
              
            Text(
              'Desde ${goal.startDate.toString().substring(0,10)} hasta ${goal.endDate.toString().substring(0,10)}', 
              style: Theme.of(context).textTheme.bodyText1,
              textAlign: TextAlign.left
            ),
          ],
        ),
      ),
    );
  }
}