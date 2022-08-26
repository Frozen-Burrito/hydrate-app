import 'package:flutter/foundation.dart';
import "package:flutter_test/flutter_test.dart";
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/country.dart';
import 'package:hydrate_app/src/models/enums/occupation_type.dart';
import 'package:hydrate_app/src/models/enums/user_sex.dart';
import 'package:hydrate_app/src/models/environment.dart';
import 'package:hydrate_app/src/models/medical_data.dart';

import 'package:hydrate_app/src/models/user_profile.dart';

void main() {
  group("Test UserProfile's constructors", () {
    test("Using UserProfile.unmodifiable() creates a profile with isReadonly = true", () {
      // Arrange
      final profile = UserProfile.unmodifiable();

      // Act
      final isTheProfileReadonly = profile.isReadonly;

      // Assert
      expect(isTheProfileReadonly, isTrue);
    });

    test("UserProfile.modifiableCopyOf(other) creates a non-readonly profile", () {
      // Arrange
      final original = UserProfile.unmodifiable();

      // Act
      final copy = UserProfile.modifiableCopyOf(original);

      // Assert
      expect(copy.isReadonly, isFalse);
    });

    test("UserProfile.modifiableCopyOf(other) creates a modifiable profile with the values of other", () {
      // Arrange
      final original = UserProfile.unmodifiable();

      // Act
      final copy = UserProfile.modifiableCopyOf(original);

      // Assert
      expect(copy, original);
    });

    test("UserProfile.uncommited() creates an unmodifiable profile with id = -1", () {
      // Arrange
      const int expectedId = -1;

      // Act
      final profile = UserProfile.uncommitted();

      // Assert
      expect(profile.isReadonly, isTrue);
      expect(profile.id, expectedId);
    });
  });

  group("Test UserProfile as an SQLiteModel", () {
    test("UserProfile implements SQLiteModel", () {
      // Arrange
      // Act
      final profile = UserProfile.unmodifiable();

      // Assert
      expect(profile, isA<SQLiteModel>());
    });

    test("UserProfile.fromMap() creates an equivalent UserProfile from a map representation", () {
      // Arrange
      final DateTime now = DateTime.now();

      final Map<String, Object?> sourceMap = <String, Object?>{
        'id': 2,
        'nombre': "John",
        'apellido': "Doe",
        'fecha_nacimiento': now.toIso8601String(),
        "sexo": UserSex.woman.index,
        'estatura': 1.87,
        'peso': 60.7,
        "padecimientos": MedicalCondition.renalInsufficiency.index,
        "ocupacion": Occupation.student.index,
        'id_usuario': "459861be-f603-4cf0-89a9-e3bd248cb491",
        'entorno_sel': 2,
        'monedas': 256,
        "num_modificaciones": 1,
        "pais": {
          "id": 2,
          "codigo": "NZ",
        }, 
        "entornos": [
          Environment.firstUnlocked().toMap(),
        ],
      };

      final expectedProfile = UserProfile.unmodifiable(
        id: 2,
        firstName: "John",
        lastName: "Doe",
        birthDate: now,
        sex: UserSex.woman,
        height: 1.87,
        weight: 60.7,
        medicalCondition: MedicalCondition.renalInsufficiency,
        occupation: Occupation.student,
        userAccountID: "459861be-f603-4cf0-89a9-e3bd248cb491",
        selectedEnvId: 2,
        coins: 256,
        modificationCount: 1,
        country: Country(id: 2, code: "NZ"),
        unlockedEnvironments: [ Environment.firstUnlocked() ],
      );

      // Act
      final result = UserProfile.fromMap(sourceMap);

      // Assert
      expect(result, expectedProfile);
    });

    test("UserProfile.toMap() creates an equivalent map representation of the profile", () {
      // Arrange
      final DateTime now = DateTime.now();

      final Map<String, Object?> expectedMap = <String, Object?>{
        'id': 2,
        'nombre': "John",
        'apellido': "Doe",
        'fecha_nacimiento': now.toIso8601String(),
        "sexo": UserSex.woman.index,
        'estatura': 1.87,
        'peso': 60.7,
        "padecimientos": MedicalCondition.renalInsufficiency.index,
        "ocupacion": Occupation.student.index,
        'id_usuario': "459861be-f603-4cf0-89a9-e3bd248cb491",
        'entorno_sel': 2,
        'monedas': 256,
        "num_modificaciones": 1,
        "pais": {
          "id": 2,
          "codigo": "NZ",
        }, 
        "entornos": [
          Environment.firstUnlocked().toMap(),
        ],
      };

      final sourceProfile = UserProfile.unmodifiable(
        id: 2,
        firstName: "John",
        lastName: "Doe",
        birthDate: now,
        sex: UserSex.woman,
        height: 1.87,
        weight: 60.7,
        medicalCondition: MedicalCondition.renalInsufficiency,
        occupation: Occupation.student,
        userAccountID: "459861be-f603-4cf0-89a9-e3bd248cb491",
        selectedEnvId: 2,
        coins: 256,
        modificationCount: 1,
        country: Country(id: 2, code: "NZ"),
        unlockedEnvironments: [ Environment.firstUnlocked() ],
      );

      // Act
      final actualMap = sourceProfile.toMap();

      // Assert
      expect(mapEquals(actualMap, expectedMap), isTrue);
    });

    test("Invoking UserProfile.fromMap() and then UserProfile.toMap() produces an equal map", () {
      // Arrange
      final DateTime now = DateTime.now();

      final Map<String, Object?> expectedMap = <String, Object?>{
        'id': 2,
        'nombre': "John",
        'apellido': "Doe",
        'fecha_nacimiento': now.toIso8601String(),
        "sexo": UserSex.woman.index,
        'estatura': 1.87,
        'peso': 60.7,
        "padecimientos": MedicalCondition.renalInsufficiency.index,
        "ocupacion": Occupation.student.index,
        'id_usuario': "459861be-f603-4cf0-89a9-e3bd248cb491",
        'entorno_sel': 2,
        'monedas': 256,
        "num_modificaciones": 1,
        "pais": {
          "id": 2,
          "codigo": "NZ",
        }, 
        "entornos": [
          Environment.firstUnlocked().toMap(),
        ],
      };

      // Act
      final profile = UserProfile.fromMap(expectedMap);
      final actualMap = profile.toMap();

      // Assert
      expect(mapEquals(actualMap, expectedMap), isTrue);
    });

    test("UserProfile's table name is consistent between tableName and table", () {
      // Arrange
      final profile = UserProfile.unmodifiable();

      // Act
      const staticTableName = UserProfile.tableName;
      final instanceTableName = profile.table;

      // Assert
      expect(staticTableName, instanceTableName);
    });
  });

  group("Test the common object methods of UserProfile", () {
      test("UserProfile.toString() returns a non-empty string representation", () {
      // Arrange
      final profile = UserProfile.uncommitted();

      // Act
      final profileAsString = profile.toString();

      // Assert
      expect(profileAsString.isNotEmpty, isTrue);
    });

    test("UserProfile.toString() does not return the default string representation of the object", () {
      // Arrange
      const defaultStrValue = "Instance of 'UserProfile'";
      final profile = UserProfile.uncommitted();

      // Act
      final profileAsString = profile.toString();

      // Assert
      expect(profileAsString, isNot(defaultStrValue));
    });

    test("UserProfile == operator implementation is reflexive", () {
      // Arrange
      final a = UserProfile.uncommitted();

      // Act
      final comparisonResult = a == a;

      // Assert
      expect(comparisonResult, isTrue);
    });

    test("UserProfile == operator implementation is symmetric", () {
      // Arrange
      final a = UserProfile.uncommitted();
      final b = UserProfile.uncommitted();

      // Act
      final firstResult = a == b;
      final secondResult = b == a;

      // Assert
      expect(firstResult, secondResult);
    });

    test("UserProfile == operator implementation is transitive", () {
      // Arrange
      final a = UserProfile.uncommitted();
      final b = UserProfile.uncommitted();
      final c = UserProfile.uncommitted();

      final expectedResult = (a == b) && (b == c);

      // Act
      final transitiveResult = a == c;

      // Assert
      expect(transitiveResult, expectedResult);
    });
  });
}