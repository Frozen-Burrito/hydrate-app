import 'package:flutter/widgets.dart';

import 'package:hydrate_app/src/models/activity_record.dart';
import 'package:hydrate_app/src/models/enums/error_types.dart';
import 'package:hydrate_app/src/models/validators/range.dart';
import 'package:hydrate_app/src/models/validators/validator.dart';

/// Define los valores válidos de un [ActivityRecord] y contiene varios métodos
/// para validar un valor específico de cada campo.
class ActivityValidator extends Validator{

  const ActivityValidator();

  static const Range titleLengthRange = Range(max: 40);
  static const Range distanceInMetersRange = Range(max: 30000);
  static const Range durationInMinutesRange = Range(max: 60 * 12);
  static const Range kcalPerActivityRange = Range(max: 2500);

  static const Set<String> requiredFields = <String>{};

  @override
  bool isFieldRequired(String fieldName) => requiredFields.contains(fieldName);
  
  @override
  bool isValid(Object? instanceToValidate) {
    if (instanceToValidate is! ActivityRecord) {
      throw UnsupportedError("An ActivityValidator cannot validate a value that is not an instance of ActivityRecord");
    }

    final isTitleValid = validateTitle(instanceToValidate.title) == TextLengthError.none;
    final isDurationValid = validateDurationInMinutes(instanceToValidate.duration) == NumericInputError.none;
    final isDistanceValid = validateDistanceInMeters(instanceToValidate.distance) == NumericInputError.none;
    final isKcalValid = validateKcalConsumed(instanceToValidate.kiloCaloriesBurned) == NumericInputError.none; 

    return isTitleValid && isDurationValid && isDistanceValid && isKcalValid;
  }

  /// Valida un valor para el título de un [ActivityRecord].
  /// 
  /// Un título de un [ActivityRecord] es válido si [inputValue.characters.length]
  /// no supera [titleLengthRange.max]. Puede ser un [String] vacío, porque es un  
  /// campo opcional.
  TextLengthError validateTitle(String? inputValue) {

    final isTitleRequired = isFieldRequired(ActivityRecord.titlePropName);

    TextLengthError titleError = TextLengthError.none;

    if (inputValue != null) {
      if (isTitleRequired && inputValue.characters.isEmpty) {
        // Si el titulo es un campo obligatorio y es un string 
        // vacio, el titulo no es valido.
        titleError = TextLengthError.textIsEmptyError;
      } else if (inputValue.characters.length > titleLengthRange.max) {
        // Si el título no es requerido o no está vacío, pero 
        // tiene más caracteres que los permitidos, el título
        // no es válido.
        titleError = TextLengthError.textExceedsCharLimit;
      }
    }

    return titleError;
  }

  /// Valida un valor para la distancia de un [ActivityRecord].
  /// 
  /// La distancia recorrida de un [ActivityRecord] es válida si es un número o 
  /// puede ser convertida en uno, y si su valor está incluido en 
  /// [distanceInMetersRange].
  /// 
  /// NOTA: la distancia siempre es recibida como un valor con hasta dos 
  /// posiciones decimales, en kilómetros. Para validarla en metros, se 
  /// multiplica por 1000 y se convierte en un entero.
  NumericInputError validateDistanceInMeters(Object? inputValue, { bool includesUnits = false }) {
    // Intentar convertir a un valor decimal, que represente kilometros.
    double? distanceInKm = Validator.tryParseInputAsDouble(
      inputValue,
      indexInString: includesUnits ? 0 : -1,
    );

    var distanceError = NumericInputError.none;

    if (distanceInKm != null) {
      // Validar el rango de la distancia del input.
      distanceError = Validator.validateRange(
        (distanceInKm * 1000).toInt(),
        range: distanceInMetersRange,
      );

    } else {
      // El valor no es un número, o no puede ser convertido a uno.
      distanceError = NumericInputError.isNaN;
    }

    return distanceError;
  }

  /// Valida un valor para la duración, en minutos, de un [ActivityRecord].
  /// 
  /// La duración de un [ActivityRecord] es válida si es un número o puede ser 
  /// convertida en uno, y si su valor está incluido en [durationInMinutesRange].
  /// 
  /// NOTA: La duración usa valores enteros, en minutos.
  NumericInputError validateDurationInMinutes(Object? inputValue, { bool includesUnits = false }) {
    int? durationInMinutes = Validator.tryParseInputAsInt(
      inputValue,
      indexInString: includesUnits ? 0 : -1,
    );

    var durationError = NumericInputError.none;

    if (durationInMinutes != null) {
      // Validar el rango de la duracion del input.
      durationError = Validator.validateRange(
        durationInMinutes,
        range: durationInMinutesRange,
      );

    } else if ((inputValue is! String) || (inputValue.trim().isNotEmpty)) {
      durationError = NumericInputError.isNaN;
    }

    return durationError;
  }

  /// Verifica que la cantidad de __kilocalorías consumidas__ especificada en 
  /// [inputValue] sea válida.
  /// 
  /// [inputValue] es un valor de kCal válido cuando es (o puede ser 
  /// convertido en) un número entero y está en el rango especificado:
  /// 
  /// [kcalPerActivityRange.min] <= [inputValue] <= [kcalPerActivityRange.max]
  NumericInputError validateKcalConsumed(Object? inputValue, { bool includesUnits = false }) {
    int? kcal = Validator.tryParseInputAsInt(
      inputValue,
      indexInString: includesUnits ? 0 : -1,
    );

    var kCalError = NumericInputError.none;

    if (kcal != null) {
      // Validar el rango de las kilocalorias quemadas del input.
      kCalError = Validator.validateRange(
        kcal,
        range: kcalPerActivityRange,
      );

    } else {
      kCalError = NumericInputError.isNaN;
    }

    return kCalError;
  }
}