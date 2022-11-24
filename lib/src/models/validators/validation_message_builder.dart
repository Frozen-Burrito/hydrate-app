import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

import "package:hydrate_app/src/models/enums/error_types.dart";
import "package:hydrate_app/src/models/validators/activity_validator.dart";
import 'package:hydrate_app/src/models/validators/auth_validator.dart';
import 'package:hydrate_app/src/models/validators/goal_validator.dart';
import 'package:hydrate_app/src/models/validators/habit_validator.dart';
import 'package:hydrate_app/src/models/validators/profile_validator.dart';

class ValidationMessageBuilder {

  ValidationMessageBuilder.of(BuildContext context) 
    : _localizations = AppLocalizations.of(context)!;

  final AppLocalizations _localizations;

  String _buildAmountError(String message, num amount, { String? units }) {
    final strBuf = StringBuffer(message);

    strBuf.writeAll([ " ", amount ]);
    if (units != null) {
      strBuf.writeAll([ " ", units ]);
    }

    return strBuf.toString();
  }

  String? messageForUsername(UsernameError usernameError) {

    switch(usernameError) {
      case UsernameError.none: return null;
      case UsernameError.noUsernameProvided: return _localizations.usernameIsRequiredError;
      case UsernameError.noEmailProvided: return _localizations.emailIsRequiredError;
      case UsernameError.incorrectEmailFormat: return _localizations.emailFormatError;
      case UsernameError.usernameTooShort: 
        return _buildAmountError(
          _localizations.usernameTooShortError,
          AuthValidator.usernameLengthRange.min.toInt(),
          units: _localizations.characters,
        );
      case UsernameError.usernameTooLong:
        return _buildAmountError(
          _localizations.usernameTooLongError,
          AuthValidator.usernameLengthRange.max.toInt(),
          units: _localizations.characters,
        );
      case UsernameError.incorrectUsernameFormat: return _localizations.usernameFormatError;
      default: 
        print("Unhandled username/email validation message for error: $usernameError");
        return "unkown error";
    }
  } 

  String? messageForPassword(PasswordError passwordError) {
    
    switch(passwordError) {
      case PasswordError.none: return null;
      case PasswordError.noPasswordProvided: return _localizations.passwordIsRequiredError;
      case PasswordError.passwordTooShort: 
        return _buildAmountError(
          _localizations.passwordTooShortError,
          AuthValidator.passwordLengthRange.min.toInt(),
          units: _localizations.characters,
        );
      case PasswordError.passwordTooLong:
        return _buildAmountError(
          _localizations.passwordTooLongMsg,
          AuthValidator.passwordLengthRange.max.toInt(),
          units: _localizations.characters,
        );
      case PasswordError.requiresSymbols: return _localizations.passwordRequiresSymbolsMsg;
      case PasswordError.noPasswordConfirm: return _localizations.passwordConfirmIsRequiredMsg;
      case PasswordError.passwordsDoNotMatch: return _localizations.passwordConfirmDoesNotMatchMsg;
      default: 
        print("Unhandled password validation message for error: $passwordError");
        return "unkown error";
    }
  } 

  String? forActivityTitle(TextLengthError titleError) {
    switch (titleError) {
      case TextLengthError.textExceedsCharLimit:
        return _buildAmountError(
          _localizations.activityTitleTooLong,
          ActivityValidator.titleLengthRange.max.toInt(),
          units: _localizations.characters,
        );
      default: return null;
    }
  }

  String? forActivityDuration(NumericInputError durationError) {
    switch (durationError) {
      case NumericInputError.none: return null;
      case NumericInputError.inputIsBeforeRange: 
        return _buildAmountError(
          _localizations.activityDurationIsTooSmall, 
          ActivityValidator.durationInMinutesRange.min.toInt(),
          units: _localizations.minutes
        );
      case NumericInputError.inputIsAfterRange: 
        return _buildAmountError(
          _localizations.activityDurationExceedsRange,
          ActivityValidator.durationInMinutesRange.max.toInt(),
          units: _localizations.minutes
        );
      default:
        print("Unhandled activity record duration validation message for error: $durationError");
        return null;
    }
  }

  String? forActivityDistance(NumericInputError distanceError) {
    switch (distanceError) {
      case NumericInputError.none: return null;
      case NumericInputError.inputIsBeforeRange: 
        return _buildAmountError(
          _localizations.activityDistanceIsTooSmall,
          ActivityValidator.distanceInMetersRange.min.toInt(),
          units: _localizations.meters,
        );
      case NumericInputError.inputIsAfterRange: 
        return _buildAmountError(
          _localizations.activityDistanceExceedsRange,
          ActivityValidator.distanceInMetersRange.max.toInt(),
          units: _localizations.meters,
        );
      default:
        print("Unhandled activity record distance validation message for error: $distanceError");
        return null;
    }
  }

