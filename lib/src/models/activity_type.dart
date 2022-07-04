import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';

class ActivityType extends SQLiteModel {

  final int id;
  final double averageSpeedKmH;
  final double mets;

  ActivityType({
    this.id = -1,
    this.averageSpeedKmH = 0.0,
    required this.mets,
  });

  ActivityType.uncommited() : this(
    id: -1,
    averageSpeedKmH: 0.0,
    mets: 0.0,
  );

  static const String tableName = 'tipo_actividad';

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE ${ActivityType.tableName} (
      id ${SQLiteKeywords.idType},
      vel_promedio_kmh ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      mets ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType}
    )
  ''';

  static ActivityType fromMap(Map<String, Object?> map) {

    return ActivityType(
      id: int.tryParse(map['id'].toString()) ?? -1,
      averageSpeedKmH: double.tryParse(map['vel_promedio_kmh'].toString()) ?? 0.0,
      mets: double.tryParse(map['mets'].toString()) ?? 0.0,
    );
  } 

  @override
  Map<String, Object?> toMap() {
    final Map<String, Object?> map = {
      'vel_promedio_kmh': averageSpeedKmH, 
      'mets': mets
    };

    if (id >= 0) map['id'] = id;

    return map;
  }

  @override
  bool operator ==(Object? other) {

    if (other is! ActivityType) {
      return false;
    } 

    final otherActType = other;

    bool isSpeedEqual = (averageSpeedKmH - otherActType.averageSpeedKmH).abs() < 0.01;
    bool areMetsEqual = (mets - otherActType.mets).abs() < 0.001;

    return id == otherActType.id && isSpeedEqual && areMetsEqual;
  }

  @override
  int get hashCode => Object.hashAll([ id, averageSpeedKmH, mets ]);

  bool hasAverageSpeed() {
    return averageSpeedKmH > 0.0 && id < ActivityTypeValue.bicycle.index +1;
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
