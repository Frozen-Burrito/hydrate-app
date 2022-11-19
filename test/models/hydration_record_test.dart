import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrate_app/src/models/hydration_record.dart';

void main() {
  group("Map serialization", () {
    test("", () {
      // Arrange
      // Act
      // Assert
    });
  });
  
  group("JSON serialization for REST API", () {
    test("HydrationRecord.fromJson() correctly maps a JSON representation to an instance", () {
      // Arrange
      final expected = HydrationRecord(
        id: 200,
        profileId: 17,
        volumeInMl: 1500,
        batteryPercentage: 90,
        ambientTemperature: 32.5,
        date: DateTime(2022, 10, 10, 8, 39, 1),
      );

      final jsonAttributes = HydrationRecord.jsonAttributes.values;
      final testValues = <Object?>[
        expected.id, expected.volumeInMl, expected.batteryRecord.level, expected.date,
        expected.ambientTemperature, expected.profileId,
      ];

      final jsonMap = Map.fromIterables(jsonAttributes, testValues);

      // Act
      final mappedHydrationRecord = HydrationRecord.fromJson(jsonMap);

      // Assert
      expect(mappedHydrationRecord, expected);
    });

    test("HydrationRecord.toJson() produces a correct JSON representation of the object", () {
      // Arrange
      final hydrationRecord = HydrationRecord(
        id: 200,
        profileId: 17,
        volumeInMl: 1500,
        batteryPercentage: 90,
        ambientTemperature: 32.5,
        date: DateTime(2022, 10, 10, 8, 39, 1),
      );

      final jsonAttributes = HydrationRecord.jsonAttributes.values;
      final testValues = <Object?>[
        hydrationRecord.id, hydrationRecord.volumeInMl, hydrationRecord.batteryRecord.level, 
        hydrationRecord.date.toIso8601String(), hydrationRecord.ambientTemperature, 
        hydrationRecord.profileId,
      ];

      final expected = Map.fromIterables(jsonAttributes, testValues);

      // Act
      final serializedHydrationRecord = hydrationRecord.toJson();

      // Assert
      expect(mapEquals(serializedHydrationRecord, expected), isTrue);
    });

    test("HydrationRecord.toJson() only includes the fields specified in attributes, if attributes is not null", () {
      // Arrange
      final hydrationRecord = HydrationRecord(
        id: 200,
        profileId: 17,
        volumeInMl: 1500,
        batteryPercentage: 90,
        ambientTemperature: 32.5,
        date: DateTime(2022, 10, 10, 8, 39, 1),
      );

      final selectedAttributes = <String>[
        HydrationRecord.jsonAttributes[HydrationRecord.amountAttribute]!,
        HydrationRecord.jsonAttributes[HydrationRecord.idAttribute]!,
        HydrationRecord.jsonAttributes[HydrationRecord.profileIdAttribute]!,
        HydrationRecord.jsonAttributes[HydrationRecord.temperatureAttribute]!,
      ];

      // Act
      final serializedHydrationRecord = hydrationRecord.toJson( attributes: selectedAttributes );

      // Assert
      expect(serializedHydrationRecord.length, selectedAttributes.length);
      expect(serializedHydrationRecord.keys, containsAll(selectedAttributes));
    });
  });

  group("Computed properties", () {
    test("HydrationRecord.date returns the date of creation of the record", () {
      // Arrange
      final DateTime expected = DateTime(2021, 05, 28, 15, 45, 19);

      final hydrationRecord = HydrationRecord( date: expected );

      // Act
      final actualDate = hydrationRecord.date;

      // Assert
      expect(actualDate, expected);
    });

    test("HydrationRecord.volumeInLiters returns the volumeInMl by 10^-3", () {
      // Arrange
      const int volumeInMl = 2796;
      final hydrationRecord = HydrationRecord(
        id: -1,
        volumeInMl: volumeInMl,
        ambientTemperature: 12.3,
        profileId: -1,
        date: DateTime.now(),
        batteryPercentage: 70,
      );

      const double expected = volumeInMl / 1000.0;

      // Act
      final volumeInLiters = hydrationRecord.volumeInLiters;

      // Assert
      expect(volumeInLiters, expected);
    });
  });
}