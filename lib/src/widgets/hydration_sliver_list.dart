import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/models/goal.dart';
import 'package:hydrate_app/src/models/hydration_record.dart';
import 'package:hydrate_app/src/models/medical_data.dart';
import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/services/goals_service.dart';
import 'package:hydrate_app/src/services/hydration_record_service.dart';
import 'package:hydrate_app/src/services/profile_service.dart';
import 'package:hydrate_app/src/utils/datetime_extensions.dart';
import 'package:hydrate_app/src/widgets/data_placeholder.dart';
import 'package:hydrate_app/src/widgets/week_totals_chart.dart';

class HydrationSliverList extends StatelessWidget {

  const HydrationSliverList({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;

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
                  yUnit: localizations.mililitersAbbreviated,
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
                                return SliverToBoxAdapter(
                                  child: DataPlaceholder(
                                    message: "${localizations.noHydrationRecordsYet} ${localizations.drinkAndComeBackLater}",
                                    icon: Icons.fact_check_rounded,
                                  ),
                                );
                              }
                            } else if (snapshot.hasError) {
                              return SliverToBoxAdapter(
                                child: DataPlaceholder(
                                  message: localizations.errorFetchingHydration,
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

  String _getDateLabel(BuildContext context) {

    final DateTime? timestamp;

    if (hydrationRecords.isEmpty) {
      timestamp = associatedMedicalRecord?.createdAt;
    } else {
      timestamp = hydrationRecords.first.date;
    }

    assert(timestamp != null, "Una _HydrationCard fue creada sin registros de hidratacion ni medicos");

    final localizations = AppLocalizations.of(context)!;

    if (timestamp != null) {
      final today = DateTime.now().onlyDate;
      final yesterday = today.subtract(const Duration(days: 1));

      String dateAsString = timestamp.toString().substring(0,10);
    
      if (timestamp.isAfter(today)) {
        dateAsString = localizations.today;
      } else if (timestamp.isAfter(yesterday)) {
        dateAsString = localizations.yesterday;
      }

      return dateAsString;
    } else {
      return localizations.noDate;
    }
  }

  int _getTotalWaterIntakeForDay() {
    if (hydrationRecords.isNotEmpty) {
      return hydrationRecords
        .map((e) => e.volumeInMl)
        .reduce((total, v) => total + v);

    } else {
      return 0;
    }
  }

  String _getHydrationRecordLabel(BuildContext context, HydrationRecord hydrationRecord) {
    final timeAsString = hydrationRecord.date.toString().substring(11,16);
    final localizations = AppLocalizations.of(context)!;

    return "$timeAsString - ${hydrationRecord.volumeInMl} ${localizations.mililitersAbbreviated}";
  }

  @override
  Widget build(BuildContext context) {

    final totalWaterIntakeForDay = _getTotalWaterIntakeForDay();

    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ListTile(
            title: Text(
              _getDateLabel(context),
              style: Theme.of(context).textTheme.headline4?.copyWith(fontWeight: FontWeight.w500),
            ),
            trailing: _DailyProgressText(
              totalIntake: totalWaterIntakeForDay,
            ),
            minVerticalPadding: 0,
            visualDensity: VisualDensity.compact,
          ),

          Consumer<ProfileService>(
            builder: (context, profileService, __) {
              return FutureBuilder<UserProfile?>(
                future: profileService.profile,
                initialData: null,
                builder: (context, snapshot) {

                  final profileHasMedicalCondition = snapshot.hasData &&
                    (snapshot.data!.hasRenalInsufficiency || snapshot.data!.hasNephroticSyndrome);
                  
                  if (profileHasMedicalCondition) {
                    return Consumer<GoalsService>(
                      builder: (_, goalsService, __) {
                        return FutureBuilder<Goal?>(
                          future: goalsService.mainActiveGoal,
                          builder: (context, snapshot) {
                            return Container(
                              margin: const EdgeInsets.symmetric( vertical: 4.0 ),
                              child: _HydrationStatusChip(
                                mainTarget: snapshot.data?.quantity ?? 0,
                                totalWaterIntakeForDay: totalWaterIntakeForDay,
                              ),
                            );
                          }
                        );
                      }
                    );
                  } else {
                    return const SizedBox( height: 0.0 );
                  }
                }
              );
            }
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
                      _getHydrationRecordLabel(context, hydrationRecords[i]),
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

class _HydrationStatusChip extends StatelessWidget {

  const _HydrationStatusChip({
    Key? key,
    this.totalWaterIntakeForDay = 0,
    this.mainTarget = 0,
  }) : super(key: key);

  final int totalWaterIntakeForDay;

  final int mainTarget;

  @override
  Widget build(BuildContext context) {

    if (mainTarget == 0 || totalWaterIntakeForDay < mainTarget) {
      return const SizedBox( height: 0.0 );
    }

    final localizations = AppLocalizations.of(context)!;

    final bool hasExceededTarget = totalWaterIntakeForDay + (mainTarget * 0.25) >= mainTarget;
    final String warningText = hasExceededTarget 
      ? localizations.exceedsHydration 
      : localizations.stableHydration;

    return Chip(
      backgroundColor: hasExceededTarget ? Colors.red : Colors.green,
      label: Text(warningText),
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

    final localizations = AppLocalizations.of(context)!;

    return Consumer<GoalsService>(
      builder: (_, goalsService, __) {
        return FutureBuilder<Goal?>(
          future: goalsService.mainActiveGoal,
          builder: (context, snapshot) {

            String amountLabel = "$totalIntake${localizations.mililitersAbbreviated}";
            Color? textColor = Theme.of(context).colorScheme.primary;

            if (snapshot.hasData) {
              amountLabel += " / ${snapshot.data!.quantity}${localizations.mililitersAbbreviated}";

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

    final localizations = AppLocalizations.of(context)!;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(localizations.medicalReport),
        subtitle: Text(localizations.yourMedicalData),
        leading: Icon(
          _getIconForGain(
            medicalRecord.actualGain, 
            medicalRecord.recommendedGain
          ),
        ),
        children: [
          GridView.count(
            primary: false,
            mainAxisSpacing: 0.0,
            crossAxisSpacing: 8.0,
            crossAxisCount: 1,
            shrinkWrap: true,
            childAspectRatio: MediaQuery.of(context).size.width / 64.0,
            children: [
              ListTile(
                title: Text(localizations.hypervolemia),
                trailing: Text(medicalRecord.hypervolemia.toString()),
              ),
              ListTile(
                title: Text(localizations.postDialysisWeight),
                trailing: Text(medicalRecord.postDialysisWeight.toString()),
              ),
              ListTile(
                title: Text(localizations.extraCellularWater),
                trailing: Text(medicalRecord.extracellularWater.toString()),
              ),
              ListTile(
                title: Text(localizations.normovolemia),
                trailing: Text(medicalRecord.normovolemia.toString()),
              ),
              ListTile(
                title: Text(localizations.recommendedGain),
                trailing: Text(medicalRecord.recommendedGain.toString()),
              ),
              ListTile(
                title: Text(localizations.realGain),
                trailing: Text(medicalRecord.actualGain.toString()),
              ),
            ],
          ),
        ],
      ),
    );
  } 
} 