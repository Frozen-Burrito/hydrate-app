import 'package:hydrate_app/src/db/sqlite_model.dart';

enum MedicalCondition {
  notSpecified,
  none,
  renalInsufficiency,
  nefroticSyndrome,
  other,
}

class MedicalData extends SQLiteModel {
  
  int id;
  int profileId;
  double hypervolemia;
  double postDialysisWeight;
  double extracellularWater;
  double normovolemia;
  double recommendedGain;
  double actualGain;
  DateTime? nextAppointment;

  MedicalData({
    this.id = -1,
    this.profileId = -1,
    this.hypervolemia = 0.0,
    this.postDialysisWeight = 0.0,
    this.extracellularWater = 0.0,
    this.normovolemia = 0.0,
    this.recommendedGain = 0.0,
    this.actualGain = 0.0,
    this.nextAppointment
  });

  static const String tableName = 'datos_medicos';

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      id ${SQLiteModel.idType},
      hipervolemia ${SQLiteModel.realType} ${SQLiteModel.notNullType},
      peso_post_dial ${SQLiteModel.realType} ${SQLiteModel.notNullType},
      agua_extracel ${SQLiteModel.realType} ${SQLiteModel.notNullType},
      normovolemia ${SQLiteModel.realType} ${SQLiteModel.notNullType},
      ganancia_rec ${SQLiteModel.realType} ${SQLiteModel.notNullType},
      ganancia_real ${SQLiteModel.realType} ${SQLiteModel.notNullType},
      fecha_prox_cita ${SQLiteModel.textType} ${SQLiteModel.notNullType}
    )
  ''';

  static MedicalData fromMap(Map<String, Object?> map) => MedicalData(
    id: int.tryParse(map['id'].toString()) ?? -1,
    hypervolemia: double.tryParse(map['hipervolemia'].toString()) ?? 0.0,
    postDialysisWeight: double.tryParse(map['peso_post_dial'].toString()) ?? 0.0,
    extracellularWater: double.tryParse(map['agua_extracel'].toString()) ?? 0.0,
    normovolemia: double.tryParse(map['normovolemia'].toString()) ?? 0.0,
    recommendedGain: double.tryParse(map['ganancia_rec'].toString()) ?? 0.0,
    actualGain: double.tryParse(map['ganancia_real'].toString()) ?? 0.0,
    nextAppointment: DateTime.tryParse(map['fecha_prox_cita'].toString()),
  );

  @override
  Map<String, Object?> toMap() {
    final Map<String, Object?> map = {
      'hipervolemia': hypervolemia,
      'peso_post_dial': postDialysisWeight,
      'agua_extracel': extracellularWater,
      'normovolemia': normovolemia,
      'ganancia_rec': recommendedGain,
      'ganancia_real': actualGain,
      'fecha_prox_cita': nextAppointment?.toIso8601String() ?? '',
    };

    if (id >= 0) map['id'] = id;

    return map;
  }

  //TODO: Validators
}