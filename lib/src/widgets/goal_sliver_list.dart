import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hydrate_app/src/services/goals_service.dart';
import 'package:hydrate_app/src/services/hydration_record_service.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/models/goal.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/utils/datetime_extensions.dart';
import 'package:hydrate_app/src/widgets/data_placeholder.dart';
import 'package:hydrate_app/src/widgets/shapes.dart';

class GoalSliverList extends StatelessWidget {

  const GoalSliverList({
    Key? key,
    required this.hydrationGoalSource,
    this.showPlaceholderWhenEmpty = true,
    this.showLoadingIndicator = true,
  }) : super(key: key);

  final Future<List<Goal>> hydrationGoalSource;

  final bool showPlaceholderWhenEmpty;

  final bool showLoadingIndicator;

  @override
  Widget build(BuildContext context) {

    return SliverPadding(
      padding: const EdgeInsets.all(8.0),
      sliver: FutureBuilder<List<Goal>?>(
        future: hydrationGoalSource,
        builder: (context, snapshot) {
          
          if (snapshot.hasData) {

            final hydrationGoals = snapshot.data ?? const <Goal>[];

            if (hydrationGoals.isNotEmpty) {
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int i) {
                    return _GoalCard(
                      goal: hydrationGoals[i],
                    );
                  },
                  childCount: hydrationGoals.length,
                ),
              );
            } else if (showPlaceholderWhenEmpty) {
              // Retornar un placeholder si los datos están cargando, o no hay datos aín.
              //TODO: Agregar i18n.
              return SliverToBoxAdapter(
                child: DataPlaceholder(
                  message: "Aún no has creado metas de hidratación.",
                  icon: Icons.flag,
                  hasTopSpacing: false,
                  action: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, RouteNames.newHydrationGoal), 
                    child: const Text("Crea una meta"),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blue,
                    ),
                  ),
                ),
              );  
            }
          } else if (snapshot.hasError) {
            // Retornar un placeholder, indicando que hubo un error.
            print(snapshot.error);
            return const SliverToBoxAdapter(
              child: DataPlaceholder(
                isLoading: false,
                //TODO: agregar i18n
                message: "Hubo un error obteniendo tus metas de hidratación.",
                icon: Icons.error,
                hasTopSpacing: false,
              ),
            ); 
          } else if (showLoadingIndicator) {
            // El future no tiene datos ni error, aún no ha sido
            // completado.
            return const SliverToBoxAdapter(
              child: DataPlaceholder(
                isLoading: true,
                hasTopSpacing: false,
              ),
            );  
          }

          return const SliverToBoxAdapter(
            child: SizedBox( height: 0.0, width: 0.0 )
          );
        },
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {

  const _GoalCard({ required this.goal, Key? key }) : super(key: key);

  final Goal goal;

  //TODO: Agregar i18n para plazos de tiempo
  static const termLabels = <String>['Diario','Semanal','Mensual'];
  
  //TODO: Agregar i18n para rangos de fechas en metas
  String _buildDateLabel(DateTime? start, DateTime? end) {

    final strBuf = StringBuffer();

    if (start != null) {
      strBuf.writeAll([ "Desde ", start.toLocalizedDate]);
    }

    if (end != null) {
      strBuf.writeAll([ " hasta ", end.toLocalizedDate]);
    }

    return strBuf.toString();
  }

  @override
  Widget build(BuildContext context) {

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
                  child: Consumer<GoalsService>(
                    builder: (_, provider, __) {
                      return IconButton(
                        icon: Icon( goal.isMainGoal ? Icons.flag : Icons.flag_outlined ), 
                        onPressed: () => provider.setMainGoal(goal.id),
                      );
                    }
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
              _buildDateLabel(goal.startDate, goal.endDate), 
              style: Theme.of(context).textTheme.bodyText1,
              textAlign: TextAlign.left
            ),

            _GoalProgressBar(goal: goal),
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
            //TODO: agregar i18n
            "Tu Meta Principal", 
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

class _GoalProgressBar extends StatelessWidget {

  const _GoalProgressBar({
    Key? key,
    required this.goal,
  }) : super(key: key);

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    return Consumer<HydrationRecordService>(
      builder: (_, hydrationProvider, __) {
        return FutureBuilder<int>(
          future: hydrationProvider.getGoalProgressInMl(goal),
          initialData: 0,
          builder: (context, snapshot) {
            
            final goalQuantityMl = min(max(goal.quantity, Goal.waterQuantityMlRange.min), Goal.waterQuantityMlRange.max);
            final progressInMl = max(min(snapshot.data!, goalQuantityMl), 0);

            final adjustedProgress = progressInMl / goalQuantityMl.toDouble();
            final isGoalComplete = progressInMl >= goalQuantityMl;

            return Container(
              margin: const EdgeInsets.only( top: 16.0 ),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: adjustedProgress,
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
            );
          }
        );
      }
    );
  }
}