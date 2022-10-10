import 'package:flutter/material.dart';
import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/activity_record.dart';
import 'package:hydrate_app/src/models/map_options.dart';
import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/utils/datetime_extensions.dart';

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

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE ${Routine.tableName} (
      id ${SQLiteKeywords.idType},
      dias ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      hora ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      id_actividad ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      id_perfil ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},

      ${SQLiteKeywords.fk} (id_${ActivityRecord.tableName}) ${SQLiteKeywords.references} ${ActivityRecord.tableName} (id)
          ${SQLiteKeywords.onDelete} ${SQLiteKeywords.cascadeAction},

      ${SQLiteKeywords.fk} (id_${UserProfile.tableName}) ${SQLiteKeywords.references} ${UserProfile.tableName} (id)
          ${SQLiteKeywords.onDelete} ${SQLiteKeywords.cascadeAction}
    )
  ''';

  @override
  Map<String, Object?> toMap({ MapOptions options = const MapOptions(), }) {

    final Map<String, Object?> map = {
      'dias': 0x00.setDayBits(_daysOfWeek),
      'hora': timeOfDay.toString(), 
      'id_actividad': activityId,
      'id_perfil': profileId
    };

    if (id >= 0) map['id'] = id;

    return map;
  }

  static Routine fromMap(Map<String, Object?> map, { MapOptions options = const MapOptions(), }) {

    final dayBits = int.tryParse(map['dias'].toString()) ?? 0;

    final timeParts = map['hora'].toString().split(':');
    final hours = int.tryParse(timeParts.first) ?? 0;
    final minutes = int.tryParse(timeParts.last) ?? 0;

    return Routine(
      dayBits.toWeekdays,
      id: int.tryParse(map['id'].toString()) ?? -1,
      timeOfDay: TimeOfDay(hour: hours, minute: minutes),
      activityId: int.tryParse(map['id_actividad'].toString()) ?? -1,
      profileId: int.tryParse(map['id_perfil'].toString()) ?? -1,
    );
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