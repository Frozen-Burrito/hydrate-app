import 'package:flutter/material.dart';
import 'package:hydrate_app/src/utils/dropdown_labels.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/models/activity_record.dart';
import 'package:hydrate_app/src/provider/activity_provider.dart';
import 'package:hydrate_app/src/widgets/data_placeholder.dart';
import 'package:hydrate_app/src/widgets/week_totals_chart.dart';

import '../utils/activities_with_routines.dart';

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
                      isLoading: provider.areActivitiesLoading,
                      dailyTotals: provider.prevWeekKcalTotals,
                      yUnit: 'kCal',
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

                          final activityCount = routineActivities?.length ?? 0;
                          final activites = routineActivities != null
                            ? routineActivities.allActivities.toList()
                            : List<ActivityRecord>.empty();

                          if (activites.isNotEmpty) {
                            
                            // Si hay datos y la lista de actividades no esta vacia, 
                            // mostrar los registros de actividad.
                            return SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (BuildContext context, int i) {
                                  return _ActivityCard(
                                    activity: activites[i],
                                  );
                                },
                                childCount: activityCount
                              ),
                            );
                          } else {
                            // Retornar un placeholder si los datos están cargando, o no hay datos aín.
                            return const SliverDataPlaceholder(
                              message: 'Aún no hay actividad física registrada.',
                              icon: Icons.fact_check_rounded,
                            );  
                          }
                        } else if (snapshot.hasError) {
                          // Retornar un placeholder, indicando que hubo un error.
                          return const SliverDataPlaceholder(
                            isLoading: false,
                            message: 'Hubo un error obteniendo tus registros de actividad.',
                            icon: Icons.error,
                          ); 
                        }

                        // El future no tiene datos ni error, aún no ha sido
                        // completado.
                        return const SliverDataPlaceholder(
                          isLoading: true,
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

  //TODO: Hacer esto non-nullable otra vez.
  final ActivityRecord? activity;

  const _ActivityCard({ required this.activity, Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final int activityTypeIdx = activity?.activityType.id ?? -1;
    final activityTypeLabel = DropdownLabels.activityLabels(context)[activityTypeIdx];

    final activityRecord = activity;

    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all( 16.0 ),
        child: (activityRecord != null) 
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox( 
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: Text(
                      activityRecord.title,
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

                        (activityRecord.isRoutine)
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

                        (activityRecord.isIntense)
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
                activityRecord.formattedDate,
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
                      statLabel: activityRecord.formattedDistance,
                      icon: Icons.directions_run
                    ),
                    _ActivityCardStatIcon(
                      statLabel: activityRecord.formattedDuration,
                      icon: Icons.schedule
                    ),
                    _ActivityCardStatIcon(
                      statLabel: activityRecord.formattedKcal,
                      icon: Icons.bolt
                    ),
                  ],
                ),
              )
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox( 
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: Text(
                      'Actividad no encontrada',
                      style: Theme.of(context).textTheme.headline6,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ), 
                ]
              ),
            ]
          )
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