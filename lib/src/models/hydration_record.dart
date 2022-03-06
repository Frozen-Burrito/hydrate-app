import 'package:hydrate_app/src/db/sqlite_model.dart';

class HydrationRecord extends SQLiteModel {

  int id;
  int amount;
  int batteryPercentage;
  DateTime? date;

  HydrationRecord({
    this.id = 0,
    this.amount = 0,
    this.batteryPercentage = 0,
    this.date
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
      date: map['fecha'],
    );
  } 

  @override
  Map<String, dynamic> toMap({bool includeId = false}) {
    final Map<String, dynamic> map = {
      'cantidad': amount, 
      'porcentaje_bateria': batteryPercentage,
      'fecha': date?.toIso8601String(),
    };

    if (includeId) map['id'] = id;

    return map;
  }
}