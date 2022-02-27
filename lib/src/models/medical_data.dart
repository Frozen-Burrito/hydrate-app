import 'package:hydrate_app/src/db/sqlite_model.dart';

enum MedicCondition {
  notSpecified,
  none,
  renalInsufficiency,
  nefroticSyndrome,
  other,
}

class MedicalData extends SQLiteModel {
  
  int id;
  double hypervolemia;
  double postDialysisWeight;
  double extracellularWater;
  double normovolemia;
  double recommendedGain;
  double actualGain;
  DateTime? nextAppointment;

  MedicalData({
    this.id = 0,
    this.hypervolemia = 0.0,
    this.postDialysisWeight = 0.0,
    this.extracellularWater = 0.0,
    this.normovolemia = 0.0,
    this.recommendedGain = 0.0,
    this.actualGain = 0.0,
    this.nextAppointment
  });

  @override
  String get table => 'datos_medicos';

  static const String createTableQuery = '''
    CREATE TABLE datos_medicos (
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

  static MedicalData fromMap(Map<String, dynamic> map) => MedicalData(
    id: map['id'],
    hypervolemia: map['hipervolemia'],
    postDialysisWeight: map['peso_post_dial'],
    extracellularWater: map['agua_extracel'],
    normovolemia: map['normovolemia'],
    recommendedGain: map['ganancia_rec'],
    actualGain: map['ganancia_real'],
    nextAppointment: DateTime.parse(map['fecha_prox_cita']),
  );

  @override
  Map<String, dynamic> toMap() => {
    'id': id,
    'hipervolemia': hypervolemia,
    'peso_post_dial': postDialysisWeight,
    'agua_extracel': extracellularWater,
    'normovolemia': normovolemia,
    'ganancia_rec': recommendedGain,
    'ganancia_real': actualGain,
    'fecha_prox_cita': nextAppointment,
  };

  //TODO: Validators
}