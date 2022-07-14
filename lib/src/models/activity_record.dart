import "package:hydrate_app/src/db/sqlite_keywords.dart";
import "package:hydrate_app/src/db/sqlite_model.dart";
import "package:hydrate_app/src/models/activity_type.dart";
import 'package:hydrate_app/src/models/map_options.dart';
import "package:hydrate_app/src/models/user_profile.dart";

class ActivityRecord extends SQLiteModel {

  int id;
  String title;
  DateTime date;
  int duration;
  double distance;
  int kiloCaloriesBurned;
  bool doneOutdoors;
  bool isRoutine;
  ActivityType activityType;
  int profileId;

  ActivityRecord({
    this.id = -1,
    required this.title,
    required this.date, 
    required this.duration,
    this.distance = 0.0,
    this.kiloCaloriesBurned = 0,
    this.doneOutdoors = true,
    this.isRoutine = false,
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
    activityType: ActivityType.uncommited(),
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
  static const String isRoutinePropName = "es_rutina";
  static const String actTypeIdPropName = "id_${ActivityType.tableName}";
  static const String profileIdPropName = "id_${UserProfile.tableName}";

  /// Una lista con todos los nombres base de los atributos de la entidad.
  static const baseAttributeNames = <String>[
    idPropName,
    titlePropName,
    datePropName,
    durationPropName,
    distancePropName,
    kcalPropName,
    outdoorsPropName,
    isRoutinePropName,
    profileIdPropName,
    actTypeIdPropName,
  ];

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
      $isRoutinePropName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},

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
    { MapOptions options = const MapOptions(), }
  ) {

    // Asignar nombres para entradas de entidades anidadas, revisando si [map]
    // contiene la entidad completa o solo su ID.
    final actTypePropName = options.includeCompleteSubEntities 
      ? actTypeIdPropName.replaceFirst("id_", "")
      : actTypeIdPropName;

    // Obtener datos de entidades anidadas desde [map].
    final type = ActivityType.fromMap(
      (map[actTypePropName] is Map<String, Object?>) 
        ? map[actTypePropName] as Map<String, Object?> 
        : { "id": map[actTypePropName] }
    );

    return ActivityRecord(
      id: int.tryParse(map[idPropName].toString()) ?? -1,
      title: map[titlePropName].toString(),
      date: DateTime.tryParse(map[datePropName].toString()) ?? DateTime.now(),
      duration: int.tryParse(map[durationPropName].toString()) ?? 0,
      distance: double.tryParse(map[distancePropName].toString()) ?? 0.0,
      kiloCaloriesBurned: int.tryParse(map[kcalPropName].toString()) ?? 0,
      doneOutdoors: (int.tryParse(map[outdoorsPropName].toString()) ?? 0) != 0,
      isRoutine: (int.tryParse(map[isRoutinePropName].toString()) ?? 0) != 0,
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

    // Modificar los nombres de los atributos para el Map resultante, segun 
    // [options].
    final attributeNames = MapOptions.mapAttributeNames(baseAttributeNames, options);

    // Comprobar que hay una entrada por cada atributo de ActivityRecord.
    assert(attributeNames.length == baseAttributeNames.length);

    // Se asume que el mapa de attributeNames contiene entradas para todos los 
    // atributos de baseAttributeNames, y que acceder con los atributos de 
    // baseAttributeNames nunca producirá null.
    final Map<String, Object?> map = {
      attributeNames[titlePropName]!: title, 
      attributeNames[datePropName]!: date.toIso8601String(),
      attributeNames[durationPropName]!: duration,
      attributeNames[distancePropName]!: distance,
      attributeNames[kcalPropName]!: kiloCaloriesBurned,
      attributeNames[profileIdPropName]!: profileId,
    };

    if (options.useIntBooleanValues) {
      // Los valors booleanos del mapa deben ser representados usando ints.
      map[attributeNames[outdoorsPropName]!] = doneOutdoors ? 1 : 0;
      map[attributeNames[isRoutinePropName]!] = isRoutine ? 1 : 0;
    } else {
      // Los valores booleanos del mapa pueden usar bool.
      map[attributeNames[outdoorsPropName]!] = doneOutdoors;
      map[attributeNames[isRoutinePropName]!] = isRoutine;
    }

    if (options.includeCompleteSubEntities) {
      map[attributeNames[actTypeIdPropName]!] = activityType;
    } else {
      map[attributeNames[actTypeIdPropName]!] = activityType.id;
    }

    // Solo incluir el ID de la entidad si es una entidad existente.
    if (id >= 0) map[attributeNames[idPropName]!] = id;

    return Map.unmodifiable(map);
  }

  bool _kCalModifiedByUser = false;
  bool _distanceModifiedByUser = false;

  void kCalModifiedByUser() => _kCalModifiedByUser = true;
  void distanceModifiedByUser() => _distanceModifiedByUser = true;

  /// Estima los valores de kilocalorías quemadas y distancia para este 
  /// [ActivityRecord] según la duración y el tipo de la actividad, además del 
  /// peso actual del usuario.
  void aproximateData(double userWeight) {
    if (!_distanceModifiedByUser && duration > 0) {

      if (activityType.hasAverageSpeed()) {
        // Si no se ha registrado una distancia específica y la actividad tiene una 
        // velocidad promedio asociada, calcular la distancia con la duración y 
        // la velocidad.
        distance = distanceFromSpeedAndDuration(duration, activityType);

      } else {
        distance = 0;
      }
    }

    if (!_kCalModifiedByUser && duration > 0 && userWeight > 0) {
      // Si no se ha registrado la cantidad específica de kilocalorías y se tiene el 
      // peso del usuario, calcular las kilocalorías con la duración, el peso y 
      // los METs del tipo de actividad.
      kiloCaloriesBurned = kCalFromWeightAndDuration(userWeight, duration, activityType);
    }
  }

  /// Calcula la distancia aproximada de una actividad física.
  /// 
  /// Usa la siguiente fórmula:
  /// 
  /// __duracion en horas__ = __[duration]__ / 60.0  
  /// 
  /// __distancia__ =  __duracion en horas__ * __[activityType.averageSpeedKmH]__
  double distanceFromSpeedAndDuration(int duration, ActivityType activityType) {
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
  int kCalFromWeightAndDuration(
    double userWeight, 
    int durationMins, 
    ActivityType activityType
  ) {
    int kCalPerMinute = activityType.mets * 3.5 * userWeight ~/ 200;

    return kCalPerMinute * durationMins;
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

  /// Calcula la cantidad de monedas de recompensa por realizar esta actividad.
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

  static String? validateTitle(String? inputValue) {
    return (inputValue != null && inputValue.length > 40)
        ? "El título debe tener menos de 40 caracteres"
        : null;
  }

  static String? validateDitance(String? inputValue) {

    double? newDistance = double.tryParse(inputValue?.split(" ").first ?? "0");

    if (inputValue != null && inputValue.isNotEmpty && newDistance != null) {
      if (newDistance > 30.0) {
        return "Las distancia debe ser menor a 30 km";
      } else if (newDistance < 0.0) {
        return "Las distancia debe ser mayor a 0 km";
      }
    }

    return null;
  }

  static String? validateDuration(String? inputValue) {

    int? newDuration = int.tryParse(inputValue?.split(" ").first ?? "0");

    if (inputValue != null && inputValue.isNotEmpty) {
      if (newDuration != null && newDuration > 60 * 12) {
        return "Las duración debe ser menor a 12h";
      }
    }

    return null;
  }


  static String? validateKcal(String? inputValue) {

    double? newKcal = double.tryParse(inputValue?.split(" ").first ?? "0");

    if (inputValue != null && inputValue.isNotEmpty) {
      if (newKcal != null && newKcal > 2500) {
        return "La kilocalorías deben ser menores a 2500";
      }
    }

    return null;
  }
}