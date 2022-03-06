import 'package:hydrate_app/src/db/sqlite_model.dart';

class Habits extends SQLiteModel {

  int id;
  int hoursOfSleep;
  int hoursOfActivity;
  int hoursOfOccupation;
  int maxTemperature;
  DateTime? date;

  Habits({
    this.id = -1,
    this.hoursOfSleep = 0,
    this.hoursOfActivity = 0,
    this.hoursOfOccupation = 0,
    this.maxTemperature = 0,
    this.date,
  });

  static const String tableName = 'reporte_habitos';

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      id ${SQLiteModel.idType},
      horas_sueno ${SQLiteModel.integerType} ${SQLiteModel.notNullType},
      horas_act_fisica ${SQLiteModel.integerType} ${SQLiteModel.notNullType},
      horas_ocupacion ${SQLiteModel.integerType} ${SQLiteModel.notNullType},
      temperatura_max ${SQLiteModel.integerType} ${SQLiteModel.notNullType},
      fecha ${SQLiteModel.textType} ${SQLiteModel.notNullType}
    )
  ''';

  static Habits fromMap(Map<String, dynamic> map) {

    return Habits(
      id: map['id'],
      hoursOfSleep: map['horas_sueno'],
      hoursOfActivity: map['horas_act_fisica'],
      hoursOfOccupation: map['horas_ocupacion'],
      maxTemperature: map['temperatura_max'],
      date: DateTime.parse(map['fecha'] ?? DateTime.now()),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'horas_sueno': hoursOfSleep,
      'horas_act_fisica': hoursOfActivity,
      'horas_ocupacion': hoursOfOccupation,
      'temperatura_max': maxTemperature,
      'fecha': date?.toIso8601String(),
    };

    if (id >= 0) map['id'] = id;

    return map;
  }

  /// Verifica que la suma total de horas en [dailyHourAvgs] esté entre 0 y 24.
  static String? validateHourTotal(List<int> dailyHourAvgs) { 
    
    int sum = dailyHourAvgs.reduce((total, element) => total + element);

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