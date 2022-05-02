import 'dart:math';

import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';

class ActivityType extends SQLiteModel {

  final int id;
  final double averageSpeedKmH;
  final double mets;
  final ActivityTypeValue activityTypeValue;

  ActivityType({
    this.id = -1,
    this.averageSpeedKmH = 0.0,
    required this.mets,
    required this.activityTypeValue,
  });

  static const String tableName = 'tipo_actividad';

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE ${ActivityType.tableName} (
      id ${SQLiteKeywords.idType},
      vel_promedio_kmh ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      mets ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      valor ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType}
    )
  ''';

  static ActivityType fromMap(Map<String, Object?> map) {

    int activityValue = min((int.tryParse(map['valor'].toString()) ?? 0) , ActivityTypeValue.values.length);

    return ActivityType(
      id: int.tryParse(map['id'].toString()) ?? -1,
      averageSpeedKmH: double.tryParse(map['vel_promedio_kmh'].toString()) ?? 0.0,
      mets: double.tryParse(map['mets'].toString()) ?? 0.0,
      activityTypeValue: ActivityTypeValue.values[activityValue],
    );
  } 

  @override
  Map<String, Object?> toMap() {
    final Map<String, Object?> map = {
      'vel_promedio_kmh': averageSpeedKmH, 
      'mets': mets,
      'valor': activityTypeValue.index,
    };

    if (id >= 0) map['id'] = id;

    return map;
  }

  bool hasAverageSpeed() {
    return averageSpeedKmH > 0.0 && activityTypeValue.index < ActivityTypeValue.bicycle.index +1;
  }

  static String? validateType(int? value) {
    if (value == null) return 'Selecciona un tipo de actividad.';

    return (value >= 0 && value < ActivityTypeValue.values.length) 
        ? null
        : 'El tipo de actividad no es válido.';
  }
}

enum ActivityTypeValue {
  walk,
  runn,
  bicycle,
  swim,
  soccer,
  basketball,
  volleyball,
  dance,
  yoga
}
