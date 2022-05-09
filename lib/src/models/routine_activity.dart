import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/activity_record.dart';
import 'package:hydrate_app/src/models/user_profile.dart';

class RoutineActivity extends SQLiteModel {

  int id;
  int activityId;
  DateTime date;
  int profileId;

  RoutineActivity({
    this.id = -1,
    required this.activityId,
    required this.date,
    required this.profileId,
  });

  static const String tableName = 'registro_rutina';

  static const String createTableQuery = '''
    CREATE TABLE ${RoutineActivity.tableName} (
      id ${SQLiteKeywords.idType},
      fecha ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
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
      'fecha': date.toIso8601String(), 
      'id_actividad': activityId,
      'id_perfil': profileId
    };

    if (id >= 0) map['id'] = id;

    return map;
  }

  static RoutineActivity fromMap(Map<String, Object?> map) {

    return RoutineActivity(
      id: int.tryParse(map['id'].toString()) ?? -1,
      date: DateTime.tryParse(map['fecha'].toString()) ?? DateTime.now(),
      activityId: int.tryParse(map['id_actividad'].toString()) ?? -1,
      profileId: int.tryParse(map['id_perfil'].toString()) ?? -1,
    );
  }
}