  String? forActivityKcals(NumericInputError kCalsError) {
    switch (kCalsError) {
      case NumericInputError.none: return null;
      case NumericInputError.inputIsBeforeRange: 
        return _buildAmountError(
          _localizations.activityCaloriesIsTooSmall,
          ActivityValidator.distanceInMetersRange.min.toInt(),
          units: _localizations.kilocalories,
        );
      case NumericInputError.inputIsAfterRange: 
        return _buildAmountError(
          _localizations.activityCaloriesExceedsRange,
          ActivityValidator.distanceInMetersRange.max.toInt(),
          units: _localizations.kilocalories,
        );
      default:
        print("Unhandled activity record kCal validation message for error: $kCalsError");
        return null;
    }
  }

  String? forFirstName(TextLengthError firstNameError) {
    switch (firstNameError) {
      case TextLengthError.none: 
      case TextLengthError.textIsEmptyError:
        return null;
      case TextLengthError.textExceedsCharLimit:
        return _buildAmountError(
          _localizations.firstNameTooLong,
          ProfileValidator.firstNameLengthRange.max.toInt(),
          units: _localizations.characters,
        );
      default:
        print("Unhandled profile first name validation message for error: $firstNameError");
        return null;
    }
  }

  String? forLastName(TextLengthError lastNameError) {
    switch (lastNameError) {
      case TextLengthError.none: 
      case TextLengthError.textIsEmptyError:
        return null;
      case TextLengthError.textExceedsCharLimit:
        return _buildAmountError(
          _localizations.lastNameTooLong,
          ProfileValidator.lastNameLengthRange.max.toInt(),
          units: _localizations.characters,
        );
      default:
        print("Unhandled profile last name validation message for error: $lastNameError");
        return null;
    }
  }

  String? forHeight(NumericInputError heightError) {
    switch (heightError) {
      case NumericInputError.none: return null;
      case NumericInputError.isNaN: return _localizations.heightIsNaN;
      case NumericInputError.inputIsBeforeRange: 
        return _buildAmountError(
          _localizations.heightIsTooSmall, 
          ProfileValidator.heightRange.min.toInt(),
          units: _localizations.meters
        );
      case NumericInputError.inputIsAfterRange:
        return _buildAmountError(
          _localizations.heightIsTooLarge, 
          ProfileValidator.heightRange.max.toInt(),
          units: _localizations.meters
        );
      default:
        print("Unhandled profile height validation message for error: $heightError");
        return null;
    }
  }

  String? forWeight(NumericInputError weightError) {
    switch (weightError) {
      case NumericInputError.none: return null;
      case NumericInputError.isNaN: return _localizations.weightIsNaN;
      case NumericInputError.inputIsBeforeRange: 
        return _buildAmountError(
          _localizations.weightIsTooSmall, 
          ProfileValidator.weightRange.min.toInt(),
          units: _localizations.kilograms
        );
      case NumericInputError.inputIsAfterRange:
        return _buildAmountError(
          _localizations.weightIsTooLarge, 
          ProfileValidator.weightRange.max.toInt(),
          units: _localizations.kilograms
        );
      default:
        print("Unhandled profile weight validation message for error: $weightError");
        return null;
    }
  }

  String? forGoalTerm(NumericInputError termError) {
    switch (termError) {
      case NumericInputError.none: return null;
      case NumericInputError.isNaN: return _localizations.termIsNaN;
      case NumericInputError.isEmptyWhenRequired: return _localizations.termIsEmpty;
      case NumericInputError.inputIsBeforeRange: return _localizations.termIsNaN;
      case NumericInputError.inputIsAfterRange: return _localizations.termIsNaN;
      default:
        print("Unhandled goal term validation message for error: $termError");
        return null;
    }
  }

  String? forGoalEndDate(NumericInputError endDateError) {
    switch (endDateError) {
      case NumericInputError.none: return null;
      case NumericInputError.isNaN: return _localizations.endDateBadFormat;
      case NumericInputError.isEmptyWhenRequired: return _localizations.endDateRequired;
      case NumericInputError.inputIsBeforeRange: return _localizations.endDateBeforeStart;
      case NumericInputError.inputIsAfterRange: return _localizations.endDateTooLarge;
      default:
        print("Unhandled goal end date validation message for error: $endDateError");
        return null;
    }
  }

