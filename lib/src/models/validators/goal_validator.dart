import 'package:flutter/widgets.dart';

import 'package:hydrate_app/src/models/enums/error_types.dart';
import 'package:hydrate_app/src/models/enums/time_term.dart';
import 'package:hydrate_app/src/models/goal.dart';
import 'package:hydrate_app/src/models/tag.dart';
import 'package:hydrate_app/src/models/validators/range.dart';
import 'package:hydrate_app/src/models/validators/validator.dart';

class GoalValidator extends Validator {

  const GoalValidator();

  static final Range termRange = Range(max: TimeTerm.values.length);
  static const Range waterVolumeRange = Range(min: 10, max: 5000);
  static const Range notesLengthRange = Range(max: 100);
  static const Range tagCountRange = Range(max: 3);
  static const Range coinRewardRange = Range(min: 0, max: 500);

  static const Set<String> requiredFields = <String>{
    Goal.termFieldName,
    Goal.quantityFieldName,
    Goal.startDateFieldName,
    Goal.endDateFieldName,
    Goal.rewardFieldName,
  };

  @override
  bool isFieldRequired(String fieldName) => requiredFields.contains(fieldName);

  @override
  bool isValid(Object? instanceToValidate) {
    if (instanceToValidate is! Goal) {
      throw UnsupportedError("A GoalValidator cannot validate a value that is not an instance of Goal");
    }

    final isTermValid = validateTerm(instanceToValidate.term.index) == NumericInputError.none;
    final isEndDateValid = validateEndDate(instanceToValidate.startDate, instanceToValidate.endDate.toIso8601String()) == NumericInputError.none;
    final isWaterVolumeValid = validateWaterQuantity(instanceToValidate.quantity) == NumericInputError.none;
    final isRewardValid = validateReward(instanceToValidate.reward) == NumericInputError.none; 
    final areTagsValid = validateTags(instanceToValidate.tags) == NumericInputError.none;
    final areNotesValid = validateNotes(instanceToValidate.notes) == TextLengthError.none;

    return isTermValid && isEndDateValid && isWaterVolumeValid && 
           isRewardValid && areTagsValid && areNotesValid;
  }

  NumericInputError validateTerm(int? termIndex) {

    NumericInputError timeTermError = NumericInputError.none;

    if (termIndex != null) {
      timeTermError = Validator.validateRange(
        termIndex,
        range: termRange
      );

    } else if (isFieldRequired(Goal.termFieldName)) {
      timeTermError = NumericInputError.isEmptyWhenRequired;
    }

    return timeTermError;
  }

  NumericInputError validateEndDate(DateTime? startDateValue, String? endDateInput) {
    
    NumericInputError endDateError = NumericInputError.none;

    if (endDateInput != null) {

      DateTime? endDateValue = DateTime.tryParse(endDateInput);

      final bool hasDatesWithCorrectFormat = endDateValue != null && startDateValue != null;

      if (hasDatesWithCorrectFormat) {

        final nextDay = startDateValue.add(const Duration(days: 1));
        final endDateIsBeforeStartDate = !(endDateValue.isAfter(nextDay));

        if (endDateIsBeforeStartDate) {
          endDateError = NumericInputError.inputIsBeforeRange;
        }
      } else {
        endDateError = NumericInputError.isNaN;
      }
    } else if (isFieldRequired(Goal.endDateFieldName)) {
      endDateError = NumericInputError.isEmptyWhenRequired;
    }

    return endDateError;
  }

  NumericInputError validateWaterQuantity(Object? inputValue) {

    NumericInputError waterQuantityError = NumericInputError.none;

    if (inputValue != null) {

      final parsedWaterVolume = Validator.tryParseInputAsInt(inputValue);

      if (parsedWaterVolume != null) {
        waterQuantityError = Validator.validateRange(
          parsedWaterVolume, 
          range: waterVolumeRange,
        );

      } else {
        waterQuantityError = NumericInputError.isNaN;
      }
    } else if (isFieldRequired(Goal.quantityFieldName)) {
      waterQuantityError = NumericInputError.isEmptyWhenRequired;
    }

    return waterQuantityError;
  }

  NumericInputError validateReward(Object? inputValue) {

    NumericInputError rewardError = NumericInputError.none;

    if (inputValue != null) {

      final parsedCoinReward = Validator.tryParseInputAsInt(inputValue);

      if (parsedCoinReward != null) {
        rewardError = Validator.validateRange(
          parsedCoinReward, 
          range: coinRewardRange,
        );

      } else {
        rewardError = NumericInputError.isNaN;
      }
    }

    return rewardError;
  }

  NumericInputError validateTags(List<Tag>? inputValue) {

    NumericInputError tagCountError = NumericInputError.none;

    if (inputValue != null && inputValue.isNotEmpty) {

      final int tagCount = inputValue.length;
      tagCountError = Validator.validateRange(
        tagCount, 
        range: tagCountRange,
      );
    }

    return tagCountError;
  } 

  TextLengthError validateNotes(String? inputValue) {

    TextLengthError lastNameError = TextLengthError.none;

    if (inputValue != null) {

      final areNotesRequired = isFieldRequired(Goal.notesFieldName);

      if (areNotesRequired && inputValue.characters.isEmpty) {
        // Las notas son obligatorias, pero no tienen un valor (el string está vacío).
        lastNameError = TextLengthError.textIsEmptyError;

      } else if (inputValue.characters.length > notesLengthRange.max) {
        // Las notas sobrepasan el límite de caracteres.
        lastNameError = TextLengthError.textExceedsCharLimit;
      }
    }

    return lastNameError;
  }
}