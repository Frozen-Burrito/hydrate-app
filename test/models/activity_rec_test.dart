import 'package:flutter_test/flutter_test.dart';
import 'package:hydrate_app/src/models/activity_record.dart';
import 'package:hydrate_app/src/models/activity_type.dart';

void main() {

  group('Comparaciones', () {
    test('isSimilarTo() retorna true cuando las actividades son similares.', () {
      // Arrange
      final date9MinsFromNow = DateTime.now().add(const Duration(minutes: 9));
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
        date: date9MinsFromNow, 
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
      final date10MinsFromNow = DateTime.now().add(const Duration(minutes: 15));
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
        date: date10MinsFromNow, 
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
