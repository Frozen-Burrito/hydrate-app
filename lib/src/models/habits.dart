import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/user_profile.dart';

class Habits extends SQLiteModel {

  int id;
  double hoursOfSleep;
  double hoursOfActivity;
  double hoursOfOccupation;
  double maxTemperature;
  DateTime? date;
  int profileId;

  Habits({
    this.id = -1,
    this.hoursOfSleep = 0,
    this.hoursOfActivity = 0,
    this.hoursOfOccupation = 0,
    this.maxTemperature = 0,
    this.date,
    this.profileId = -1
  });

  static const String tableName = 'reporte_habitos';

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      id ${SQLiteKeywords.idType},
      horas_sueno ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      horas_act_fisica ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      horas_ocupacion ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      temperatura_max ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      fecha ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      id_perfil ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},

      ${SQLiteKeywords.fk} (id_perfil) ${SQLiteKeywords.references} ${UserProfile.tableName} (id)
          ${SQLiteKeywords.onDelete} ${SQLiteKeywords.cascadeAction}
    )
  ''';

  static Habits fromMap(Map<String, Object?> map) {

    return Habits(
      id: (map['id'] is int ? map['id'] as int : -1),
      hoursOfSleep: double.tryParse(map['horas_sueno'].toString()) ?? 0.0,
      hoursOfActivity: double.tryParse(map['horas_act_fisica'].toString()) ?? 0.0,
      hoursOfOccupation: double.tryParse(map['horas_ocupacion'].toString()) ?? 0.0,
      maxTemperature: double.tryParse(map['temperatura_max'].toString()) ?? 0.0,
      date: DateTime.tryParse(map['fecha'].toString()),
      profileId: int.tryParse(map['id_perfil'].toString()) ?? -1
    );
  }

  @override
  Map<String, Object?> toMap() {
    final Map<String, Object?> map = {
      'horas_sueno': hoursOfSleep,
      'horas_act_fisica': hoursOfActivity,
      'horas_ocupacion': hoursOfOccupation,
      'temperatura_max': maxTemperature,
      'fecha': date?.toIso8601String(),
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