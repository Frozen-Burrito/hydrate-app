import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/map_options.dart';
import 'package:hydrate_app/src/models/user_profile.dart';

enum MedicalCondition {
  notSpecified,
  none,
  renalInsufficiency,
  nephroticSyndrome,
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
  DateTime nextAppointment;

  MedicalData({
    required this.id,
    required this.profileId,
    required this.hypervolemia,
    required this.postDialysisWeight,
    required this.extracellularWater,
    required this.normovolemia,
    required this.recommendedGain,
    required this.actualGain,
    required this.nextAppointment
  });  
  
  MedicalData.uncommitted() : this(
    id: -1,    
    profileId: -1,    
    hypervolemia: 0.0,
    postDialysisWeight: 0.0,
    extracellularWater: 0.0,
    normovolemia: 0.0,
    recommendedGain: 0.0,
    actualGain: 0.0,
    nextAppointment: DateTime.now().add(const Duration( days: 7 )),
  );

  static const String tableName = 'datos_medicos';

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      id ${SQLiteKeywords.idType},
      hipervolemia ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      peso_post_dial ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      agua_extracel ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      normovolemia ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      ganancia_rec ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      ganancia_real ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      fecha_prox_cita ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      id_${UserProfile.tableName} ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},

      ${SQLiteKeywords.fk} (id_${UserProfile.tableName}) ${SQLiteKeywords.references} ${UserProfile.tableName} (id)
          ${SQLiteKeywords.onDelete} ${SQLiteKeywords.noAction}
    )
  ''';

  /// Transforma un mapa con los valores en una nueva instancia de [MedicalData].
  /// 
  /// Si [map['fecha_prox_cita']] es nulo, este método lanza un [FormatException].
  static MedicalData fromMap(Map<String, Object?> map) => MedicalData(
    id: int.tryParse(map['id'].toString()) ?? -1,
    profileId: int.tryParse(map['id_perfil'].toString()) ?? -1,
    hypervolemia: double.tryParse(map['hipervolemia'].toString()) ?? 0.0,
    postDialysisWeight: double.tryParse(map['peso_post_dial'].toString()) ?? 0.0,
    extracellularWater: double.tryParse(map['agua_extracel'].toString()) ?? 0.0,
    normovolemia: double.tryParse(map['normovolemia'].toString()) ?? 0.0,
    recommendedGain: double.tryParse(map['ganancia_rec'].toString()) ?? 0.0,
    actualGain: double.tryParse(map['ganancia_real'].toString()) ?? 0.0,
    nextAppointment: DateTime.parse(map['fecha_prox_cita'].toString()),
  );

  @override
  Map<String, Object?> toMap({ MapOptions options = const MapOptions(), }) {
    final Map<String, Object?> map = {
      'id_perfil': profileId,
      'hipervolemia': hypervolemia,
      'peso_post_dial': postDialysisWeight,
      'agua_extracel': extracellularWater,
      'normovolemia': normovolemia,
      'ganancia_rec': recommendedGain,
      'ganancia_real': actualGain,
      'fecha_prox_cita': nextAppointment.toIso8601String(),
    };

    if (id >= 0) map['id'] = id;

    return map;
  }

  //TODO: Validators
}