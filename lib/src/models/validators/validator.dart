import 'package:hydrate_app/src/models/enums/error_types.dart';
import 'package:hydrate_app/src/models/validators/range.dart';

abstract class Validator {

  const Validator();

  bool isFieldRequired(String fieldName);

  bool isValid(Object? instanceToValidate);

  static int? tryParseInputAsInt(Object? inputValue, {int indexInString = -1,}) {

    int? value;

    if (inputValue is num) {
      // Convertir directamente el valor de entrada a un entero.
      value = inputValue.toInt();
    } else if (inputValue is String) {
      // Intentar interpretar el valor de entrada, que es un String, 
      // como un número entero. Puede que sea necesario subdividir el 
      // String.
      String inputAsString = indexInString > -1
        ? inputValue.split(" ")[indexInString] 
        : inputValue;

      value = int.tryParse(inputAsString);
    } 

    return value;
  }

  static double? tryParseInputAsDouble(Object? inputValue, {int indexInString = -1, }) {
    double? value;

    if (inputValue is double) {
      // El valor de entrada ya es un double.
      value = inputValue;
    } else if (inputValue is String) {
      // Intentar interpretar el valor de entrada, que es un String, 
      // como un número double. Puede que sea necesario subdividir el 
      // String.
      String inputAsString = indexInString > -1
        ? inputValue.split(" ")[indexInString] 
        : inputValue;

      value = double.tryParse(inputAsString);
    } 

    return value;
  }

  static NumericInputError validateRange(num value, { required Range range }) {

    final rangeComparison = range.compareTo(value);

    if (rangeComparison.isNegative) {
      return NumericInputError.inputIsBeforeRange;
    }

    if (rangeComparison > 0) {
      return NumericInputError.inputIsAfterRange;
    }

    return NumericInputError.none;
  }
}