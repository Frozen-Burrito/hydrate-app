import "package:collection/collection.dart";
import "package:flutter_test/flutter_test.dart";

import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/models/enums/occupation_type.dart';
import 'package:hydrate_app/src/models/enums/user_sex.dart';
import 'package:hydrate_app/src/models/map_options.dart';

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

  group("Test the Behavior of UserProfile", () {
    test("selectedEnvironment returns the firstUnlocked env for a default profile", () {
      // Arrange
      final expectedEnvironment = Environment.firstUnlocked();
      final profile = UserProfile.uncommitted();
      
      // Act
      final selectedEnv = profile.selectedEnvironment;

      // Assert
      expect(selectedEnv, expectedEnvironment);
    });

    test("selectedEnvironment returns an environment with a matching id to profile.selectedEnvId", () {
      // Arrange
      const int expectedUnlockedEnvId = 7;

      final unlockedEnv = Environment(
        id: expectedUnlockedEnvId,
        imagePath: "/img",
        price: 0
      );

      final profile = UserProfile.unmodifiable(
        selectedEnvId: expectedUnlockedEnvId,
        unlockedEnvironments: [
          unlockedEnv,
        ],
      );

      // Act
      final selectedEnv = profile.selectedEnvironment.id;
      final selectedEnvId = profile.selectedEnvId;

      // Assert
      expect(selectedEnvId, expectedUnlockedEnvId);
      expect(selectedEnvId, selectedEnv);
    });

    test("hasUnlockedEnv() returns false if the envId is negative", () {
      // Arrange
      final profile = UserProfile.uncommitted();

      // Act
      final hasUnlockedEnv = profile.hasUnlockedEnv(-1);

      // Assert
      expect(hasUnlockedEnv, isFalse);
    });

    test("hasUnlockedEnv() returns false if the profile does not have an env with the id in its unlockedEnvironments", () {
      // Arrange
      final profile = UserProfile.unmodifiable(
        unlockedEnvironments: [
          Environment.firstUnlocked(),
          Environment(
            id: 2,
            imagePath: "/img",
            price: 0,
          ),
        ],
      );

      // Act
      final hasUnlockedEnv = profile.hasUnlockedEnv(3);

      // Assert
      expect(hasUnlockedEnv, isFalse);
    });

    test("hasUnlockedEnv() returns true if the profile has unlocked the environment with the given id", () {
      // Arrange
      const int unlockedEnvId = 2;
      final profile = UserProfile.unmodifiable(
        unlockedEnvironments: [
          Environment.firstUnlocked(),
          Environment(
            id: unlockedEnvId,
            imagePath: "/img",
            price: 0,
          ),
        ],
      );

      // Act
      final hasUnlockedEnv = profile.hasUnlockedEnv(unlockedEnvId);

      // Assert
      expect(hasUnlockedEnv, isTrue);
    });

    test("hasRenalInsufficiency retorna false si el perfil no tiene MedicalCondition.renalInsufficiency como medicalCondition", () {
      // Arrange
      final profile = UserProfile.unmodifiable( 
        medicalCondition: MedicalCondition.other, 
      );

      // Act
      final hasRenalInsufficiency = profile.hasRenalInsufficiency;

      // Assert
      expect(hasRenalInsufficiency, isFalse);
    });

    test("hasNephroticSyndrome retorna false si el perfil no tiene MedicalCondition.nephroticSyndrome como medicalCondition", () {
      // Arrange
      final profile = UserProfile.unmodifiable( 
        medicalCondition: MedicalCondition.other, 
      );

      // Act
      final hasNephroticSyndrome = profile.hasNephroticSyndrome;

      // Assert
      expect(hasNephroticSyndrome, isFalse);
    });

    test("fullName returns the concatenation of the first and last name, separated by a single space", () {
      // Arrange
      const String firstName = "John Marcus";
      const String lastName = "Doe Johnson";

      const String expectedFullName = "$firstName $lastName";

      final profile = UserProfile.unmodifiable( 
        firstName: firstName, 
        lastName: lastName 
      );

      // Act
      final fullName = profile.fullName;

      // Assert
      expect(fullName, expectedFullName);
    });

    test("initials returns the first letters of both first and last name, in uppercase", () {
      // Arrange
      const String firstName = "John Marcus";
      const String lastName = "Doe Johnson";

      final profile = UserProfile.unmodifiable( 
        firstName: firstName, 
        lastName: lastName 
      );

      const String expectedInitials = "JD";

      // Act
      final initials = profile.initials;

      // Assert
      expect(initials, expectedInitials);
    });

    test("initials returns two dashes, if both first and last name are empty", () {
      // Arrange
      final profile = UserProfile.unmodifiable( 
        firstName: "", 
        lastName: "" 
      );

      const String expectedInitials = "--";

      // Act
      final initials = profile.initials;

      // Assert
      expect(initials, expectedInitials);
    });

    test("addCoins increases the profile's coins to coins + amount", () {
      // Arrange
      const int initialCoins = 30;
      const int amount = 200;
      const int expectedCoinCount = initialCoins + amount;

      final profile = UserProfile.unmodifiable(
        coins: initialCoins,
      );

      // Act
      profile.addCoins(amount);
      final newCoinCount = profile.coins;

      // Assert
      expect(newCoinCount, expectedCoinCount);
    });

    test("addCoins limits the coin count to maxCoins if the amount would surpass the limit", () {
      // Arrange
      const int amount = 1;
      const int expectedCoinCount = UserProfile.maxCoins;

      final profile = UserProfile.unmodifiable(
        coins: UserProfile.maxCoins,
      );

      // Act
      profile.addCoins(amount);
      final newCoinCount = profile.coins;

      // Assert
      expect(newCoinCount, expectedCoinCount);
    });

    
    test("spendCoins() produces the same result, no matter if the amount is negative", () {
      // Arrange
      const int initialCoinAmount = 9;
      const int amount = -9;
      const int expectedCoinCount = 0;

      final profile = UserProfile.unmodifiable(
        coins: initialCoinAmount,
      );

      // Act
      profile.spendCoins(amount);
      final newCoinCount = profile.coins;

      // Assert
      expect(newCoinCount, expectedCoinCount);
    });

    test("spendCoins(amounts) decreases coins by amount", () {
      // Arrange
      const int initialCoinAmount = UserProfile.maxCoins;
      const int amount = UserProfile.maxCoins;
      const int expectedCoinCount = 0;

      final profile = UserProfile.unmodifiable(
        coins: initialCoinAmount,
      );

      // Act
      profile.spendCoins(amount);
      final newCoinCount = profile.coins;

      // Assert
      expect(newCoinCount, expectedCoinCount);
    });

    test("spendCoins() returns false and no coins are spent when the profile has not enough funds", () {
      // Arrange
      const int initialCoinAmount = 0;
      const int amount = 1;

      final profile = UserProfile.unmodifiable(
        coins: initialCoinAmount,
      );

      // Act
      final wereCoinsSpent = profile.spendCoins(amount);

      // Assert
      expect(wereCoinsSpent, isFalse);
      expect(profile.coins, initialCoinAmount);
    });

    test("recordModification() increases a profile's modification count by 1", () {
      // Arrange
      const int initialModificationCount = 1;
      const int expectedModificationCount = 2;

      final profile = UserProfile.unmodifiable(
        modificationCount: initialModificationCount,
      );

      // Act
      profile.recordModification();
      final newModificationCount = profile.modificationCount;

      // Assert
      expect(newModificationCount, expectedModificationCount);
    });
  });

  group("Test UserProfile as an SQLiteModel", () {

    const MapEquality mapEquality = MapEquality();

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
        'entorno_sel': 0,
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
        selectedEnvId: 0,
        coins: 256,
        modificationCount: 1,
        country: Country(id: 2, code: "NZ"),
        unlockedEnvironments: [ Environment.firstUnlocked() ],
      );

      // Act
      final actualMap = sourceProfile.toMap();

      // Assert
      expect(actualMap.keys, containsAll(expectedMap.keys));
    });

    test("Invoking UserProfile.fromMap() and then UserProfile.toMap() produces an equal map", () {
      // Arrange
      const mapOptions = MapOptions(
        useCamelCasePropNames: false,
        includeCompleteSubEntities: true,
        useIntBooleanValues: false,
      );

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
        'entorno_sel': 0,
        'monedas': 256,
        "num_modificaciones": 1,
        "pais": Country( id: 2, code: "NZ" ).toMap( options: mapOptions ),
        "entornos": [
          Environment.firstUnlocked().toMap( options: mapOptions ),
        ],
      };

      // Act
      final profile = UserProfile.fromMap(expectedMap);
      final actualMap = profile.toMap( options: mapOptions );

      // Assert
      expect(actualMap.keys, containsAll(expectedMap.keys));
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
