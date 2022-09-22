import 'dart:math';

import 'package:hydrate_app/src/models/enums/time_term.dart';
import 'package:hydrate_app/src/models/enums/user_sex.dart';
import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/models/routine_occurrence.dart';
import 'package:hydrate_app/src/models/validators/range.dart';
import 'package:hydrate_app/src/utils/datetime_extensions.dart';

class IdealHydrationCalculator {

  static int _previousRecommendation = 0;

  /// El incremento máximo a partir de fuentes de activitdad y temperatura a  la
  /// hidratación sugerida.
  static const int maxIncrFromActAndTemp = 500;

  static const int maxDifferenceFromPrevRecommendation = 100;

  static const int numOfIntenseActivitiesForIncrement = 3; 

  static const Range dailyHydrationRangeMl = Range(min: 1000, max: 3500);

  static const baseWaterIntakeByGenderAndAge = {
    UserSex.man: { 
      19: 3000,
    },
    UserSex.woman: {
      19: 2200,
    },
    UserSex.notSpecified: {
      19: 2500,
    },
  };

  /// Calcula la ingesta de agua ideal para un usuario, con base en su
  /// [UserProfile] y otros varios parámetros opcionales para esta función.
  static int aproximateIdealHydration(
    UserProfile profile,
    List<RoutineOccurrence> activityDuringPastWeek,
    List<int> dailyHydrationTotals, { 
      Habits? mostRecentWeeklyReport,
      MedicalData? mostRecentMedicalReport,
      Range? temperatureRangeInPastWeek,
      TimeTerm term = TimeTerm.daily,
    }
  ) {

    final Map<int, int> baseIntakesForGender = baseWaterIntakeByGenderAndAge[profile.sex]
      ?? baseWaterIntakeByGenderAndAge[UserSex.notSpecified]!;

    int baseIntake = 0;

    for (final baseWaterIntake in baseIntakesForGender.entries) {
      if (baseWaterIntake.key > profile.ageInYears) {
        baseIntake = baseWaterIntake.value;
        break;
      }
    }

    final int incrFromWeightAndHeight = (profile.weight * 2.0 / 3).floor();

    int waterIntake = ((incrFromWeightAndHeight + baseIntake) / 2).floor();

    // Determinar el incremento en ml como resultado de la actividad física.
    final incrMlFromActivity = aproximateHydrationChangeFromActivity(activityDuringPastWeek);

    // Determinar el incremento en ml como resultado de la temperatura.
    final incrMlFromTemperature = aproximateRecommendationFromTemperature(
      mostRecentWeeklyReport?.maxTemperature ?? 25.0,
      temperatureRangeInPastWeek
    );

    final incrFromActivityAndTemperature = incrMlFromActivity.abs() + incrMlFromTemperature.abs();

    // El consumo de agua por actividades y temperatura, limitado a [maxIncrFromActAndTemp].
    waterIntake += min(incrFromActivityAndTemperature, maxIncrFromActAndTemp);

    // Balancear el consumo de agua recomendado con el consumo diario durante la 
    // semana pasada.
    final avgDailyIntakeInPreviousWeek = dailyHydrationTotals
      .reduce((total, dailyTotal) => total + dailyTotal) / 7;

    // Si 
    final hasPreviousRecommendation = dailyHydrationRangeMl
        .compareTo(_previousRecommendation) == 0;

    // Si existe una recomendación anterior, limitar el cambio entre la 
    // recomendación anterior y la nueva recomendación.
    if (hasPreviousRecommendation) {

      final lowerBound = _previousRecommendation - maxDifferenceFromPrevRecommendation;
      final upperBound = _previousRecommendation + maxDifferenceFromPrevRecommendation;

      // Restringir el cambio total entre la recomendación anterior y la siguiente.
      waterIntake = min(max(waterIntake, lowerBound), upperBound);
    }

    waterIntake = min(max(waterIntake, dailyHydrationRangeMl.min.toInt()), dailyHydrationRangeMl.max.toInt());
    
    // Actualizar la recomendacion anterior, después de usar su valor.
    _previousRecommendation = waterIntake;

    return waterIntake;
  }

  static int aproximateHydrationChangeFromActivity(List<RoutineOccurrence> physicalActivityInPastWeek) {

    final DateTime now = DateTime.now();
    final DateTime threeDaysAgo = now.onlyDate.subtract(const Duration( days: 2 ));

    int incrementInMlFromActivity = 0;

    final int numOfIntenseActivitiesDuringPastThreeDays = physicalActivityInPastWeek
      .where((record) => (record.activity.isIntense && record.date.onlyDate.isInRange(threeDaysAgo, now)))
      .length;

    if (numOfIntenseActivitiesDuringPastThreeDays > numOfIntenseActivitiesForIncrement) {
      incrementInMlFromActivity += 100;
    }

    return incrementInMlFromActivity;
  }

  /// Determina el incremento en consumo de agua recomendado a causa
  /// de la temperatura durante la semana anterior. 
  ///
  /// Por cada grado celsius de diferencia positiva entre [averageTemperature] 
  /// y 28°C, este método agrega 50 ml extra de consumo de agua por día. 
  static int aproximateRecommendationFromTemperature(
    double averageTemperature,
    Range? temperatureRangeInPastWeek,
  ) {
    const double beginIncrementFromTemperature = 28.0;
    const int maxDegreesCelsiusOfDifference = 5;
    const int incrementMlPerDegreeCelsius = 25;

    int incrementFromTemperature = 0;

    final int degreesOfDifference = (averageTemperature - beginIncrementFromTemperature).round();

    if (degreesOfDifference > 0) {
      incrementFromTemperature += incrementMlPerDegreeCelsius * min(degreesOfDifference, maxDegreesCelsiusOfDifference);
    }

    return incrementFromTemperature;
  }
}