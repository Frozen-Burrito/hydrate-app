import 'dart:math';

import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/map_options.dart';
import 'package:hydrate_app/src/models/user_profile.dart';

class HydrationRecord extends SQLiteModel {

  HydrationRecord({
    this.id = -1,
    this.amount = 0,
    int batteryPercentage = 0,
    this.temperature = 0.0,
    required DateTime date,
    this.profileId = -1
  }) : batteryRecord = BatteryRecord( date, batteryPercentage );

  int id;
  final int amount;
  final double temperature;
  int profileId;

  final BatteryRecord batteryRecord; 

  DateTime get date => batteryRecord.date;

  double get volumeInLiters => amount / 1000.0;

  //TODO: Quitar este constructor, es solo temporal para pruebas.
  HydrationRecord.random(Random rand, DateTime lastDate, int profileId) : this(
    id: -1,
    amount: rand.nextInt(200), 
    batteryPercentage: rand.nextInt(100), 
    date: lastDate,
    temperature: rand.nextDouble() * 50,
    profileId: profileId
  );

  static const String tableName = 'consumo';

  static const String idFieldName = "id";
  static const String amountFieldName = "cantidad";
  static const String batteryLvlFieldName = "porcentaje_bateria";
  static const String dateFieldName = "fecha";
  static const String temperatureFieldName = "temperatura";
  static const String profileIdFieldName = "id_perfil";

  /// Una lista con todos los nombres base de los atributos de la entidad.
  static const baseAttributeNames = <String>[
    idFieldName,
    amountFieldName,
    batteryLvlFieldName,
    dateFieldName,
    temperatureFieldName,
    profileIdFieldName,
  ];

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE ${HydrationRecord.tableName} (
      $idFieldName ${SQLiteKeywords.idType},
      $amountFieldName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      $batteryLvlFieldName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      $dateFieldName ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      $temperatureFieldName ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      $profileIdFieldName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},

      ${SQLiteKeywords.fk} ($profileIdFieldName) ${SQLiteKeywords.references} ${UserProfile.tableName} (id)
          ${SQLiteKeywords.onDelete} ${SQLiteKeywords.cascadeAction}
    )
  ''';

  static HydrationRecord fromMap(Map<String, Object?> map, { MapOptions options = const MapOptions(), }) {
    return HydrationRecord(
      id: int.tryParse(map['id'].toString()) ?? -1,
      amount: int.tryParse(map['cantidad'].toString()) ?? 0,
      batteryPercentage: int.tryParse(map['porcentaje_bateria'].toString()) ?? 0,
      temperature: double.tryParse(map['temperatura'].toString()) ?? 21.0,
      date: DateTime.tryParse(map['fecha'].toString()) ?? DateTime.now(),
      profileId: int.tryParse(map['id_perfil'].toString()) ?? -1,
    );
  } 

  @override
  Map<String, Object?> toMap({ MapOptions options = const MapOptions(), }) {
    final Map<String, Object?> map = {
      'cantidad': amount, 
      'porcentaje_bateria': batteryRecord.level,
      'temperatura': temperature,
      'fecha': batteryRecord.date.toIso8601String(),
      'id_perfil': profileId
    };

    if (id >= 0) map['id'] = id;

    return map;
  }

  @override
  String toString() {
    final strBuf = StringBuffer("Test Hydration record = {");

    strBuf.writeAll(["id:", id, ", "]);
    strBuf.writeAll(["amount:", amount, " ml, "]);
    strBuf.writeAll(["temperature:", temperature, " °C, "]);
    strBuf.writeAll(["remaining battery:", batteryRecord.level, "%, "]);
    strBuf.writeAll(["date:", batteryRecord.date.toIso8601String(), ", "]);
    strBuf.writeAll(["profileId:", profileId, ", "]);

    strBuf.write("}");

    return strBuf.toString();    
  }
}

class BatteryRecord {

  const BatteryRecord( this.date, this.level );

  final DateTime date;
  final int level;

  @override
  String toString() => "BatteryLevel: { date: $date, level: $level% }";
}
