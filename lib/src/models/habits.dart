import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/map_options.dart';
import 'package:hydrate_app/src/models/user_profile.dart';

class Habits extends SQLiteModel {

  @override
  final int id;
  
  double hoursOfSleep;
  double hoursOfActivity;
  double hoursOfOccupation;
  double maxTemperature;
  DateTime date;
  int profileId;

  Habits({
    required this.id,
    required this.hoursOfSleep,
    required this.hoursOfActivity,
    required this.hoursOfOccupation,
    required this.maxTemperature,
    required this.date,
    required this.profileId
  });

  Habits.uncommitted() : this(
    id: -1,
    hoursOfSleep: 0,
    hoursOfActivity: 0,
    hoursOfOccupation: 0,
    maxTemperature: 0,
    date: DateTime.now(),
    profileId: -1
  );

  static const String tableName = 'reporte_habitos';

  static const String idFieldName = "id";
  static const String profileIdFieldName = "id_perfil";
  static const String hoursOfSleepFieldName = "horas_sueno";
  static const String hoursOfActivityFieldName = "horas_act_fisica";
  static const String hoursOfOccupationFieldName = "horas_ocupacion";
  static const String maxTemperatureFieldName = "temperatura_max";
  static const String dateFieldName = "fecha";

  /// Una lista con todos los nombres base de los atributos de la entidad.
  static const baseAttributeNames = <String>[
    idFieldName,
    profileIdFieldName,
    hoursOfSleepFieldName,
    hoursOfActivityFieldName,
    hoursOfOccupationFieldName,
    maxTemperatureFieldName,
    dateFieldName,
  ];

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      $idFieldName ${SQLiteKeywords.idType},
      $hoursOfSleepFieldName ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      $hoursOfActivityFieldName ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      $hoursOfOccupationFieldName ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      $maxTemperatureFieldName ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      $dateFieldName ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      $profileIdFieldName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},

      ${SQLiteKeywords.fk} ($profileIdFieldName) ${SQLiteKeywords.references} ${UserProfile.tableName} (id)
          ${SQLiteKeywords.onDelete} ${SQLiteKeywords.cascadeAction}
    )
  ''';

  /// Transforma un mapa con los valores en una nueva instancia de [Habits].
  /// 
  /// Si [map['fecha']] es nulo, este método lanza un [FormatException].
  static Habits fromMap(Map<String, Object?> map, { MapOptions options = const MapOptions(),}) {

    return Habits(
      id: (map['id'] is int ? map['id'] as int : -1),
      hoursOfSleep: double.tryParse(map['horas_sueno'].toString()) ?? 0.0,
      hoursOfActivity: double.tryParse(map['horas_act_fisica'].toString()) ?? 0.0,
      hoursOfOccupation: double.tryParse(map['horas_ocupacion'].toString()) ?? 0.0,
      maxTemperature: double.tryParse(map['temperatura_max'].toString()) ?? 0.0,
      date: DateTime.parse(map['fecha'].toString()),
      profileId: int.tryParse(map['id_perfil'].toString()) ?? -1
    );
  }

  @override
  Map<String, Object?> toMap({ MapOptions options = const MapOptions(), }) {
    final Map<String, Object?> map = {
      'horas_sueno': hoursOfSleep,
      'horas_act_fisica': hoursOfActivity,
      'horas_ocupacion': hoursOfOccupation,
      'temperatura_max': maxTemperature,
      'fecha': date.toIso8601String(),
      'id_perfil': profileId
    };

    if (id >= 0) map['id'] = id;

    return map;
  }

  /// Verifica que la suma total de horas en [dailyHourAvgs] esté entre 0 y 24.
  static String? validateHourTotal(List<double> dailyHourAvgs) { 
    
    double sum = dailyHourAvgs.reduce((total, element) => total + element);

    return (sum < 0 || sum > 24) 
        ? 'El total de horas diarias debe estar entre 0 y 24 horas.'
        : null;
  }

  /// Verifica que [inputTemperature] pueda convertirse a número decimal y esté 
  /// en el rango requerido.
  static String? validateTemperature(String? inputTemperature) {

    if (inputTemperature == null) return 'Escribe la temperatura máxima';
    
    double newMaxTemperature = double.tryParse(inputTemperature) ?? 0.0;

    return (newMaxTemperature < -60.0 || newMaxTemperature > 60.0) 
        ? 'La temperatura máxima debe estar entre -60.0° y 60.0° Celsius.'
        : null;
  }
}