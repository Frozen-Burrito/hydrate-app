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
  DateTime createdAt;

  MedicalData({
    required this.id,
    required this.profileId,
    required this.hypervolemia,
    required this.postDialysisWeight,
    required this.extracellularWater,
    required this.normovolemia,
    required this.recommendedGain,
    required this.actualGain,
    required this.nextAppointment,
    required this.createdAt,
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
    createdAt: DateTime.now(),
  );

  static const int mainFieldsCount = 6;

  static const String tableName = 'datos_medicos';

  static const String idFieldName = "id";
  static const String profileIdFieldName = "id_${UserProfile.tableName}";
  static const String hypervolemiaFieldName = "hipervolemia";
  static const String postDialysisWeightFieldName = "peso_post_dial";
  static const String extracellularWaterFieldName = "agua_extracel";
  static const String normovolemiaFieldName = "normovolemia";
  static const String recommendedGainFieldName = "ganancia_rec";
  static const String actualGainFieldName = "ganancia_real";
  static const String nextAppointmentFieldName = "fecha_prox_cita";
  static const String createdAtFieldName = "fecha_creacion";

  /// Una lista con todos los nombres base de los atributos de la entidad.
  static const baseAttributeNames = <String>[
    idFieldName,
    profileIdFieldName,
    hypervolemiaFieldName,
    postDialysisWeightFieldName,
    extracellularWaterFieldName,
    normovolemiaFieldName,
    recommendedGainFieldName,
    actualGainFieldName,
    nextAppointmentFieldName,
    createdAtFieldName,
  ];

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      $idFieldName ${SQLiteKeywords.idType},
      $hypervolemiaFieldName ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      $postDialysisWeightFieldName ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      $extracellularWaterFieldName ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      $normovolemiaFieldName ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      $recommendedGainFieldName ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      $actualGainFieldName ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      $nextAppointmentFieldName ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      $createdAtFieldName ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      $profileIdFieldName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},

      ${SQLiteKeywords.fk} (id_${UserProfile.tableName}) ${SQLiteKeywords.references} ${UserProfile.tableName} (id)
          ${SQLiteKeywords.onDelete} ${SQLiteKeywords.noAction}
    )
  ''';

  /// Transforma un mapa con los valores en una nueva instancia de [MedicalData].
  /// 
  /// Si [map['fecha_prox_cita']] es nulo, este método lanza un [FormatException].
  static MedicalData fromMap(Map<String, Object?> map, { MapOptions options = const MapOptions(),}) => MedicalData(
    id: int.tryParse(map[idFieldName].toString()) ?? -1,
    profileId: int.tryParse(map[profileIdFieldName].toString()) ?? -1,
    hypervolemia: double.tryParse(map[hypervolemiaFieldName].toString()) ?? 0.0,
    postDialysisWeight: double.tryParse(map[postDialysisWeightFieldName].toString()) ?? 0.0,
    extracellularWater: double.tryParse(map[extracellularWaterFieldName].toString()) ?? 0.0,
    normovolemia: double.tryParse(map[normovolemiaFieldName].toString()) ?? 0.0,
    recommendedGain: double.tryParse(map[recommendedGainFieldName].toString()) ?? 0.0,
    actualGain: double.tryParse(map[actualGainFieldName].toString()) ?? 0.0,
    nextAppointment: DateTime.parse(map[nextAppointmentFieldName].toString()),
    createdAt: DateTime.parse(map[createdAtFieldName].toString())
  );

  @override
  Map<String, Object?> toMap({ MapOptions options = const MapOptions(), }) {
    final Map<String, Object?> map = {
      profileIdFieldName: profileId,
      hypervolemiaFieldName: hypervolemia,
      postDialysisWeightFieldName: postDialysisWeight,
      extracellularWaterFieldName: extracellularWater,
      normovolemiaFieldName: normovolemia,
      recommendedGainFieldName: recommendedGain,
      actualGainFieldName: actualGain,
      nextAppointmentFieldName: nextAppointment.toIso8601String(),
      createdAtFieldName: createdAt.toIso8601String(),
    };

    if (id >= 0) map[idFieldName] = id;

    return map;
  }

  //TODO: Validators
}