import "package:hydrate_app/src/db/sqlite_keywords.dart";
import "package:hydrate_app/src/db/sqlite_model.dart";

import 'package:hydrate_app/src/models/enums/error_types.dart';
import 'package:hydrate_app/src/models/map_options.dart';
import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/models/validators/activity_validator.dart';
import 'package:hydrate_app/src/utils/map_extensions.dart';

class ActivityRecord extends SQLiteModel {

  @override
  int id;

  String title;
  DateTime date;
  int duration;
  double distance;
  int kiloCaloriesBurned;
  bool doneOutdoors;
  Routine? routine;
  ActivityType activityType;
  int profileId;

  static const ActivityValidator validator = ActivityValidator();

  ActivityRecord({
    this.id = -1,
    required this.title,
    required this.date, 
    required this.duration,
    this.distance = 0.0,
    this.kiloCaloriesBurned = 0,
    this.doneOutdoors = true,
    this.routine,
    required this.activityType,
    required this.profileId
  });

  /// Crea un nuevo [ActivityRecord] que no ha sido almacenado como una entidad.
  /// Puede ser usado en formularios de creación, para almacenar los datos de los
  /// campos antes de insertarlo en la BD.
  ActivityRecord.uncommited() : this(
    title: "", 
    date: DateTime.now(), 
    duration: 0, 
    activityType: const ActivityType.uncommited(),
    profileId: -1
  );

  static const String tableName = "actividad";

  static const String idPropName = "id";
  static const String titlePropName = "titulo";
  static const String datePropName = "fecha";
  static const String durationPropName = "duracion";
  static const String distancePropName = "distancia";
  static const String kcalPropName = "kilocalorias_quemadas";
  static const String outdoorsPropName = "al_aire_libre";
  static const String routineAttributeName = "rutina";
  static const String actTypeIdPropName = "id_${ActivityType.tableName}";
  static const String profileIdPropName = "id_${UserProfile.tableName}";

  static const int maxDuration = 60 * 12;

  /// Una lista con todos los nombres base de los atributos de la entidad.
  static const baseAttributeNames = <String>[
    idPropName,
    titlePropName,
    datePropName,
    durationPropName,
    distancePropName,
    kcalPropName,
    outdoorsPropName,
    routineAttributeName,
    profileIdPropName,
    actTypeIdPropName,
  ];

  static const Map<String, String> jsonAttributes = <String, String>{
    idPropName: "id",
    titlePropName: "titulo",
    datePropName: "fecha",
    durationPropName: "duracion",
    distancePropName: "distancia",
    kcalPropName: "kcalQuemadas",
    outdoorsPropName: "fueAlAireLibre",
    routineAttributeName: "rutina",
    profileIdPropName: "idPerfil",
    actTypeIdPropName: "idTipoDeActividad"
  };

  /// El nombre de la tabla, usado en SQLite.
  @override
  String get table => tableName;

  static const String createTableQuery = """
    CREATE TABLE ${ActivityRecord.tableName} (
      $idPropName ${SQLiteKeywords.idType},
      $titlePropName ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      $datePropName ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      $durationPropName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      $distancePropName ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      $kcalPropName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      $outdoorsPropName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},

      $actTypeIdPropName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      $profileIdPropName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},

      ${SQLiteKeywords.fk} ($actTypeIdPropName) ${SQLiteKeywords.references} ${ActivityType.tableName} (id)
          ${SQLiteKeywords.onDelete} ${SQLiteKeywords.cascadeAction},

      ${SQLiteKeywords.fk} ($profileIdPropName) ${SQLiteKeywords.references} ${UserProfile.tableName} (id)
          ${SQLiteKeywords.onDelete} ${SQLiteKeywords.cascadeAction}
    )
  """;

