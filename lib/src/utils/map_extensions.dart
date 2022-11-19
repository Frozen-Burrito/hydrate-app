import 'package:flutter/material.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/map_options.dart';
import 'package:hydrate_app/src/models/validators/range.dart';
import 'package:hydrate_app/src/utils/numbers_common.dart';

extension MapExtensions on Map<String, Object?> {

  T? getMappedEntityOrDefault<T extends SQLiteModel>({ 
    required String attribute,
    T? defaultValue,
    T Function(Map<String, Object?>, { MapOptions options })? mapper,
    EntityMappingType mappingType = EntityMappingType.noMapping,
  }) {
    final T? entity;

    switch (mappingType) {
      case EntityMappingType.noMapping:
        if (this[attribute] is T) {
          entity = this[attribute] as T;
        } else {
          entity = defaultValue;
        }
        break;
      case EntityMappingType.asMap:
        if (mapper != null && this[attribute] is Map<String, Object?>) {
          entity = mapper(this[attribute] as Map<String, Object?>);
        } else {
          entity = defaultValue;
        }
        break;
      case EntityMappingType.idOnly:
        final int countryId = int.tryParse(this[attribute].toString()) ?? -1;
        // final countryWithId = existingCountries.where((country) => country.id == countryId);
        // country = countryWithId.isNotEmpty ? countryWithId.first : Country.countryNotSpecified;
        entity = defaultValue;
        break;
      case EntityMappingType.notIncluded:
      default:
        entity = defaultValue;
        break;
    }
    
    return entity;
  }

  Iterable<T> getEntityCollection<T extends SQLiteModel>({
    required String attribute,
    T Function(Map<String, Object?>, { MapOptions? options })? mapper,
    List<T>? existingEntities,
  }) {
    final List<T> entityCollection = <T>[];
    final Object? entitiesFromMap = this[attribute];

    print("Mapped entity collection type <${entitiesFromMap.runtimeType}>");

    if (entitiesFromMap is List<Map<String, Object?>> && mapper != null) {
      entityCollection.addAll(
        entitiesFromMap.map((entity) => mapper(entity))
      );
    } else if (entitiesFromMap is List<dynamic> && existingEntities != null) {
      entityCollection.addAll(
        existingEntities.where((entity) => entitiesFromMap.contains(entity.id))
      );
    }

    return entityCollection;
  }
  
  int getIntegerInRange({ required String attribute, required Range range, }) {

    final int parsedValue = int.tryParse(this[attribute].toString()) ?? 0;
    final int constrainedValue = constrain(
      parsedValue, 
      min: range.min.toInt(),
      max: range.max.toInt() - 1,
    );

    return constrainedValue;
  }

  int getIntegerOrDefault({ required String attribute, int defaultValue = 0 }) {
    return int.tryParse(this[attribute].toString()) ?? defaultValue;
  }

  double getDoubleOrDefault({ required String attribute, double defaultValue = 0.0 }) {
    return double.tryParse(this[attribute].toString()) ?? defaultValue;
  }

  double getDoubleInRange({ required String attribute, required Range range, }) {

    final double parsedValue = getDoubleOrDefault(attribute: attribute);
    final int comparisonResult = range.compareTo(parsedValue);

    final double constrainedValue;

    if (comparisonResult == 0) {
      constrainedValue = parsedValue;
    } else if (comparisonResult > 0) {
      constrainedValue = range.max.toDouble();
    } else {
      constrainedValue = range.min.toDouble();
    }

    return constrainedValue;
  }
  
  DateTime? getDateTimeOrDefault({ required String attribute, DateTime? defaultValue, }) {
    
    final parsedDateTime = DateTime.tryParse(this[attribute].toString()) 
        ?? defaultValue;

    return parsedDateTime;
  }

  TimeOfDay? getTimeOfDayOrDefault({ required String attribute, TimeOfDay? defaultValue, }) {

    final parsedTime = this[attribute].toString().split(':');

    if (parsedTime.length < 2) return defaultValue;

    final hours = int.tryParse(parsedTime.first) ?? 0;
    final minutes = int.tryParse(parsedTime.last) ?? 0;

    return TimeOfDay(hour: hours, minute: minutes);
  }
}