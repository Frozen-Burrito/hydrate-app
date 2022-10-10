import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/map_options.dart';
import 'package:hydrate_app/src/utils/google_fit_activity_type.dart';

class ActivityType extends SQLiteModel {

  final int id;
  final double averageSpeedKmH;
  final double mets;
  final int googleFitActivityType;

  ActivityType({
    this.id = -1,
    this.averageSpeedKmH = 0.0,
    required this.mets,
    required this.googleFitActivityType,
  });

  ActivityType.uncommited() : this(
    id: -1,
    averageSpeedKmH: 0.0,
    mets: 0.0,
    googleFitActivityType: GoogleFitActivityType.unknown,
  );

  static const String tableName = 'tipo_actividad';

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE ${ActivityType.tableName} (
      id ${SQLiteKeywords.idType},
      vel_promedio_kmh ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      mets ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      tipo_act_google_fit ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType}
    )
  ''';

  static ActivityType fromMap(Map<String, Object?> map, { MapOptions options = const MapOptions(),}) {

    final int parsedGoogleFitActType = int.tryParse(map["tipo_act_google_fit"].toString()) ?? GoogleFitActivityType.unknown;
    final int googleFitActType = GoogleFitActivityType.values.singleWhere(
      (value) => parsedGoogleFitActType == value,
      orElse: () => GoogleFitActivityType.unknown
    );

    return ActivityType(
      id: int.tryParse(map['id'].toString()) ?? -1,
      averageSpeedKmH: double.tryParse(map['vel_promedio_kmh'].toString()) ?? 0.0,
      mets: double.tryParse(map['mets'].toString()) ?? 0.0,
      googleFitActivityType: googleFitActType,
    );
  } 

  @override
  Map<String, Object?> toMap({ MapOptions options = const MapOptions(), }) {
    final Map<String, Object?> map = {
      'vel_promedio_kmh': averageSpeedKmH, 
      'mets': mets,
      'tipo_act_google_fit': googleFitActivityType,
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

    final bool isSpeedEqual = (averageSpeedKmH - otherActType.averageSpeedKmH).abs() < 0.01;
    final bool areMetsEqual = (mets - otherActType.mets).abs() < 0.001;
    final bool areGoogleFitActTypesEqual = googleFitActivityType == other.googleFitActivityType;

    return id == otherActType.id && isSpeedEqual && areMetsEqual && areGoogleFitActTypesEqual;
  }

  @override
  int get hashCode => Object.hashAll([ id, averageSpeedKmH, mets, googleFitActivityType ]);

  static String? validateType(int? value, List<ActivityType> availableActivityTypes) {
    if (value == null) return 'Selecciona un tipo de actividad.';

    final int selectedItemIndex = availableActivityTypes
      .indexWhere((activityType) => activityType.id == value);

    return (selectedItemIndex != -1) 
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