  /// Crea una nueva instancia de [ActivityRecord] a partir del [map] con sus 
  /// atributos.
  /// 
  /// En el [Map], cada llave es el nombre de un atributo de [ActivityRecord] y 
  /// su valor es el valor que tendrá esa propiedad en la nueva instancia.
  /// 
  /// Si se incluye [options], se puede controlar la forma en que [map] es 
  /// interpretado. 
  static ActivityRecord fromMap(
    Map<String, Object?> map, 
    { MapOptions options = const MapOptions(), List<ActivityType> activityTypes = const <ActivityType>[] }
  ) {
    final attributeNames = options.mapAttributeNames(
      baseAttributeNames,
      specificAttributeMappings: options.useCamelCasePropNames 
        ? const {
          kcalPropName: "kcalQuemadas",
          outdoorsPropName: "fueAlAireLibre",
          actTypeIdPropName: "idTipoDeActividad",
          routineAttributeName: "rutina",
        } 
        : const {
          profileIdPropName: profileIdPropName,
        },
    );

    assert(attributeNames.length == baseAttributeNames.length);

    // Obtener datos de entidades anidadas desde [map].
    final ActivityType type;
    switch(options.subEntityMappingType) {
      case EntityMappingType.noMapping:
        type = (map[attributeNames[actTypeIdPropName]!] as ActivityType?) ?? const ActivityType.uncommited();
        break;
      case EntityMappingType.asMap:
        if ((map[attributeNames[actTypeIdPropName]!] is Map<String, Object?>)) {
          type = ActivityType.fromMap(map[attributeNames[actTypeIdPropName]!] as Map<String, Object?>);
        } else {
          type = const ActivityType.uncommited();
        }
        break;
      case EntityMappingType.idOnly:
        final int actTypeId = int.tryParse(map[attributeNames[actTypeIdPropName]!].toString()) ?? -1;
        final actTypeWithId = activityTypes.where((activityType) => activityType.id == actTypeId);
        type = actTypeWithId.isNotEmpty ? actTypeWithId.first : const ActivityType.uncommited();
        break;
      case EntityMappingType.notIncluded:
      default:
        type = const ActivityType.uncommited();
        break;
    }

    final Routine? linkedRoutine = map.getMappedEntityOrDefault<Routine>(
      attribute: routineAttributeName, 
      mapper: Routine.fromMap,
    );

    return ActivityRecord(
      id: int.tryParse(map[idPropName].toString()) ?? -1,
      title: map[titlePropName].toString(),
      date: DateTime.tryParse(map[datePropName].toString()) ?? DateTime.now(),
      duration: int.tryParse(map[durationPropName].toString()) ?? 0,
      distance: double.tryParse(map[distancePropName].toString()) ?? 0.0,
      kiloCaloriesBurned: int.tryParse(map[kcalPropName].toString()) ?? 0,
      doneOutdoors: (int.tryParse(map[outdoorsPropName].toString()) ?? 0) != 0,
      routine: linkedRoutine,
      activityType: type,
      profileId: int.tryParse(map[profileIdPropName].toString()) ?? -1,
    );
  } 

  /// Crea una representación de este objeto en un Map.
  /// 
  /// Si [useCamelCasePropNames] es __true__, los nombres de las propiedades 
  /// (las llaves del mapa) eliminarán los guiones bajos y espacios en ellos y 
  /// harán mayúscula la primera letra de cada palabra después de un separador,
  /// menos la primera. Por ejemplo, `"al_aire_libre"` sería convertido a 
  /// `"alAireLibre"`.
  /// 
  /// Si [includeCompleteSubEntities] es __true__, el mapa resultante tendrá 
  /// entradas con los mapas de las entidades anidadas en este objeto, invocando
  /// sus propios [toMap()]. Si no, solo se incluye el ID de la sub-entidad. 
  /// 
  /// Si [useIntBooleanValues] es __true__, todos los valores booleanos del mapa 
  /// resultante usarán 0 para false y 1 para true. Si es __false__, los valores
  /// por defecto de un bool son usados ("true" y "false") .
  @override
  Map<String, Object?> toMap({ MapOptions options = const MapOptions(), }) {
    // Se asume que el mapa de attributeNames contiene entradas para todos los 
    // atributos de baseAttributeNames, y que acceder con los atributos de 
    // baseAttributeNames nunca producirá null.
    final Map<String, Object?> map = {};

    // Solo incluir el ID de la entidad si es una entidad existente.
    if (id >= 0) map[idPropName] = id;

    map.addAll({
      titlePropName: title, 
      datePropName: date.toIso8601String(),
      durationPropName: duration,
      distancePropName: distance,
      kcalPropName: kiloCaloriesBurned,
    });

    if (options.useIntBooleanValues) {
      // Los valores booleanos del mapa deben ser representados usando ints.
      map[outdoorsPropName] = doneOutdoors ? 1 : 0;
    } else {
      // Los valores booleanos del mapa pueden usar bool.
      map[outdoorsPropName] = doneOutdoors;
    }

    //TODO: arreglar este metodo
    switch (options.subEntityMappingType) {
      case EntityMappingType.noMapping:
        map[actTypeIdPropName] = activityType;
        break;
      case EntityMappingType.asMap:
        map[actTypeIdPropName] = activityType.toMap(options: options);
        break;
      case EntityMappingType.idOnly:
        map[actTypeIdPropName] = activityType.id;
        break;
      case EntityMappingType.notIncluded:
        break;
    }

    map[profileIdPropName] = profileId;

    return map;
  }

