import 'package:flutter/material.dart';
import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/activity_record.dart';
import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/utils/datetime_extensions.dart';
import 'package:hydrate_app/src/utils/day_frequency.dart';

class RoutineActivity extends SQLiteModel {

  int id;
  int activityId;
  Iterable<int> daysOfWeek;
  TimeOfDay timeOfDay;
  int profileId;

  RoutineActivity({
    this.id = -1,
    required this.activityId,
    required this.daysOfWeek,
    required this.timeOfDay,
    required this.profileId,
  });

  static const String tableName = 'registro_rutina';

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE ${RoutineActivity.tableName} (
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
  Map<String, Object?> toMap() {

    final Map<String, Object?> map = {
      'dias': 0x00.setDayBits(daysOfWeek),
      'hora': timeOfDay.toString(), 
      'id_actividad': activityId,
      'id_perfil': profileId
    };

    if (id >= 0) map['id'] = id;

    return map;
  }

  static RoutineActivity fromMap(Map<String, Object?> map) {

    final dayBits = int.tryParse(map['dias'].toString()) ?? 0;

    final timeParts = map['hora'].toString().split(':');
    final hours = int.tryParse(timeParts.first) ?? 0;
    final minutes = int.tryParse(timeParts.last) ?? 0;

    return RoutineActivity(
      id: int.tryParse(map['id'].toString()) ?? -1,
      daysOfWeek: dayBits.toWeekdays,
      timeOfDay: TimeOfDay(hour: hours, minute: minutes),
      activityId: int.tryParse(map['id_actividad'].toString()) ?? -1,
      profileId: int.tryParse(map['id_perfil'].toString()) ?? -1,
    );
  }
}