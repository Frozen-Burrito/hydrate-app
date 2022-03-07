import 'package:hydrate_app/src/db/sqlite_model.dart';

class HydrationRecord extends SQLiteModel {

  int id;
  int amount;
  int batteryPercentage;
  DateTime date;

  HydrationRecord({
    this.id = -1,
    this.amount = 0,
    this.batteryPercentage = 0,
    required this.date
  });

  static const String tableName = 'consumo';

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE ${HydrationRecord.tableName} (
      id ${SQLiteModel.idType},
      cantidad ${SQLiteModel.integerType} ${SQLiteModel.notNullType},
      porcentaje_bateria ${SQLiteModel.integerType} ${SQLiteModel.notNullType},
      fecha ${SQLiteModel.textType} ${SQLiteModel.notNullType}
    )
  ''';

  static HydrationRecord fromMap(Map<String, dynamic> map) {
    return HydrationRecord(
      id: map['id'],
      amount: map['cantidad'],
      batteryPercentage: map['porcentaje_bateria'],
      date: DateTime.tryParse(map['fecha']) ?? DateTime.now(),
    );
  } 

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'cantidad': amount, 
      'porcentaje_bateria': batteryPercentage,
      'fecha': date.toIso8601String(),
    };

    if (id >= 0) map['id'] = id;

    return map;
  }
}