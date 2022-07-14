import 'package:flutter_test/flutter_test.dart';

import 'package:hydrate_app/src/utils/string_utils.dart';

void main() {

  group("Utilidades de Strings", () {

    test("toCamelCase() transforma un string a camelCase", () {
      // Arrange
      const initialString = "hola_mundo_saludos";
      const expected = "holaMundoSaludos";

      // Act
      final camelCaseString = initialString.toCamelCase();

      // Assert
      expect(camelCaseString, expected);
    });

    test("toCamelCase() no modifica un string que ya es camelCase", () {
      // Arrange
      const initialString = "unStringEnCamelCase";
      const expected = "unStringEnCamelCase";

      // Act
      final camelCaseString = initialString.toCamelCase();

      // Assert
      expect(camelCaseString, expected);
    });

    test("toCamelCase() puede transformar un string con espacios", () {
      // Arrange
      const initialString = "un string que Tiene espacios_y_guiones";
      const expected = "unStringQueTieneEspaciosYGuiones";

      // Act
      final camelCaseString = initialString.toCamelCase();

      // Assert
      expect(camelCaseString, expected);
    });
  });
}