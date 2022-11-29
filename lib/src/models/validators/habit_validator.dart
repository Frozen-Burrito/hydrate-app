import 'package:hydrate_app/src/models/enums/error_types.dart';
import 'package:hydrate_app/src/models/habits.dart';
import 'package:hydrate_app/src/models/validators/range.dart';
import 'package:hydrate_app/src/models/validators/validator.dart';

class HabitValidator extends Validator {

  const HabitValidator();

  static const Range dailyHoursRange = Range(max: 24);
  static const Range maxTemperatureRange = Range(min: -60.0, max: 60.0);

  static const Set<String> requiredFields = <String>{
    Habits.hoursOfSleepFieldName,
    Habits.hoursOfOccupationFieldName,
    Habits.hoursOfActivityFieldName,
    Habits.maxTemperatureFieldName,
  };

  @override
  bool isFieldRequired(String fieldName) => requiredFields.contains(fieldName);

  @override
  bool isValid(Object? instanceToValidate) {
    if (instanceToValidate is! Habits) {
      throw UnsupportedError("A HabitValidator cannot validate a value that is not an instance of Habits");
    }

    final isHourTotalValid = validateHourTotal(instanceToValidate.totalHoursPerDay) == NumericInputError.none;
    final isMaxTempValid = validateMaxTemperature(instanceToValidate.maxTemperature.toString()) == NumericInputError.none; 

    return isHourTotalValid && isMaxTempValid;
  }

  /// Verifica que la suma total de horas en [dailyHourAvgs] esté entre 0 y 24.
  NumericInputError validateHourTotal(double totalAverageHours) { 
    
    NumericInputError hourTotalError = NumericInputError.none;

    final int comparisonResult = dailyHoursRange.compareTo(totalAverageHours);

    if (comparisonResult > 0) {
      hourTotalError = NumericInputError.inputIsAfterRange;
    } else if (comparisonResult < 0) {
      hourTotalError = NumericInputError.inputIsBeforeRange;
    }

    return hourTotalError;
  }

  /// Verifica que [inputTemperature] pueda convertirse a número decimal y esté 
  /// en el rango requerido.
  NumericInputError validateMaxTemperature(String? inputValue) {

    NumericInputError maxTemperatureError = NumericInputError.none;

    if (inputValue != null) {

      final double? parsedValue = Validator.tryParseInputAsDouble(inputValue);

      if (parsedValue != null) {
        final comparisonResult = maxTemperatureRange.compareTo(parsedValue);

        if (comparisonResult > 0) {
          maxTemperatureError = NumericInputError.inputIsAfterRange;
        } else if (comparisonResult < 0) {
          maxTemperatureError = NumericInputError.inputIsBeforeRange;
        }
      } else {
        maxTemperatureError = NumericInputError.isNaN;
      }

    } else if (isFieldRequired(Habits.maxTemperatureFieldName)) {
      maxTemperatureError = NumericInputError.isEmptyWhenRequired;
    }

    return maxTemperatureError;
  }
}