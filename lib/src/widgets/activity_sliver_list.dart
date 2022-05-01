import 'package:flutter/material.dart';
import 'package:hydrate_app/src/utils/dropdown_labels.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/models/activity_record.dart';
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
                      isLoading: provider.isLoading,
                      dailyTotals: provider.weekDailyTotals,
                      yUnit: 'kCal',
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.all(8.0),
                    sliver: Builder(
                      builder: (context) {
                        String msg = '';
                        IconData placeholderIcon = Icons.info;
                  
                        if (!provider.isLoading && provider.activityRecords.isEmpty) {
                          msg = 'Aún no hay actividad física registrada.';
                          placeholderIcon = Icons.fact_check_rounded;
                        }
                  
                        if (provider.isLoading || provider.activityRecords.isEmpty) {
                          // Retornar un placeholder si los datos están cargando, o no hay datos aín.
                          return SliverDataPlaceholder(
                            isLoading: provider.isLoading,
                            message: msg,
                            icon: placeholderIcon,
                          );
          
                        } else {
                          // Retornar la lista de registros de hidratacion del usuario.
                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (BuildContext context, int i) {
                                return _ActivityCard(
                                  activityRecord: provider.activityRecords[i],
                                );
                              },
                              childCount: provider.activityRecords.length,
                            ),
                          );
                        }
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

  final ActivityRecord activityRecord;

  const _ActivityCard({ required this.activityRecord, Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final int activityTypeIdx = activityRecord.activityType.activityTypeValue.index;
    final activityTypeLabel = DropdownLabels.activityLabels[activityTypeIdx];

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
                Text(
                  activityRecord.title,
                  style: Theme.of(context).textTheme.headline6,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                (activityRecord.isIntense)
                ? Container(
                    width: 24.0,
                    child: const Icon(
                      Icons.directions_walk, 
                      color: Colors.yellow,
                      size: 24.0,
                    ),
                    decoration: BoxDecoration(

                      shape: BoxShape.circle,
                      color: Colors.yellow[300]?.withOpacity(0.3),
                    ),
                  )
                : const SizedBox(),
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