  ActivityRecord.fromJson(Map<String, dynamic> json, { List<ActivityType> activityTypes = const <ActivityType>[] })
    : id = json[idPropName],
      title = json[titlePropName],
      date = DateTime.tryParse(json[datePropName].toString()) ?? DateTime.now(), 
      duration = json[durationPropName],
      distance = json[jsonAttributes[distancePropName]!],
      kiloCaloriesBurned = json[jsonAttributes[kcalPropName]!],
      doneOutdoors = json[jsonAttributes[outdoorsPropName]!],
      routine = json[jsonAttributes[routineAttributeName]!] != null ? Routine.fromMap(json[jsonAttributes[routineAttributeName]!]) : null,
      activityType = activityTypes.singleWhere((actType) => actType.id == json[jsonAttributes[actTypeIdPropName]!]),
      profileId = json[jsonAttributes[profileIdPropName]];

  Map<String, Object?> toJson({ List<String>? attributes }) {

    final Map<String, Object?> map = {};

    if (id >= 0) map[jsonAttributes[idPropName]!] = id;

    map.addAll({
      jsonAttributes[titlePropName]!: title,
      jsonAttributes[datePropName]!: date.toIso8601String(),
      jsonAttributes[durationPropName]!: duration,
      jsonAttributes[distancePropName]!: distance,
      jsonAttributes[kcalPropName]!: kiloCaloriesBurned,
      jsonAttributes[actTypeIdPropName]!: activityType.id,
      jsonAttributes[outdoorsPropName]!: doneOutdoors,
      jsonAttributes[routineAttributeName]!: routine,
      jsonAttributes[profileIdPropName]!: profileId,
    });

    if (attributes != null && attributes.isNotEmpty) {
      map.removeWhere((attributeName, _) => !(attributes.contains(attributeName)));
    }

    assert(map.length <= jsonAttributes.length);
    assert(map.isNotEmpty);

    return Map.unmodifiable(map);
  }

  bool _kCalNotYetModified = true;
  bool _distanceNotYetModified = true;

  void userModifiedKcal() => _kCalNotYetModified = false;
  void userModifiedDistance() => _distanceNotYetModified = false;

  /// Estima los valores de kilocalorías quemadas y distancia para este 
  /// [ActivityRecord] según la duración y el tipo de la actividad, además del 
  /// peso actual del usuario.
  void aproximateData(double userWeight) {

    final durationError = validator.validateDurationInMinutes(duration);
    final isDurationValid = durationError == NumericInputError.none;
    
    if (isDurationValid) {
      if (_distanceNotYetModified) {
        // Si no se ha registrado una distancia específica y la actividad tiene una 
        // velocidad promedio asociada, calcular la distancia con la duración y 
        // la velocidad.
        distance = _distanceFromSpeedAndDuration();
      }

      if (_kCalNotYetModified) {
        // Si no se ha registrado la cantidad específica de kilocalorías y se tiene el 
        // peso del usuario, calcular las kilocalorías con la duración, el peso y 
        // los METs del tipo de actividad.
        kiloCaloriesBurned = _kCalFromWeightAndDuration(userWeight);
      }
    }
  }

  /// Calcula la distancia aproximada de una actividad física.
  /// 
  /// Usa la siguiente fórmula:
  /// 
  /// __duracion en horas__ = __[duration]__ / 60.0  
  /// 
  /// __distancia__ =  __duracion en horas__ * __[activityType.averageSpeedKmH]__
  double _distanceFromSpeedAndDuration() {
    double durationInHours = duration / 60.0;

    return durationInHours * activityType.averageSpeedKmH;
  }

