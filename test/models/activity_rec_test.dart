import 'dart:ffi';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrate_app/src/models/activity_record.dart';
import 'package:hydrate_app/src/models/activity_type.dart';
import 'package:hydrate_app/src/models/map_options.dart';

void main() {

  group('Comparaciones', () {
    test('isSimilarTo() retorna true cuando las actividades son similares.', () {
      // Arrange
      final tomorrowWithSmallDiff = DateTime.now()
          .add(const Duration( days: 1, minutes: 9));

      final walking =  ActivityType(id: 0, mets: 0.0, averageSpeedKmH: 3.2);

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

      final walking =  ActivityType(id: 0, mets: 0.0, averageSpeedKmH: 3.2);

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
    test("toMap() retorna un mapa con todos los atributos de ActivityRecord", () {
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
        "perfil": -1,
      });

      // Act
      final actualMap = activityRecord.toMap();

      // Assert
      expect(actualMap.isNotEmpty, isTrue);
      expect(actualMap, expectedMap);
    });

    test("toMap(), con useCamelCasePropNames = true, usa nombres en camelCase", () {
      // Arrange
      final activityRecord = ActivityRecord.uncommited();

      // Para que el mapa de la entidad incluya su id.
      activityRecord.id = 0;

      final expectedMap = Map.unmodifiable(<String, Object?>{
        "titulo": "",
        "fecha": activityRecord.date.toIso8601String(),
        "duracion": 0,
        "distancia": 0.0,
        "kilocaloriasQuemadas": 0,
        "perfil": -1,
        "alAireLibre": true,
        "esRutina": false,
        "tipoActividad": ActivityType.uncommited(),
        "id": -1,
      });

      // Act
      final actualMap = activityRecord.toMap(options: const MapOptions(
        useCamelCasePropNames: true
      ));

      // Assert
      expect(actualMap.keys, expectedMap.keys);
    });

    test("toMap(), con includeCompleteSubEntities = false, solo incluye el ID ActivityType", () {
      // Arrange
      final activityRecord = ActivityRecord.uncommited();

      // Act
      final actualMap = activityRecord.toMap(options: const MapOptions(
        includeCompleteSubEntities: false
      ));

      // Assert
      expect(actualMap.containsKey("tipo_actividad"), isFalse);
      expect(actualMap.containsValue(ActivityRecord.uncommited()), isFalse);
      
      expect(actualMap["id_tipo_actividad"] is int, isTrue);
    });
  });

  group('Validaciones', () {

    test('validateTitle() retorna un String si el título tiene más de 40 chars.', () {
      // Arrange
      const title = 'Esto es un titulo con mas de cuarenta caracteres, por lo que no es soportado';

      // Act
      final result = ActivityRecord.validateTitle(title);

      // Assert
      expect(result, isA<String>()); 
    });

    test('validateDistance() retorna null si la distancia está en el rango válido.', () {
      // Arrange
      const distance = '29.9 km';

      // Act
      final result = ActivityRecord.validateDitance(distance);

      // Assert
      expect(result, isNull);
    });

    test('validateDistance() retorna un String si la distancia está fuera del rango válido.', () {
      // Arrange
      const distance = '30.1 km';

      // Act
      final result = ActivityRecord.validateDitance(distance);

      // Assert
      expect(result, isA<String>());
    });

    test('validateDuration() retorna null si la duración está el rango válido.', () {
      // Arrange
      const duration = '${60 * 11} mins';

      // Act
      final result = ActivityRecord.validateDuration(duration);

      // Assert
      expect(result, isNull);
    });

    test('validateDuration() retorna un String si la duración es mayor que el rango válido.', () {
      // Arrange
      const duration = '${60 * 12 + 1} mins';

      // Act
      final result = ActivityRecord.validateDuration(duration);

      // Assert
      expect(result, isA<String>());
    });
  });
}
