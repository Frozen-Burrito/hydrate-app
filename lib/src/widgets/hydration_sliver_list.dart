import 'package:flutter/material.dart';
import 'package:hydrate_app/src/models/goal.dart';
import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/services/profile_service.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/models/hydration_record.dart';
import 'package:hydrate_app/src/models/medical_data.dart';
import 'package:hydrate_app/src/services/goals_service.dart';
import 'package:hydrate_app/src/services/hydration_record_service.dart';
import 'package:hydrate_app/src/utils/datetime_extensions.dart';
import 'package:hydrate_app/src/widgets/data_placeholder.dart';
import 'package:hydrate_app/src/widgets/week_totals_chart.dart';

class HydrationSliverList extends StatelessWidget {
  const HydrationSliverList({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Builder(
        builder: (context) {
          return Consumer<HydrationRecordService>(
            builder: (_, provider, __) {
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: <Widget> [
                  // SliverOverlapInjector(
                  //   handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  // ),

                  SliverToBoxAdapter(
                    child: WeekTotalsChart(
                      dailyTotals: provider.pastWeekMlTotals,
                      maxYValue: 2000.0,
                      yUnit: 'ml',
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.all(8.0),
                    sliver: FutureBuilder<Map<DateTime, List<HydrationRecord>>>(
                      future: provider.dailyHidration,
                      builder: (context, snapshot) {

                        if (snapshot.hasData) {
                          if (snapshot.data!.isNotEmpty) {
                            final sortedRecords = snapshot.data!.values.toList();

                            // Retornar la lista de registros de hidratacion del usuario.
                            return SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (BuildContext context, int i) {
                                  return _HydrationCard(
                                    hydrationRecords: sortedRecords[i],
                                  );
                                },
                                childCount: snapshot.data!.length,
                              ),
                            );
                          } else {
                            return const SliverToBoxAdapter(
                              child: DataPlaceholder(
                                //TODO: agregar i18n.
                                message: 'Aún no hay registros de hidratación. Toma agua y vuelve más tarde.',
                                icon: Icons.fact_check_rounded,
                              ),
                            );
                          }
                        } else if (snapshot.hasError) {
                          return const SliverToBoxAdapter(
                            child: DataPlaceholder(
                              //TODO: agregar i18n.
                              message: 'Hubo un error al intentar obtener registros de hidratación.',
                              icon: Icons.error_outline,
                            ),
                          );
                        }

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

class _HydrationCard extends StatelessWidget {

  final List<HydrationRecord> hydrationRecords;

  const _HydrationCard({ required this.hydrationRecords, Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final totalIntake = hydrationRecords.isNotEmpty 
      ? hydrationRecords.map((e) => e.amount).reduce((total, v) => total + v)
      : 0;

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    String dateString = hydrationRecords[0].date.toString().substring(0,10);
    
    //TODO: agregar i18n
    if (hydrationRecords[0].date.isAfter(today)) {
      dateString = 'Hoy';
    } else if (hydrationRecords[0].date.isAfter(today.subtract(const Duration(days: 1)))) {
      dateString = 'Ayer';
    }

    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ListTile(
            title: Text(
              hydrationRecords.isNotEmpty ? dateString : 'Sin fecha',
              style: Theme.of(context).textTheme.headline4?.copyWith(fontWeight: FontWeight.w500),
            ),
            trailing: _DailyProgressText(totalIntake: totalIntake),
            minVerticalPadding: 0,
            visualDensity: VisualDensity.compact,
          ),

          SizedBox(
            height: 16.0 * hydrationRecords.length + 48.0,
            child:Padding(
              padding: const EdgeInsets.only( left: 16.0, right: 16.0, bottom: 16.0),
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 16.0),
                itemCount: hydrationRecords.length,
                itemBuilder: (context, i) {
                  return Row(
                    children: [
                      Container(
                        width: 16.0,
                        height: 16.0,
                        color: Theme.of(context).colorScheme.primaryContainer,
                        margin: const EdgeInsets.only(right: 4.0),
                      ),

                      Text(
                        '${hydrationRecords[i].date.toString().substring(11,16)} - ${hydrationRecords[i].amount} ml',
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          _MedicalRecordData(
            hydrationRecords: hydrationRecords,
          ),
        ],
      ),
    );
  }
}

class _DailyProgressText extends StatelessWidget {
  const _DailyProgressText({
    Key? key,
    required this.totalIntake,
  }) : super(key: key);

  final int totalIntake;

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalsService>(
      builder: (_, goalsService, __) {
        return FutureBuilder<Goal?>(
          future: goalsService.mainActiveGoal,
          builder: (context, snapshot) {

            String amountLabel = "${totalIntake}ml";
            Color? textColor = Theme.of(context).colorScheme.primary;

            if (snapshot.hasData) {
              amountLabel += " / ${snapshot.data!.quantity}ml";

              if (totalIntake < snapshot.data!.quantity) {
                textColor = Theme.of(context).colorScheme.onSurface;
              }
            }

            return Text(
              amountLabel,
              style: Theme.of(context).textTheme.headline5?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500
              ),
            );
          }
        );
      }
    );
  }
}

class _MedicalRecordData extends StatelessWidget {

  const _MedicalRecordData({
    Key? key, 
    this.hydrationRecords = const <HydrationRecord>[],
  }) : super(key: key);

  final List<HydrationRecord> hydrationRecords;

  IconData _getIconForGain(double actualGain, double recommendedGain) {
    if (actualGain == recommendedGain) {
      return Icons.minimize;
    } else if (actualGain > recommendedGain) {
      return Icons.arrow_upward;
    } else {
      return Icons.arrow_downward;
    }
  }

  @override
  Widget build(BuildContext context) {

    final goalsService = Provider.of<GoalsService>(context);
    final profileService = Provider.of<ProfileService>(context);

    return FutureBuilder<UserProfile?>(
      future: profileService.profile,
      builder: (context, profileSnapshot) => FutureBuilder<List<MedicalData>>(
        future: goalsService.medicalData,
        builder: (context, snapshot) {
          
          final hasMedicalCondition = profileSnapshot.hasData && 
            (profileSnapshot.data!.hasRenalInsufficiency || 
             profileSnapshot.data!.hasNephroticSyndrome);
            
          if (hasMedicalCondition && snapshot.hasData ) {
            // Existen registros médicos del usuario.
            final medicalRecords = snapshot.data!;

            final recordsForDate = medicalRecords
                .where((record) => record.createdAt.onlyDate
                  .isAtSameMomentAs(hydrationRecords.first.date)
                );

            // if (recordsForDate.isNotEmpty) {

              final medicalRecord = MedicalData(id: 1, profileId: 1, hypervolemia: 0.0, postDialysisWeight: 0.0, extracellularWater: 0.0, normovolemia: 0.0, recommendedGain: 20.0, actualGain: 10.0, nextAppointment: DateTime.now(), createdAt: DateTime.now());

              //TODO: agregar i18n
              return Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text("Reporte médico"),
                  subtitle: Text("Tus datos médicos para este día:"),
                  leading: Icon(
                    _getIconForGain(
                      medicalRecord.actualGain, 
                      medicalRecord.recommendedGain
                    ),
                  ),
                  children: [
                    GridView.count(
                      primary: false,
                      mainAxisSpacing: 8.0,
                      crossAxisSpacing: 8.0,
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      childAspectRatio: MediaQuery.of(context).size.width * 0.5 / 64.0,
                      children: [
                        ListTile(
                          title: Text("Hipervolemia"),
                          trailing: Text(medicalRecord.hypervolemia.toString()),
                        ),
                        ListTile(
                          title: Text("Peso post-diálisis"),
                          trailing: Text(medicalRecord.postDialysisWeight.toString()),
                        ),
                        ListTile(
                          title: Text("Agua extracelular"),
                          trailing: Text(medicalRecord.extracellularWater.toString()),
                        ),
                        ListTile(
                          title: Text("Normovolemia"),
                          trailing: Text(medicalRecord.normovolemia.toString()),
                        ),
                        ListTile(
                          title: Text("Ganancia recomendada"),
                          trailing: Text(medicalRecord.recommendedGain.toString()),
                        ),
                        ListTile(
                          title: Text("Ganancia real"),
                          trailing: Text(medicalRecord.actualGain.toString()),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            } 
          // } 

          // Si no hay registros médicos, o no hay uno que coincida con la 
          // fecha de hydrationRecord retornar un SizedBox vacío.
          return const SizedBox( height: 0.0,);
        },
      )
    );
  }
}