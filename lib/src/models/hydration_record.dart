import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/user_profile.dart';

class HydrationRecord extends SQLiteModel {

  int id;
  int amount;
  int batteryPercentage;
  double temperature;
  DateTime date;
  int profileId;

  HydrationRecord({
    this.id = -1,
    this.amount = 0,
    this.batteryPercentage = 0,
    this.temperature = 0.0,
    required this.date,
    this.profileId = -1
  });

  static const String tableName = 'consumo';

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE ${HydrationRecord.tableName} (
      id ${SQLiteModel.idType},
      cantidad ${SQLiteModel.integerType} ${SQLiteModel.notNullType},
      porcentaje_bateria ${SQLiteModel.integerType} ${SQLiteModel.notNullType},
      fecha ${SQLiteModel.textType} ${SQLiteModel.notNullType},
      temperatura ${SQLiteModel.realType} ${SQLiteModel.notNullType},
      id_perfil ${SQLiteModel.integerType} ${SQLiteModel.notNullType},

      ${SQLiteModel.fk} (id_perfil) ${SQLiteModel.references} ${UserProfile.tableName} (id)
          ${SQLiteModel.onDelete} ${SQLiteModel.cascadeAction}
    )
  ''';

  static HydrationRecord fromMap(Map<String, dynamic> map) {
    return HydrationRecord(
      id: map['id'],
      amount: map['cantidad'],
      batteryPercentage: map['porcentaje_bateria'],
      temperature: map['temperatura'],
      date: DateTime.tryParse(map['fecha']) ?? DateTime.now(),
      profileId: map['id_perfil'],
    );
  } 

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'cantidad': amount, 
      'porcentaje_bateria': batteryPercentage,
      'temperatura': temperature,
      'fecha': date.toIso8601String(),
      'id_perfil': profileId
    };

    if (id >= 0) map['id'] = id;

    return map;
  }
}