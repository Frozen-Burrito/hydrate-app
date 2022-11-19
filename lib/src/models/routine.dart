import 'package:flutter/material.dart';
import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/activity_record.dart';
import 'package:hydrate_app/src/models/map_options.dart';
import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/utils/datetime_extensions.dart';
import 'package:hydrate_app/src/utils/map_extensions.dart';

class Routine extends SQLiteModel {

  int id;
  int activityId;
  Iterable<int> _daysOfWeek;
  TimeOfDay timeOfDay;
  int profileId;

  List<int> daysOfWeekList;

  Routine(this._daysOfWeek, {
    this.id = -1,
    required this.activityId,
    required this.timeOfDay,
    this.profileId = -1,
  }) : daysOfWeekList = _daysOfWeek.toList();

  Routine.uncommited() : this(
    <int>[],
    activityId: -1,
    timeOfDay: const TimeOfDay(hour: 0, minute: 0),
    profileId: -1,
  );

  Iterable<int> get daysOfweek => _daysOfWeek;

  set daysOfWeek (Iterable<int> weekdays) {
    _daysOfWeek = weekdays;
    daysOfWeekList = _daysOfWeek.toList();
  } 

  bool get hasWeekdays => _daysOfWeek.isNotEmpty;

  static const String tableName = 'registro_rutina';

  static const String idFieldName = "id";
  static const String daysFieldName = "dias";
  static const String timeOfDayFieldName = "hora";
  static const String activityIdFieldName = "id_${ActivityRecord.tableName}";
  static const String profileIdFieldName = "id_${UserProfile.tableName}";

  /// Una lista con todos los nombres base de los atributos de la entidad.
  static const baseAttributeNames = <String>[
    idFieldName,
    daysFieldName,
    timeOfDayFieldName,
    activityIdFieldName,
    profileIdFieldName,
  ];

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE ${Routine.tableName} (
      $idFieldName ${SQLiteKeywords.idType},
      $daysFieldName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      $timeOfDayFieldName ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      $activityIdFieldName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      $profileIdFieldName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},

      ${SQLiteKeywords.fk} ($activityIdFieldName) ${SQLiteKeywords.references} ${ActivityRecord.tableName} (${ActivityRecord.idPropName})
          ${SQLiteKeywords.onDelete} ${SQLiteKeywords.cascadeAction},

      ${SQLiteKeywords.fk} ($profileIdFieldName) ${SQLiteKeywords.references} ${UserProfile.tableName} (${UserProfile.idFieldName})
          ${SQLiteKeywords.onDelete} ${SQLiteKeywords.cascadeAction}
    )
  ''';

  @override
  Map<String, Object?> toMap({ MapOptions options = const MapOptions(), }) {

    final attributeNames = options.mapAttributeNames(
      baseAttributeNames,
      specificAttributeMappings: options.useCamelCasePropNames 
      ? const {
        profileIdFieldName: "idPerfil",
        activityIdFieldName: "idActividad",
      } 
      : const {
        profileIdFieldName: profileIdFieldName,
        activityIdFieldName: activityIdFieldName,
      }
    );

    final Map<String, Object?> map = {};

    if (id >= 0) map[attributeNames[idFieldName]!] = id;

    map.addAll({
      attributeNames[daysFieldName]!: 0x00.setDayBits(_daysOfWeek),
      attributeNames[timeOfDayFieldName]!: _getSimpleTimeOfDay(), 
      attributeNames[activityIdFieldName]!: activityId,
      attributeNames[profileIdFieldName]!: profileId
    });

    return map;
  }

  static Routine fromMap(Map<String, Object?> map, { MapOptions options = const MapOptions(), }) {

    final attributeNames = options.mapAttributeNames(
      baseAttributeNames,
      specificAttributeMappings: options.useCamelCasePropNames ? {} 
      : const {
        activityIdFieldName: activityIdFieldName,
        profileIdFieldName: profileIdFieldName,
      }
    );

    final dayBits = map.getIntegerOrDefault(attribute: attributeNames[daysFieldName]!, defaultValue: 0 );

    final int id = map.getIntegerOrDefault(attribute: attributeNames[idFieldName]!);
    final int activityId = map.getIntegerOrDefault(attribute: attributeNames[activityIdFieldName]!);
    final int profileId = map.getIntegerOrDefault(attribute: attributeNames[profileIdFieldName]!);

    final TimeOfDay timeOfDay = map.getTimeOfDayOrDefault(
      attribute: attributeNames[timeOfDayFieldName]!,
      defaultValue: const TimeOfDay(hour: 0, minute: 0)
    )!;

    return Routine(
      dayBits.toWeekdays,
      id: id,
      timeOfDay: timeOfDay,
      activityId: activityId,
      profileId: profileId,
    );
  }

  String _getSimpleTimeOfDay() {
    final twoDigitHour = timeOfDay.hour.toString().padLeft(2, "0");
    final twoDigitMinute = timeOfDay.minute.toString().padLeft(2, "0");

    return "$twoDigitHour:$twoDigitMinute";
  }

  /// Obtiene la fecha de la siguiente ocurrencia de la rutina, después de 
  /// [previousDate]. 
  /// 
  /// La fecha producida siempre es después (isAfter) que [previousDate] y puede
  /// tener un weekday diferente, si la rutina sucede en dos o varios días de la 
  /// semana. 
  DateTime getNextOccurrence(DateTime previousDate) {

    // Obtener el siguiente índice para el día de la semana de la rutina.
    final currentDayIdx = daysOfWeekList.indexOf(previousDate.weekday);
    final nextIdx = (currentDayIdx + 1) % daysOfWeekList.length;

    assert(nextIdx >= 0 && nextIdx < daysOfWeekList.length);

    // Calcular el número de días entre previousDate y la nueva ocurrencia de 
    // la rutina.
    final daysToNextDate = DateTime.sunday - (previousDate.weekday - daysOfWeekList[nextIdx]).abs();

    // Obtener la fecha de la siguiente ocurrencia.
    final nextDate = previousDate.add(Duration( days: daysToNextDate ));

    assert(nextDate.isAfter(previousDate));

    return nextDate;
  }
}
