import 'package:flutter/widgets.dart';

import 'package:hydrate_app/src/models/enums/error_types.dart';
import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/models/validators/range.dart';
import 'package:hydrate_app/src/models/validators/validator.dart';

/// Define los valores válidos de un [UserProfile] y contiene varios métodos
/// para validar un valor específico de cada campo.
class ProfileValidator extends Validator {

  const ProfileValidator();

  static const Range firstNameLengthRange = Range(max: 64);
  static const Range lastNameLengthRange = Range(max: 64);
  static const Range heightRange = Range(min: 0.5, max: 3.5);
  static const Range weightRange = Range(min: 20.0, max: 200.0);

  static const Range coinAmountRange = Range(min: 0, max: 9999);

  static const Set<String> requiredFields = <String>{};

  @override
  bool isFieldRequired(String fieldName) => requiredFields.contains(fieldName);

  @override
  bool isValid(Object? instanceToValidate) {
    if (instanceToValidate is! UserProfile) {
      throw UnsupportedError("A ProfileValidator cannot validate a value that is not an instance of UserProfile");
    }

    final isTitleValid = validateFirstName(instanceToValidate.firstName) == TextLengthError.none;
    final isDurationValid = validateLastName(instanceToValidate.lastName) == TextLengthError.none;
    final isDistanceValid = validateHeight(instanceToValidate.height.toString()) == NumericInputError.none;
    final isKcalValid = validateWeight(instanceToValidate.weight.toString()) == NumericInputError.none; 

    return isTitleValid && isDurationValid && isDistanceValid && isKcalValid;
  }

  /// Verifica que [inputName] sea un string con longitud en el rango [firstNameLengthRange].
  TextLengthError validateFirstName(String? inputName) {

    final isFirstNameRequired = isFieldRequired(UserProfile.firstNameFieldName);

    TextLengthError firstNameError = TextLengthError.none;

    if (inputName != null) {
      if (isFirstNameRequired && inputName.characters.isEmpty) {
        // El nombre es obligatorio, pero no tiene un valor (el stirng está vacío).
        firstNameError = TextLengthError.textIsEmptyError;
      } else if (inputName.characters.length > firstNameLengthRange.max) {
        // El nombre sobrepasa el límite de caracteres.
        firstNameError = TextLengthError.textExceedsCharLimit;
      }
    }

    return firstNameError;
  }

  /// Verifica que [inputName] sea un string con longitud menor a 50.
  TextLengthError validateLastName(String? inputValue) {

    TextLengthError lastNameError = TextLengthError.none;

    if (inputValue != null) {

      final isLastNameRequired = isFieldRequired(UserProfile.firstNameFieldName);

      if (isLastNameRequired && inputValue.characters.isEmpty) {
        // El nombre es obligatorio, pero no tiene un valor (el stirng está vacío).
        lastNameError = TextLengthError.textIsEmptyError;
      } else if (inputValue.characters.length > lastNameLengthRange.max) {
        // El nombre sobrepasa el límite de caracteres.
        lastNameError = TextLengthError.textExceedsCharLimit;
      }
    }

    return lastNameError;
  }

  /// Verifica que [inputHeight] pueda convertirse a número decimal y esté en el
  /// rango requerido.
  NumericInputError validateHeight(Object? inputValue) {

    NumericInputError heightError = NumericInputError.none;

    if (inputValue != null) {

      final parsedHeight = Validator.tryParseInputAsDouble(inputValue);

      if (parsedHeight != null) {
        heightError = Validator.validateRange(
          parsedHeight, 
          range: heightRange,
        );

      } else {
        heightError = NumericInputError.isNaN;
      }
    }

    return heightError;
  }

  /// Verifica que [inputWeight] pueda convertirse a número decimal y esté en el
  /// rango requerido.
  NumericInputError validateWeight(Object? inputValue) {
    
    NumericInputError weightError = NumericInputError.none;

    if (inputValue != null) {

      final parsedWeight = Validator.tryParseInputAsDouble(inputValue);

      if (parsedWeight != null) {
        weightError = Validator.validateRange(
          parsedWeight, 
          range: weightRange,
        );

      } else {
        weightError = NumericInputError.isNaN;
      }
    }

    return weightError;
  }
}