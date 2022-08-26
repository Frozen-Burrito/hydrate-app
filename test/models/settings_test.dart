import "package:flutter_test/flutter_test.dart";

import 'package:hydrate_app/src/models/settings.dart';

void main() {
  group("Test settings model", () {
    test("Using Settings.from() creates a new Settings instance with other's values", () {
      // Arrange
      final original = Settings.defaults();
      original.shouldContributeData = true;

      // Act
      final copyResult = Settings.from(original);

      // Assert
      expect(copyResult, original);
    });
  });

  group("Common object method overrides", () {
    test("Setings.toString() returns a non-empty string representation", () {
      // Arrange
      final settings = Settings.defaults();

      // Act
      final settingsAsString = settings.toString();

      // Assert
      expect(settingsAsString.isNotEmpty, isTrue);
    });

    test("Settings.toString() does not return the default string representation of the object", () {
      // Arrange
      const defaultStrValue = "Instance of 'Settings'";
      final settings = Settings.defaults();

      // Act
      final settingsAsString = settings.toString();

      // Assert
      expect(settingsAsString, isNot(defaultStrValue));
    });

    test("Article == operator implementation is reflexive", () {
      // Arrange
      final a = Settings.defaults();

      // Act
      final comparisonResult = a == a;

      // Assert
      expect(comparisonResult, isTrue);
    });

    test("Settings == operator implementation is symmetric", () {
      // Arrange
      final a = Settings.defaults();
      final b = Settings.defaults();

      // Act
      final result = a == b;
      final inverseOrderResult = b == a;

      // Assert
      expect(result, inverseOrderResult);
    });

    test("Settings == operator implementation is transitive", () {
      // Arrange
      final a = Settings.defaults();
      final b = Settings.defaults();
      final c = Settings.defaults();

      final expectedResult = (a == b) && (b == c);

      // Act
      final transitiveResult = a == c;

      // Assert
      expect(transitiveResult, expectedResult);
    });

    test("Comparing two article references with equal identities returns true", () {
      // Arrange
      final a = Settings.defaults();
      final b = a;

      // Act
      final comparisonResult = a == b;

      // Assert
      expect(comparisonResult, isTrue);
    });

    test("Comparing two Settings instances with equal values returns true", () {
      // Arrange
      final a = Settings.defaults();
      final b = Settings.defaults();

      // Act
      final comparisonResult = a == b;

      // Assert
      expect(comparisonResult, isTrue);
    });

    test("Comparing two Settings instances with different values returns false", () {
      // Arrange
      final a = Settings.defaults();
      final b = Settings.defaults();

      // Act
      a.areWeeklyFormsEnabled = !b.areWeeklyFormsEnabled;
      final comparisonResult = a == b;

      // Assert
      expect(comparisonResult, isFalse);
    });
  });
}