  /// Calcula un aproximado de las kilocalorías quemadas en una actividad física.
  /// 
  /// Usa la siguiente fórmula:
  /// 
  /// **kcal/min** = [activityType.mets] * 3.5 * [userWeight] / 200
  /// 
  /// **kcal** = **kcal/min** * [durationMins]
  int _kCalFromWeightAndDuration(double userWeight) {
    int kCalPerMinute = activityType.mets * 3.5 * userWeight ~/ 200;

    return kCalPerMinute * duration;
  }

  /// Determina si este [ActivityRecord] y [other] son similares.
  /// 
  /// Dos actividades son similares si:
  ///  - Tienen el mismo [activityType].
  ///  - Sus fechas, dadas por [date], están en un rango de 7 días.
  ///  - Las horas de las actividades, dadas por sus [date], tiene menos de 15 
  ///    minutos de diferencia.
  ///  - Sus [duration] tienen menos de 10 minutos de diferencia.
  ///  - Tienen intensidades similares.
  bool isSimilarTo(ActivityRecord other) {
    // Revisar si son el mismo tipo de actividad.
    final bool sameType = activityType == other.activityType;

    // Revisar si son en la misma semana, pero distinto día.
    final diffInDays = date.difference(other.date).inDays.abs();
    final bool areDatesInSameWeek = diffInDays > 0 && diffInDays <= 7 ;

    // Revisar si las actividades son en horas similares.
    final minuteOfDay = (date.hour * 60) + date.minute;
    final otherMinuteOfDay = (other.date.hour * 60) + other.date.minute;
    final int absTimeDiff = (minuteOfDay - otherMinuteOfDay).abs();
    final bool similarTime = (absTimeDiff < 15);

    // Revisar ti tienen duraciones similares.
    final bool similarDuration = (duration - other.duration).abs() < 10;
    
    // Revisar si tienen intensidades similares.
    final bool similarIntensity = 
      (kiloCaloriesBurned - other.kiloCaloriesBurned).abs() < 50 ||
      (distance - other.distance).abs() < 0.15;

    // Este método solo retorna true si todas las condiciones anteriores se 
    // cumplen.
    return sameType && areDatesInSameWeek && similarTime && similarDuration && similarIntensity;
  }

  bool get isIntense => (duration > 60 * 3 || distance > 10 || kiloCaloriesBurned > 1500);

  bool get isExhausting => (duration > 60 * 5 || distance > 20 || kiloCaloriesBurned > 2000);

  int get durationInNanoseconds => duration * 60 * 1000000000;

  /// Calcula la cantidad de monedas de recompensa por realizar esta actividad.
  //TODO: otorgar recompensa acorde a la actividad.
  int get coinReward => 50;

  String get formattedDuration => "$duration min.";

  String get formattedDistance => "${distance.toStringAsFixed(1)} km";

  String get formattedKcal => "${kiloCaloriesBurned.toString()} kCal";

  String get hourAndMinuteDuration { 
    int hours = duration ~/ 60;
    int minutes = duration % 60;

    String hourStr = (hours > 0) ? "${hours}h" : "";
    String minuteStr = (hours > 0) ? "y $minutes min." : "$minutes min.";

    return "$hourStr $minuteStr";
  }

  String get numericDate {
    // Fecha con horas y minutos.
    return date.toString().substring(0, 16);
  }

  @override
  String toString() {
    // Use a StringBuffer to build the string representation of this object.
    StringBuffer strBuf = StringBuffer("[ActivityRecord]: {");

    strBuf.writeAll(["id: ", id, ", "]);
    strBuf.writeAll(["date: ", date.toIso8601String().substring(0, 10), ", "]);
    strBuf.writeAll(["title: ", title, ", "]);
    strBuf.writeAll(["duration: ", duration, " minutes, "]);
    strBuf.writeAll(["type: ", activityType.id, ", "]);
    strBuf.writeAll(["profile ID: ", profileId]);

    strBuf.write("}");

    return strBuf.toString();
  }

  @override
  bool operator==(Object? other) {

    if (other is! ActivityRecord) return false;

    final areIdsEqual = id == other.id;
    final areDatesTheSame = date.isAtSameMomentAs(other.date);

    return areIdsEqual && areDatesTheSame;
  }
  
  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    date,
    duration,
    distance,
    kiloCaloriesBurned,
    doneOutdoors,
    routine,
    activityType,
    profileId,
  ]);
}