  String? forGoalWaterVolume(NumericInputError waterVolumeError) {
    switch (waterVolumeError) {
      case NumericInputError.none: return null;
      case NumericInputError.isNaN: return _localizations.waterAmountIsNaN;
      case NumericInputError.isEmptyWhenRequired: return _localizations.waterAmountIsRequired;
      case NumericInputError.inputIsBeforeRange: 
        return _buildAmountError(
          _localizations.waterAmountTooSmall, 
          GoalValidator.waterVolumeRange.min.toInt(),
          units: _localizations.mililiters
        );
      case NumericInputError.inputIsAfterRange:
        return _buildAmountError(
          _localizations.waterAmountTooLarge, 
          GoalValidator.waterVolumeRange.max.toInt(),
          units: _localizations.mililiters
        );
      default:
        print("Unhandled goal water volume validation message for error: $waterVolumeError");
        return null;
    }
  }

  String? forGoalReward(NumericInputError rewardError) {
    switch (rewardError) {
      case NumericInputError.none: return null;
      case NumericInputError.isNaN: return _localizations.rewardIsNaN;
      case NumericInputError.isEmptyWhenRequired: return _localizations.rewardIsRequired;
      case NumericInputError.inputIsBeforeRange: 
        return _buildAmountError(
          _localizations.rewardTooSmall, 
          GoalValidator.coinRewardRange.min.toInt(),
          units: _localizations.coins
        );
      case NumericInputError.inputIsAfterRange:
        return _buildAmountError(
          _localizations.rewardTooLarge, 
          GoalValidator.coinRewardRange.max.toInt(),
          units: _localizations.coins
        );
      default:
        print("Unhandled goal reward validation message for error: $rewardError");
        return null;
    }
  }

  String? forGoalTagCount(NumericInputError tagCountError) {
    switch (tagCountError) {
      case NumericInputError.none: return null;
      case NumericInputError.isNaN: return _localizations.tagCountIsNaN;
      case NumericInputError.isEmptyWhenRequired: return _localizations.tagCountIsRequired;
      case NumericInputError.inputIsBeforeRange: 
        return _buildAmountError(
          _localizations.tagCountTooSmall, 
          GoalValidator.tagCountRange.min.toInt(),
        );
      case NumericInputError.inputIsAfterRange:
        return _buildAmountError(
          _localizations.tagCountTooLarge, 
          GoalValidator.tagCountRange.max.toInt(),
        );
      default:
        print("Unhandled goal tags count validation message for error: $tagCountError");
        return null;
    }
  }

  String? forGoalNotes(TextLengthError notesError) {
    switch (notesError) {
      case TextLengthError.none: 
        return null;
      case TextLengthError.textIsEmptyError:
        return _localizations.notesAreRequired;
      case TextLengthError.textExceedsCharLimit:
        return _buildAmountError(
          _localizations.notesTooLong, 
          GoalValidator.notesLengthRange.max.toInt(),
          units: _localizations.characters,
        );
      default:
        print("Unhandled goal notes validation message for error: $notesError");
        return null;
    }
  }

  String? forMaxTemperature(NumericInputError temperatureError) {
    switch (temperatureError) {
      case NumericInputError.none: return null;
      case NumericInputError.isNaN: return _localizations.maxTempIsNaN;
      case NumericInputError.isEmptyWhenRequired: return _localizations.maxTempIsRequired;
      case NumericInputError.inputIsBeforeRange: 
        return _buildAmountError(
          _localizations.maxTempTooSmall, 
          HabitValidator.maxTemperatureRange.min.toInt(),
          units: _localizations.degrees
        );
      case NumericInputError.inputIsAfterRange:
        return _buildAmountError(
          _localizations.maxTempTooLarge, 
          HabitValidator.maxTemperatureRange.max.toInt(),
          units: _localizations.degrees
        );
      default:
        print("Unhandled habits max temperature validation message for error: $temperatureError");
        return null;
    }
  }

  String? forTotalDailyHours(NumericInputError totalHoursError) {
    switch (totalHoursError) {
      case NumericInputError.none: return null;
      case NumericInputError.isNaN: return _localizations.totalAvgHoursIsNaN;
      case NumericInputError.isEmptyWhenRequired: return _localizations.totalAvgHoursIsRequired;
      case NumericInputError.inputIsBeforeRange: 
        return _buildAmountError(
          _localizations.totalAvgHoursTooSmall, 
          HabitValidator.dailyHoursRange.min.toInt(),
          units: _localizations.hours
        );
      case NumericInputError.inputIsAfterRange:
        return _buildAmountError(
          _localizations.totalAvgHoursTooLarge, 
          HabitValidator.dailyHoursRange.max.toInt(),
          units: _localizations.hours
        );
      default:
        print("Unhandled Habits validation message for error: $totalHoursError");
        return null;
    }
  }
}