import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrate_app/src/models/activity_record.dart';
import 'package:hydrate_app/src/models/activity_type.dart';
import 'package:hydrate_app/src/models/enums/error_types.dart';
import 'package:hydrate_app/src/models/map_options.dart';
import 'package:hydrate_app/src/models/validators/activity_validator.dart';
import 'package:hydrate_app/src/utils/google_fit_activity_type.dart';

void main() {

  group('Comparaciones', () {
    test('isSimilarTo() retorna true cuando las actividades son similares.', () {
      // Arrange
      final tomorrowWithSmallDiff = DateTime.now()
          .add(const Duration( days: 1, minutes: 9));

      final walking =  ActivityType(id: 0, mets: 0.0, averageSpeedKmH: 3.2, googleFitActivityType: GoogleFitActivityType.walking);

      final activityA = ActivityRecord(
        title: '', 
        date: DateTime.now(), 
        duration: 14, 
        kiloCaloriesBurned: 240,
        activityType: walking, 
        profileId: 0
      );

      final activityB = ActivityRecord(
        title: '', 
        date: tomorrowWithSmallDiff, 
        duration: 21, 
        kiloCaloriesBurned: 217,
        activityType: walking, 
        profileId: 0
      );
      
      // Act
      final actual = activityA.isSimilarTo(activityB); 

      // Assert
      expect(actual, isTrue);
    });

    test('isSimilarTo() retorna false cuando las actividades tienen fechas distintas.', () {
      // Arrange
      final differentDate = DateTime.now()
        .subtract(const Duration( days: 3, hours: 8, minutes: 15));

      final walking =  ActivityType(id: 0, mets: 0.0, averageSpeedKmH: 3.2, googleFitActivityType: GoogleFitActivityType.walking);

      final activityA = ActivityRecord(
        title: '', 
        date: DateTime.now(), 
        duration: 14, 
        kiloCaloriesBurned: 240,
        activityType: walking, 
        profileId: 0
      );

      final activityB = ActivityRecord(
        title: '', 
        date: differentDate, 
        duration: 21, 
        kiloCaloriesBurned: 217,
        activityType: walking, 
        profileId: 0
      );
      
      // Act
      final actual = activityA.isSimilarTo(activityB); 

      // Assert
      expect(actual, isFalse);
    });
  });

  group("From y to Map", () {
    test("ActivityRecord toMap() retorna un mapa con todos los atributos de ActivityRecord", () {
      // Arrange
      final activityRecord = ActivityRecord.uncommited();

      // Para que el mapa de la entidad incluya su id.
      activityRecord.id = 0;

      final expectedMap = Map.unmodifiable(<String, Object?>{
        "id": 0,
        "titulo": "",
        "fecha": activityRecord.date.toIso8601String(),
        "duracion": 0,
        "distancia": 0.0,
        "kilocalorias_quemadas": 0,
        "al_aire_libre": true,
        "es_rutina": false,
        "tipo_actividad": ActivityType.uncommited(),
        "id_perfil": -1,
      });

      // Act
      final actualMap = activityRecord.toMap();

      // Assert
      expect(actualMap.isNotEmpty, isTrue);
      expect(actualMap, expectedMap);
    });

    test("ActivityRecord.toMap(), con useCamelCasePropNames = true, usa nombres en camelCase", () {
      // Arrange
      final activityRecord = ActivityRecord.uncommited();

      // Para que el mapa de la entidad incluya su id.
      activityRecord.id = 0;

      final expectedMap = Map.unmodifiable(<String, Object?>{
        "id": -1,
        "titulo": "",
        "fecha": activityRecord.date.toIso8601String(),
        "duracion": 0,
        "distancia": 0.0,
        "kilocaloriasQuemadas": 0,
        "alAireLibre": true,
        "esRutina": false,
        "tipoActividad": ActivityType.uncommited(),
        "idPerfil": -1,
      });

      // Act
      final actualMap = activityRecord.toMap(options: const MapOptions(
        useCamelCasePropNames: true
      ));

      // Assert
      expect(actualMap.keys, expectedMap.keys);
    });

    test("ActivityRecord.toMap(), subEntityMappingType = EntityMappingType.idOnly, solo incluye el ID ActivityType", () {
      // Arrange
      final activityRecord = ActivityRecord.uncommited();

      // Act
      final actualMap = activityRecord.toMap(options: const MapOptions(
        subEntityMappingType: EntityMappingType.idOnly
      ));

      // Assert
      expect(actualMap.containsKey("tipo_actividad"), isFalse);
      expect(actualMap.containsValue(ActivityRecord.uncommited()), isFalse);
      
      expect(actualMap["id_tipo_actividad"] is int, isTrue);
    });
  });

  group("ActivityRecord serialization to JSON", () {
    test("ActivityRecord.fromJson() correctly maps a JSON representation to an instance", () {
      // Arrange
      final testActType = ActivityType(id: 1, mets: 0.0, googleFitActivityType: 0);
      final expected = ActivityRecord(
        id: 5, 
        title: "Correr en la mañana",
        date: DateTime.parse("2022-10-03T08:22:00.0000000"),
        duration: 28,
        distance: 3.7,
        kiloCaloriesBurned: 0,
        doneOutdoors: false,
        profileId: 1,
        activityType: testActType,
      );

      final jsonAttributes = ActivityRecord.jsonAttributes.values;
      final testJsonValues = <Object?>[ 
        expected.id, expected.title, expected.date.toIso8601String(), expected.duration, 
        expected.distance, expected.kiloCaloriesBurned, expected.doneOutdoors, expected.routine, 
        expected.profileId, expected.activityType.id
      ];

      final originalJson = Map.fromIterables(jsonAttributes, testJsonValues);

      // Act 
      final parsedActivityRecord = ActivityRecord.fromJson(originalJson, activityTypes: [ testActType ]);

      // Assert
      expect(parsedActivityRecord, expected);
    });


    test("ActivityRecord.toJson() produces a correct JSON representation of the object", () {
      // Arrange
      final testActType = ActivityType(id: 1, mets: 0.0, googleFitActivityType: 0);
      final activityRecord = ActivityRecord(
        id: 5, 
        title: "Correr en la mañana",
        date: DateTime.parse("2022-10-03T08:22:00.0000000"),
        duration: 28,
        distance: 3.7,
        kiloCaloriesBurned: 0,
        doneOutdoors: false,
        profileId: 1,
        activityType: testActType,
      );

      final jsonAttributes = ActivityRecord.jsonAttributes.values;
      final testJsonValues = <Object?>[ 
        activityRecord.id, activityRecord.title, activityRecord.date.toIso8601String(), activityRecord.duration, 
        activityRecord.distance, activityRecord.kiloCaloriesBurned, activityRecord.doneOutdoors, activityRecord.routine, 
        activityRecord.profileId, activityRecord.activityType.id
      ];

      final Map<String, Object?> expected = Map.fromIterables(jsonAttributes, testJsonValues);

      // Act 
      final serializedActivityRecord = activityRecord.toJson();

      // Assert
      expect(mapEquals(serializedActivityRecord, expected), isTrue);
    });

    test("ActivityRecord.toJson() only includes the fields specified in attributes, if attributes is not null", () {
      // Arrange
      final testActType = ActivityType(id: 1, mets: 0.0, googleFitActivityType: 0);
      final activityRecord = ActivityRecord(
        id: 5, 
        title: "Correr en la mañana",
        date: DateTime.parse("2022-10-03T08:22:00.0000000"),
        duration: 28,
        distance: 3.7,
        kiloCaloriesBurned: 0,
        doneOutdoors: false,
        profileId: 1,
        activityType: testActType,
      );

      final selectedAttributes = <String>[
        ActivityRecord.jsonAttributes[ActivityRecord.idPropName]!,
        ActivityRecord.jsonAttributes[ActivityRecord.actTypeIdPropName]!,
        ActivityRecord.jsonAttributes[ActivityRecord.datePropName]!,
      ];

      // Act 
      final serializedActivityRecord = activityRecord.toJson(attributes: selectedAttributes);

      // Assert
      expect(serializedActivityRecord.length, selectedAttributes.length);
      expect(serializedActivityRecord.keys, containsAll(selectedAttributes));
    });

    test("ActivityRecord.toJson() creates a map with all the fields, if attributes is null or empty", () {
      // Arrange
      final testActType = ActivityType(id: 1, mets: 0.0, googleFitActivityType: 0);
      final activityRecord = ActivityRecord(
        id: 5, 
        title: "Correr en la mañana",
        date: DateTime.parse("2022-10-03T08:22:00.0000000"),
        duration: 28,
        distance: 3.7,
        kiloCaloriesBurned: 0,
        doneOutdoors: false,
        profileId: 1,
        activityType: testActType,
      );

      final expectedAttributes = ActivityRecord.jsonAttributes.values;

      // Act 
      final serializedActivityRecord = activityRecord.toJson(attributes: List<String>.empty());

      // Assert
      expect(serializedActivityRecord.length, expectedAttributes.length);
      expect(serializedActivityRecord.keys, containsAll(expectedAttributes));
    });
  });

  group('Validaciones para el título de un ActivityRecord', () {

    test('validateTitle(input) retorna TextLengthError.none si input es un String vacio', () {
      // Arrange
      const String input = "";
      const expected = TextLengthError.none;
      const  validator = ActivityValidator();

      // Act
      final result = validator.validateTitle(input);

      // Assert
      expect(result, expected);
    });

    test('validateTitle(input) retorna TextLengthError.textExceedsCharLimit si input tiene mas caracteres que titleLengthRange.max', () {
      // Arrange
      final String input = List.generate(41, (_) => "+").join();
      const expected = TextLengthError.textExceedsCharLimit;
      const  validator = ActivityValidator();

      // Act
      final result = validator.validateTitle(input);

      // Assert
      expect(result, expected); 
    });
  });

  group('Validaciones para la distancia de un ActivityRecord', () {

    const validator = ActivityValidator();

    test('validateDistanceInMeters(input) retorna NumericInputError.isNaN si input no puede convertirse en un número', () {
      // Arrange
      const inputNaN = Object();
      const expectedError = NumericInputError.isNaN;

      // Act
      final result = validator.validateDistanceInMeters(inputNaN);

      // Assert
      expect(result, expectedError);
    });

    test('validateDistanceInMeters(input) retorna NumericInputError.none si input es un String sin unidades que puede convertirse en número double', () {
      // Arrange
      const input = '29.0';
      const expectedError = NumericInputError.none;

      // Act
      final result = validator.validateDistanceInMeters(input);

      // Assert
      expect(result, expectedError);
    });

    test('validateDistanceInMeters(input, false) retorna NumericInputError.isNaN si input es un String con un número válido seguido de unidades', () {
      // Arrange
      const input = '29.0 km';
      const expectedError = NumericInputError.isNaN;

      // Act
      final result = validator.validateDistanceInMeters(input, includesUnits: false);

      // Assert
      expect(result, expectedError);
    });

    test('validateDistanceInMeters(input, true) retorna NumericInputError.none si input es un String con un número válido seguido de unidades', () {
      // Arrange
      const input = '29.0 km';
      const expectedError = NumericInputError.none;

      // Act
      final result = validator.validateDistanceInMeters(input, includesUnits: true);

      // Assert
      expect(result, expectedError);
    });

    test('validateDistanceInMeters(input) retorna NumericInputError.inputIsBeforeRange si input es un número negativo', () {
      // Arrange
      const double negativeInput = -0.1;
      const expectedError = NumericInputError.inputIsBeforeRange;

      // Act
      final result = validator.validateDistanceInMeters(negativeInput);

      // Assert
      expect(result, expectedError);
    });

    test('validateDistanceInMeters(input) retorna NumericInputError.none si input es igual a distanceInMetersRange.min', () {
      // Arrange
      final inputInRange = ActivityValidator.distanceInMetersRange.min.toDouble();
      const expectedError = NumericInputError.none;

      // Act
      final result = validator.validateDistanceInMeters(inputInRange);

      // Assert
      expect(result, expectedError);
    });

    test('validateDistanceInMeters(input) retorna NumericInputError.inputIsAfterRange si input es mayor a distanceInMetersRange.max', () {
      // Arrange
      final negativeInput = ActivityValidator.distanceInMetersRange.max.toDouble() + 0.1;
      const expectedError = NumericInputError.inputIsAfterRange;

      // Act
      final result = validator.validateDistanceInMeters(negativeInput);

      // Assert
      expect(result, expectedError);
    });

    test('validateDistanceInMeters(input) retorna NumericInputError.none si input es igual a distanceInMetersRange.max', () {
      // Arrange
      final inputInRange = ActivityValidator.distanceInMetersRange.max.toDouble() / 1000;
      const expectedError = NumericInputError.none;

      // Act
      final result = validator.validateDistanceInMeters(inputInRange);

      // Assert
      expect(result, expectedError);
    });
  });

  group('Validaciones para la duración en minutos de un ActivityRecord', () {

    const validator = ActivityValidator();

    test('validateDurationInMinutes(input) retorna NumericInputError.isNaN si input no puede convertirse en un número', () {
      // Arrange
      const inputNaN = Object();
      const expectedError = NumericInputError.isNaN;

      // Act
      final result = validator.validateDurationInMinutes(inputNaN);

      // Assert
      expect(result, expectedError);
    });

    test('validateDurationInMinutes(input) retorna NumericInputError.none si input es un String sin unidades que puede convertirse en número', () {
      // Arrange
      const input = '15';
      const expectedError = NumericInputError.none;

      // Act
      final result = validator.validateDurationInMinutes(input);

      // Assert
      expect(result, expectedError);
    });

    test('validateDurationInMinutes(input, false) retorna NumericInputError.isNaN si input es un String con un número válido, seguido de unidades', () {
      // Arrange
      const input = '15 m';
      const expectedError = NumericInputError.isNaN;

      // Act
      final result = validator.validateDurationInMinutes(input, includesUnits: false);

      // Assert
      expect(result, expectedError);
    });

    test('validateDurationInMinutes(input, true) retorna NumericInputError.none si input es un String con un número válido seguido de unidades', () {
      // Arrange
      const input = '15 m';
      const expectedError = NumericInputError.none;

      // Act
      final result = validator.validateDurationInMinutes(input, includesUnits: true);

      // Assert
      expect(result, expectedError);
    });

    test('validateDurationInMinutes(input) retorna NumericInputError.inputIsBeforeRange si input es un número menor a durationInMinutesRange.min', () {
      // Arrange
      final negativeInput = ActivityValidator.durationInMinutesRange.min - 1;
      const expectedError = NumericInputError.inputIsBeforeRange;

      // Act
      final result = validator.validateDurationInMinutes(negativeInput);

      // Assert
      expect(result, expectedError);
    });

    test('validateDurationInMinutes(input) retorna NumericInputError.none si input es igual a durationInMinutesRange.min', () {
      // Arrange
      final inputInRange = ActivityValidator.distanceInMetersRange.min;
      const expectedError = NumericInputError.none;

      // Act
      final result = validator.validateDurationInMinutes(inputInRange);

      // Assert
      expect(result, expectedError);
    });

    test('validateDurationInMinutes(input) retorna NumericInputError.inputIsAfterRange si input es mayor a durationInMinutesRange.max', () {
      // Arrange
      final negativeInput = ActivityValidator.durationInMinutesRange.max + 1;
      const expectedError = NumericInputError.inputIsAfterRange;

      // Act
      final result = validator.validateDurationInMinutes(negativeInput);

      // Assert
      expect(result, expectedError);
    });

    test('validateDurationInMinutes(input) retorna NumericInputError.none si input es igual a durationInMinutesRange.max', () {
      // Arrange
      final inputInRange = ActivityValidator.durationInMinutesRange.max;
      const expectedError = NumericInputError.none;

      // Act
      final result = validator.validateDurationInMinutes(inputInRange);

      // Assert
      expect(result, expectedError);
    });
  });

  group('Validaciones para cantidad de kilocalorías quemadas en un ActivityRecord', () {

    const validator = ActivityValidator();

    test('validateKcalConsumed(input) retorna NumericInputError.isNaN si input no puede convertirse en un número', () {
      // Arrange
      const inputNaN = Object();
      const expectedError = NumericInputError.isNaN;

      // Act
      final result = validator.validateKcalConsumed(inputNaN);

      // Assert
      expect(result, expectedError);
    });

    test('validateKcalConsumed(input) retorna NumericInputError.none si input es un String sin unidades que puede convertirse en número', () {
      // Arrange
      const input = '1000';
      const expectedError = NumericInputError.none;

      // Act
      final result = validator.validateKcalConsumed(input);

      // Assert
      expect(result, expectedError);
    });

    test('validateKcalConsumed(input, false) retorna NumericInputError.isNaN si input es un String con un número válido, seguido de unidades', () {
      // Arrange
      const input = '1000 kcal';
      const expectedError = NumericInputError.isNaN;

      // Act
      final result = validator.validateKcalConsumed(input, includesUnits: false);

      // Assert
      expect(result, expectedError);
    });

    test('validateKcalConsumed(input, true) retorna NumericInputError.none si input es un String con un número válido seguido de unidades', () {
      // Arrange
      const input = '1000 kcal';
      const expectedError = NumericInputError.none;

      // Act
      final result = validator.validateKcalConsumed(input, includesUnits: true);

      // Assert
      expect(result, expectedError);
    });

    test('validateKcalConsumed(input) retorna NumericInputError.inputIsBeforeRange si input es un número menor a kcalPerActivityRange.min', () {
      // Arrange
      final negativeInput = ActivityValidator.kcalPerActivityRange.min - 1;
      const expectedError = NumericInputError.inputIsBeforeRange;

      // Act
      final result = validator.validateKcalConsumed(negativeInput);

      // Assert
      expect(result, expectedError);
    });

    test('validateKcalConsumed(input) retorna NumericInputError.none si input es igual a kcalPerActivityRange.min', () {
      // Arrange
      final inputInRange = ActivityValidator.kcalPerActivityRange.min;
      const expectedError = NumericInputError.none;

      // Act
      final result = validator.validateKcalConsumed(inputInRange);

      // Assert
      expect(result, expectedError);
    });

    test('validateKcalConsumed(input) retorna NumericInputError.inputIsAfterRange si input es mayor a kcalPerActivityRange.max', () {
      // Arrange
      final negativeInput = ActivityValidator.kcalPerActivityRange.max + 1;
      const expectedError = NumericInputError.inputIsAfterRange;

      // Act
      final result = validator.validateKcalConsumed(negativeInput);

      // Assert
      expect(result, expectedError);
    });

    test('validateKcalConsumed(input) retorna NumericInputError.none si input es igual a kcalPerActivityRange.max', () {
      // Arrange
      final inputInRange = ActivityValidator.kcalPerActivityRange.max;
      const expectedError = NumericInputError.none;

      // Act
      final result = validator.validateKcalConsumed(inputInRange);

      // Assert
      expect(result, expectedError);
    });
  });
}
