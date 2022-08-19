import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/models/goal.dart';
import 'package:hydrate_app/src/provider/goals_provider.dart';
import 'package:hydrate_app/src/provider/hydration_record_provider.dart';
import 'package:hydrate_app/src/provider/profile_provider.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/utils/datetime_extensions.dart';
import 'package:hydrate_app/src/widgets/data_placeholder.dart';
import 'package:hydrate_app/src/widgets/shapes.dart';

class GoalSliverList extends StatelessWidget {

  const GoalSliverList({Key? key}) : super(key: key);

  Future<Map<Goal, int>> getGoalsWithProgress(
    BuildContext context, 
    int profileId,
    Future<Map<Goal, int>> Function(List<Goal>) getProgressValuesForGoals
  ) async {

    final goalsProvider = Provider.of<GoalProvider>(context, listen: false);

    goalsProvider.activeProfileId = profileId;

    final goals = await goalsProvider.goals ?? <Goal>[];

    if (goals.isNotEmpty) {
      // Ordenar metas para que la meta principal sea la primera.
      final mainGoalIdx = goals.indexWhere((goal) => goal.isMainGoal);
      final mainGoal = goals.removeAt(mainGoalIdx);

      goals.insert(0, mainGoal);

      // Obtener los progresos hacia las metas de hidratación.
      final progressTowardsGoals = await getProgressValuesForGoals(goals);

      assert(progressTowardsGoals.length == goals.length);

      return progressTowardsGoals;
    }

    return <Goal, int>{};
  }

  @override
  Widget build(BuildContext context) {

    final hydrationProvider = Provider.of<HydrationRecordProvider>(context);
    final profileId = Provider.of<ProfileProvider>(context).profileId;
    
    return SliverPadding(
      padding: const EdgeInsets.all(8.0),
      sliver: FutureBuilder<Map<Goal, int>>(
        future: getGoalsWithProgress(
          context, 
          profileId,
          hydrationProvider.getGoalsProgressValuesInMl,
        ),
        builder: (context, snapshot) {
          
          if (snapshot.hasData) {

            final goals = snapshot.data;

            if (goals != null && goals.isNotEmpty) {

              final goalList = goals.entries.toList();

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int i) {
                    return _GoalCard(
                      goal: goalList[i].key,
                      progress: goalList[i].value,
                    );
                  },
                  childCount: goals.length,
                ),
              );
            } else {
              // Retornar un placeholder si los datos están cargando, o no hay datos aín.
              //TODO: Agregar i18n.
              return SliverDataPlaceholder(
                message: 'Aún no has creado metas de hidratación.',
                icon: Icons.flag,
                hasTopSpacing: false,
                action: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, RouteNames.newHydrationGoal), 
                  child: const Text('Crea una meta'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue,
                  ),
                ),
              );  
            }

          } else if (snapshot.hasError) {

            print(snapshot.error);
            // Retornar un placeholder, indicando que hubo un error.
            return const SliverDataPlaceholder(
              isLoading: false,
              message: 'Hubo un error obteniendo tus metas de hidratación.',
              icon: Icons.error,
              hasTopSpacing: false,
            ); 
          } else {
            // El future no tiene datos ni error, aún no ha sido
            // completado.
            return const SliverDataPlaceholder(
              isLoading: true,
              hasTopSpacing: false,
            );  
          }
        },
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {

  final Goal goal;
  final int progress;

  //TODO: Agregar traducciones reales, centralizadas.
  static const termLabels = <String>['Diario','Semanal','Mensual'];

  const _GoalCard({ 
    required this.goal, 
    required this.progress,
    Key? key 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final setMainGoal = Provider.of<GoalProvider>(context).setMainGoal;

    final currentProgress = max(min(progress, goal.quantity), 0.0);
    final isGoalComplete = (currentProgress >= goal.quantity);

    final startDateStr = goal.startDate != null 
      ? 'Desde ${goal.startDate?.toLocalizedDate}'
      : '';

    final endDateStr = goal.endDate != null 
      ? 'hasta ${goal.endDate?.toLocalizedDate}'
      : '';

    final mainCard = Card(
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
                  width: MediaQuery.of(context).size.width * 0.075,
                  child: IconButton(
                    icon: Icon( goal.isMainGoal ? Icons.flag : Icons.flag_outlined ), 
                    onPressed: () => setMainGoal(goal.id),
                  )
                ),

                const SizedBox( width: 8.0 ),

                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Text(
                    goal.notes ?? 'Meta', 
                    style: Theme.of(context).textTheme.headline6,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox( width: 4.0 ),

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
              '$startDateStr $endDateStr', 
              style: Theme.of(context).textTheme.bodyText1,
              textAlign: TextAlign.left
            ),

            Container(
              margin: const EdgeInsets.only( top: 16.0 ),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: currentProgress / goal.quantity.toDouble(),
                    ),
                  ),

                  (isGoalComplete) 
                  ? Container(
                      margin: const EdgeInsets.only( left: 8.0 ),
                      child: Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : const SizedBox( width: 0, ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final columnItems = <Widget>[];

    if (goal.isMainGoal) {
      columnItems.add(
        Container(
          width: double.maxFinite,
          margin: const EdgeInsets.only( bottom: 8.0, left: 8.0 ),
          child: Text(
            'Tu Meta Principal', 
            style: Theme.of(context).textTheme.headline5,
          )
        ),
      );
    }

    columnItems.add(mainCard);

    if (goal.isMainGoal) {
      columnItems.add(
        const Divider( thickness: 1.0, height: 24.0, ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: columnItems,
    );
  }
}