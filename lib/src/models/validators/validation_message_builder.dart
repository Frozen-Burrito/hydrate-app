import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

import "package:hydrate_app/src/models/enums/error_types.dart";
import "package:hydrate_app/src/models/validators/activity_validator.dart";
import 'package:hydrate_app/src/models/validators/profile_validator.dart';

import "package:hydrate_app/src/utils/auth_validators.dart";

class ValidationMessageBuilder {

  ValidationMessageBuilder.of(BuildContext context) 
    : _localizations = AppLocalizations.of(context)!;

  //TODO: Implement i18n validation messages.
  final AppLocalizations _localizations;

  static const String usernameIsRequiredMsg = "El nombre de usuario es obligatorio";
  static const String usernameTooShortMsg = "El usuario debe tener más de 4 letras o números";
  static const String usernameTooLongMsg = "El usuario debe tener menos de 20 letras o números";
  static const String emailIsRequiredMsg = "El correo electrónico es obligatorio";
  static const String incorrectEmailFormatMsg = "El correo no tiene un formato válido";
  static const String incorrectUsernameFormatMsg = "El usuario no tiene un formato válido";

  static const String passwordIsRequiredMsg = "La contraseña es obligatoria";
  static const String passwordTooShortMsg = "La contraseña debe tener más de 8 caracteres";
  static const String passwordTooLongMsg = "La contraseña debe tener menos de 40 caracteres";
  static const String passwordRequiresSymbolsMsg = "La contraseña debe tener un número y una mayúscula";
  static const String passwordConfirmIsRequiredMsg = "La confirmación de contraseña es obligatoria";
  static const String passwordConfirmDoesNotMatchMsg = "La confirmación de contraseña no coincide";

  static final Map<String, String> activityMessages = Map.unmodifiable({
    "titleTooLong": "El título debe tener menos de ${ActivityValidator.titleLengthRange.max} caracteres",
    "distanceIsNegative": "La distancia debe ser mayor a ${ActivityValidator.distanceInMetersRange.min} m",
    "distanceExceedsRange": "La distancia debe ser menor a ${ActivityValidator.distanceInMetersRange.max} m",
    "durationIsNegative": "La duración debe ser mayor a ${ActivityValidator.durationInMinutesRange.min} minutos",
    "durationExceedsRange": "La duración debe ser menor a ${ActivityValidator.durationInMinutesRange.max ~/ 60} horas",
    "kCalIsNegative": "Las cantidad de kCal debe ser mayor a ${ActivityValidator.kcalPerActivityRange.min}",
    "kCalExceedsRange": "La cantidad de kilocalorías debe ser menore a ${ActivityValidator.kcalPerActivityRange.max}",
  });

  static final Map<String, String> profileMessages = Map.unmodifiable({
    "firstNameTooLong": "El nombre debe tener menos de ${ProfileValidator.firstNameLengthRange.max} caracteres",
    "lastNameTooLong": "Los apellidos deben tener menos de ${ProfileValidator.lastNameLengthRange.max} caracteres",
    "heightIsNaN": "La estatura debe ser un número",
    "heightIsTooSmall": "La estatura debe ser mayor a ${ProfileValidator.heightRange.min} metros",
    "heightIsTooLarge": "La estatura debe ser menor a ${ProfileValidator.heightRange.max} metros",
    "weightIsNaN": "El peso debe ser un número",
    "weightIsTooSmall": "El peso debe ser mayor a ${ProfileValidator.heightRange.min} kilogramos",
    "weightIsTooLarge": "El peso debe ser mayor a ${ProfileValidator.heightRange.max} kilogramos",
  });

  String? messageForUsername(UsernameError usernameError) {

    switch(usernameError) {
      case UsernameError.none: return null;
      case UsernameError.noUsernameProvided: return usernameIsRequiredMsg;
      case UsernameError.noEmailProvided: return emailIsRequiredMsg;
      case UsernameError.incorrectEmailFormat: return incorrectEmailFormatMsg;
      case UsernameError.usernameTooShort: return usernameTooShortMsg;
      case UsernameError.usernameTooLong: return usernameTooLongMsg;
      case UsernameError.incorrectUsernameFormat: return incorrectUsernameFormatMsg;
      default: 
        print("Unhandled username/email validation message for error: $usernameError");
        return "unkown error";
    }
  } 

  String? messageForPassword(PasswordError passwordError) {
    
    switch(passwordError) {
      case PasswordError.none: return null;
      case PasswordError.noPasswordProvided: return passwordIsRequiredMsg;
      case PasswordError.passwordTooShort: return passwordTooShortMsg;
      case PasswordError.passwordTooLong: return passwordTooLongMsg;
      case PasswordError.requiresSymbols: return passwordRequiresSymbolsMsg;
      case PasswordError.noPasswordConfirm: return passwordConfirmIsRequiredMsg;
      case PasswordError.passwordsDoNotMatch: return passwordConfirmDoesNotMatchMsg;
      default: 
        print("Unhandled password validation message for error: $passwordError");
        return "unkown error";
    }
  } 

  String? forActivityTitle(TextLengthError titleError) {
    switch (titleError) {
      case TextLengthError.textExceedsCharLimit:
        return activityMessages["titleTooLong"];
      default: return null;
    }
  }

  String? forActivityDuration(NumericInputError durationError) {
    switch (durationError) {
      case NumericInputError.none: return null;
      case NumericInputError.inputIsBeforeRange: return activityMessages["durationIsNegative"];
      case NumericInputError.inputIsAfterRange: return activityMessages["durationExceedsRange"];
      default:
        print("Unhandled activity record duration validation message for error: $durationError");
        return null;
    }
  }

  String? forActivityDistance(NumericInputError distanceError) {
    switch (distanceError) {
      case NumericInputError.none: return null;
      case NumericInputError.inputIsBeforeRange: return activityMessages["distanceIsNegative"];
      case NumericInputError.inputIsAfterRange: return activityMessages["distanceExceedsRange"];
      default:
        print("Unhandled activity record distance validation message for error: $distanceError");
        return null;
    }
  }

  String? forActivityKcals(NumericInputError kCalsError) {
    switch (kCalsError) {
      case NumericInputError.none: return null;
      case NumericInputError.inputIsBeforeRange: return activityMessages["kCalIsNegative"];
      case NumericInputError.inputIsAfterRange: return activityMessages["kCalExceedsRange"];
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
        return profileMessages["firstNameTooLong"];
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
        return profileMessages["lastNameTooLong"];
      default:
        print("Unhandled profile last name validation message for error: $lastNameError");
        return null;
    }
  }

  String? forHeight(NumericInputError heightError) {
    switch (heightError) {
      case NumericInputError.none: return null;
      case NumericInputError.isNaN: return profileMessages["heightIsNaN"];
      case NumericInputError.inputIsBeforeRange: return profileMessages["heightIsTooSmall"];
      case NumericInputError.inputIsAfterRange: return profileMessages["heightIsTooLarge"];
      default:
        print("Unhandled profile height validation message for error: $heightError");
        return null;
    }
  }

  String? forWeight(NumericInputError weightError) {
    switch (weightError) {
      case NumericInputError.none: return null;
      case NumericInputError.isNaN: return profileMessages["weightIsNaN"];
      case NumericInputError.inputIsBeforeRange: return profileMessages["weightIsTooSmall"];
      case NumericInputError.inputIsAfterRange: return profileMessages["weightIsTooLarge"];
      default:
        print("Unhandled profile weight validation message for error: $weightError");
        return null;
    }
  }
}