import 'package:flutter/material.dart';
import 'package:hydrate_app/src/models/routine_occurrence.dart';
import 'package:hydrate_app/src/utils/activities_with_routines.dart';
import 'package:hydrate_app/src/utils/datetime_extensions.dart';
import 'package:hydrate_app/src/utils/dropdown_labels.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/provider/activity_provider.dart';
import 'package:hydrate_app/src/widgets/data_placeholder.dart';
import 'package:hydrate_app/src/widgets/week_totals_chart.dart';

class ActivitySliverList extends StatelessWidget {
  const ActivitySliverList({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Builder(
        builder: (context) {
          return Consumer<ActivityProvider>(
            builder: (_, provider, __) {
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: <Widget> [
                  SliverOverlapInjector(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  ),

                  SliverToBoxAdapter(
                    child: WeekTotalsChart(
                      dailyTotals: provider.prevWeekKcalTotals,
                      yUnit: 'kCal',
                      maxYValue: 3000.0,
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.all(8.0),
                    sliver: FutureBuilder(
                      future: provider.routineActivities,
                      builder: (context, AsyncSnapshot<RoutineActivities> snapshot) {
                        // Revisar si hay datos en el snapshot del future.
                        if (snapshot.hasData ) {

                          final routineActivities = snapshot.data;

                          final activityCount = routineActivities?.activitiesWithRoutines.length ?? 0;
                          final activites = routineActivities != null
                            ? routineActivities.activitiesWithRoutines
                            : List<RoutineOccurrence>.empty();

                          if (activites.isNotEmpty) {
                            
                            // Si hay datos y la lista de actividades no esta vacia, 
                            // mostrar los registros de actividad.
                            return SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (BuildContext context, int i) {
                                  return _ActivityCard(
                                    activityRecord: activites[i],
                                  );
                                },
                                childCount: activityCount
                              ),
                            );
                          } else {
                            // Retornar un placeholder si los datos están cargando, o no hay datos aín.
                            return const SliverToBoxAdapter(
                              child: DataPlaceholder(
                                //TODO: agregar i18n
                                message: 'Aún no hay actividad física registrada.',
                                icon: Icons.fact_check_rounded,
                              ),
                            );  
                          }
                        } else if (snapshot.hasError) {
                          // Retornar un placeholder, indicando que hubo un error.
                          return const SliverToBoxAdapter(
                            child: DataPlaceholder(
                              isLoading: false,
                              //TODO: agregar i18n
                              message: 'Hubo un error obteniendo tus registros de actividad.',
                              icon: Icons.error,
                            ),
                          ); 
                        }

                        // El future no tiene datos ni error, aún no ha sido
                        // completado.
                        return const SliverToBoxAdapter(
                          child: DataPlaceholder(
                            isLoading: true,
                          ),
                        );  
                      }
                    ),
                  ),
                ],
              );
            }
          );
        }
      ),
    ); 
  }
}

class _ActivityCard extends StatelessWidget {

  final RoutineOccurrence activityRecord;

  const _ActivityCard({ 
    required this.activityRecord, 
    Key? key 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final activity = activityRecord.activity;
    
    final activityTypeLabel = DropdownLabels.activityLabels(context)[activity.activityType.id];

    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all( 16.0 ),
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
                    activity.title,
                    style: Theme.of(context).textTheme.headline6,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),                

                SizedBox( 
                  width: MediaQuery.of(context).size.width * 0.14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.max,
                    children: [

                      (activity.isRoutine && activityRecord.routine != null)
                      ? Container(
                          width: 24.0,
                          margin: const EdgeInsets.only(right: 4.0),
                          child: const Icon(
                            Icons.alarm, 
                            color: Colors.blue,
                            size: 22.0,
                          ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.shade300.withOpacity(0.3),
                          ),
                        )
                      : const SizedBox(),

                      (activity.isIntense)
                      ? Container(
                          width: 24.0,
                          child: const Icon(
                            Icons.directions_walk, 
                            color: Colors.yellow,
                            size: 22.0,
                          ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.yellow[300]?.withOpacity(0.3),
                          ),
                        )
                      : const SizedBox(),
                    ],
                  )
                ),
              ],
            ),


            const SizedBox( height: 8.0 ),

            Text(
              activityRecord.date.toLocalizedDateTime,
              style: Theme.of(context).textTheme.bodyText2?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.start,
            ),

            const SizedBox( height: 8.0 ),

            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(activityTypeLabel.icon),

                const SizedBox( width: 8.0 ),

                Text(
                  activityTypeLabel.label,
                  style: Theme.of(context).textTheme.bodyText2,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),

            const SizedBox( height: 16.0 ),

            IconTheme(
              data: Theme.of(context).iconTheme.copyWith(
                size: 24.0,
                color: Theme.of(context).colorScheme.onSurface
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  _ActivityCardStatIcon(
                    statLabel: activity.formattedDistance,
                    icon: Icons.directions_run
                  ),
                  _ActivityCardStatIcon(
                    statLabel: activity.formattedDuration,
                    icon: Icons.schedule
                  ),
                  _ActivityCardStatIcon(
                    statLabel: activity.formattedKcal,
                    icon: Icons.bolt
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ActivityCardStatIcon extends StatelessWidget {

  final String statLabel;
  final IconData icon;

  const _ActivityCardStatIcon({ 
    required this.statLabel,
    required this.icon,
    Key? key 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(icon),

          const SizedBox( width: 4.0,),

          Text(
            statLabel,
            style: Theme.of(context).textTheme.bodyText1?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14.0
            )
          ),
        ],
      ) 
    );
  }
}