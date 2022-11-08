import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/models/goal.dart';
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
      child: Consumer<HydrationRecordService>(
        builder: (_, hydrationRecordService, __) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget> [
              SliverToBoxAdapter(
                child: WeekTotalsChart(
                  dailyTotals: hydrationRecordService.pastWeekMlTotals,
                  maxYValue: 2000.0,
                  yUnit: 'ml',
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(8.0),
                sliver: Consumer<GoalsService>(
                  builder: (context, goalsService, __) {
                    return FutureBuilder<List<MedicalData>>(
                      future: goalsService.medicalData,
                      initialData: const <MedicalData>[],
                      builder: (context, snapshot) {

                        final medicalRecords = snapshot.data ?? const <MedicalData>[];

                        return FutureBuilder<List<HydrationSummary>>(
                          future: hydrationRecordService.getHydrationSummary(medicalRecords: medicalRecords),
                          initialData: const <HydrationSummary>[],
                          builder: (context, snapshot) {

                            if (snapshot.hasData) {
                              if (snapshot.data!.isNotEmpty) {

                                final historialHydration = snapshot.data ?? const <HydrationSummary>[];

                                return SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (BuildContext context, int i) {
                                      return _HydrationCard(
                                        hydrationRecords: historialHydration[i].hydrationRecords,
                                        associatedMedicalRecord: historialHydration[i].medicalRecord,
                                      );
                                    },
                                    childCount: historialHydration.length,
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
                        );
                      }
                    );
                  }
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}

class _HydrationCard extends StatelessWidget {

  const _HydrationCard({ 
    Key? key,
    required this.hydrationRecords, 
    this.associatedMedicalRecord,
  }) : super(key: key);

  final List<HydrationRecord> hydrationRecords;

  final MedicalData? associatedMedicalRecord;

  String _getDateLabel() {

    final DateTime? timestamp;

    if (hydrationRecords.isEmpty) {
      timestamp = associatedMedicalRecord?.createdAt;
    } else {
      timestamp = hydrationRecords.first.date;
    }

    assert(timestamp != null, "Una _HydrationCard fue creada sin registros de hidratacion ni medicos");

    if (timestamp != null) {
      final today = DateTime.now().onlyDate;
      final yesterday = today.subtract(const Duration(days: 1));

      String dateAsString = timestamp.toString().substring(0,10);
    
      if (timestamp.isAfter(today)) {
        //TODO: agregar i18n
        dateAsString = 'Hoy';
      } else if (timestamp.isAfter(yesterday)) {
        //TODO: agregar i18n
        dateAsString = 'Ayer';
      }

      return dateAsString;
    } else {
      return "Unknown date";
    }
  }

  int _getTotalWaterIntakeForDay() {
    if (hydrationRecords.isNotEmpty) {
      return hydrationRecords
        .map((e) => e.amount)
        .reduce((total, v) => total + v);

    } else {
      return 0;
    }
  }

  String _getHydrationRecordLabel(HydrationRecord hydrationRecord) {
    final timeAsString = hydrationRecord.date.toString().substring(11,16);
    return "$timeAsString - ${hydrationRecord.amount} ml";
  }

  @override
  Widget build(BuildContext context) {

    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ListTile(
            title: Text(
              _getDateLabel(),
              style: Theme.of(context).textTheme.headline4?.copyWith(fontWeight: FontWeight.w500),
            ),
            trailing: _DailyProgressText(
              totalIntake: _getTotalWaterIntakeForDay()
            ),
            minVerticalPadding: 0,
            visualDensity: VisualDensity.compact,
          ),

          Container(
            height: 16.0 * hydrationRecords.length + 48.0,
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
                      _getHydrationRecordLabel(hydrationRecords[i]),
                      style: Theme.of(context).textTheme.bodyText1,
                    ),
                  ],
                );
              },
            ),
          ),

          if (associatedMedicalRecord != null)
          _MedicalRecordData(
            medicalRecord: associatedMedicalRecord!,
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
    required this.medicalRecord,
  }) : super(key: key);

  final MedicalData medicalRecord;

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
} 