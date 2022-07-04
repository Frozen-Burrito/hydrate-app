import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/activity_type.dart';
import 'package:hydrate_app/src/models/user_profile.dart';

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
    title: '', 
    date: DateTime.now(), 
    duration: 0, 
    activityType: ActivityType.uncommited(),
    profileId: -1
  );

  static const String tableName = 'actividad';

  /// El nombre de la tabla, usado en SQLite.
  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE ${ActivityRecord.tableName} (
      id ${SQLiteKeywords.idType},
      titulo ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      fecha ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      duracion ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      distancia ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      kilocalorias_quemadas ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      al_aire_libre ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      es_rutina ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},

      id_${ActivityType.tableName} ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      id_${UserProfile.tableName} ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},

      ${SQLiteKeywords.fk} (id_${ActivityType.tableName}) ${SQLiteKeywords.references} ${ActivityType.tableName} (id)
          ${SQLiteKeywords.onDelete} ${SQLiteKeywords.cascadeAction},

      ${SQLiteKeywords.fk} (id_${UserProfile.tableName}) ${SQLiteKeywords.references} ${UserProfile.tableName} (id)
          ${SQLiteKeywords.onDelete} ${SQLiteKeywords.cascadeAction}
    )
  ''';

  static ActivityRecord fromMap(Map<String, Object?> map) {

    final type = ActivityType.fromMap(
      (map[ActivityType.tableName] is Map<String, Object?>) 
        ? map[ActivityType.tableName] as Map<String, Object?> 
        : {}
    );

    return ActivityRecord(
      id: int.tryParse(map['id'].toString()) ?? -1,
      title: map['titulo'].toString(),
      date: DateTime.tryParse(map['fecha'].toString()) ?? DateTime.now(),
      duration: int.tryParse(map['duracion'].toString()) ?? 0,
      distance: double.tryParse(map['distancia'].toString()) ?? 0.0,
      kiloCaloriesBurned: int.tryParse(map['kilocalorias_quemadas'].toString()) ?? 0,
      doneOutdoors: (int.tryParse(map['al_aire_libre'].toString()) ?? 0) != 0,
      isRoutine: (int.tryParse(map['es_rutina'].toString()) ?? 0) != 0,
      activityType: type,
      profileId: int.tryParse(map['id_perfil'].toString()) ?? -1,
    );
  } 

  @override
  Map<String, Object?> toMap() {

    final Map<String, Object?> map = {
      'titulo': title, 
      'fecha': date.toIso8601String(),
      'duracion': duration,
      'distancia': distance,
      'kilocalorias_quemadas': kiloCaloriesBurned,
      'al_aire_libre': doneOutdoors ? 1 : 0,
      'es_rutina': isRoutine ? 1 : 0,
      ActivityType.tableName: activityType,
      'id_perfil': profileId
    };

    if (id >= 0) map['id'] = id;

    return map;
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

  String get formattedDuration => '$duration min.';

  String get formattedDistance => '${distance.toStringAsFixed(1)} km';

  String get formattedKcal => '${kiloCaloriesBurned.toString()} kCal';

  //TODO: Localizar el formato de la fecha.
  static const meses = <String>[
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  String get formattedDate {
    String dateStr = '${date.day} de ${meses[date.month -1]} de ${date.year}';
    String minuteStr = date.minute < 10 ? '0${date.minute}' : date.minute.toString();
    String hour = 'a la${date.hour > 1 ? 's' : ''} ${date.hour}:$minuteStr';

    return '$dateStr, $hour';
  }

  String get hourAndMinuteDuration { 
    int hours = duration ~/ 60;
    int minutes = duration % 60;

    String hourStr = (hours > 0) ? '${hours}h' : '';
    String minuteStr = (hours > 0) ? 'y $minutes min.' : '$minutes min.';

    return '$hourStr $minuteStr';
  }

  String get numericDate {
    // Fecha con horas y minutos.
    return date.toString().substring(0, 16);
  }

  static String? validateTitle(String? inputValue) {
    return (inputValue != null && inputValue.length > 40)
        ? 'El título debe tener menos de 40 caracteres'
        : null;
  }

  static String? validateDitance(String? inputValue) {

    double? newDistance = double.tryParse(inputValue?.split(" ").first ?? '0');

    if (inputValue != null && inputValue.isNotEmpty && newDistance != null) {
      if (newDistance > 30.0) {
        return 'Las distancia debe ser menor a 30 km';
      } else if (newDistance < 0.0) {
        return 'Las distancia debe ser mayor a 0 km';
      }
    }

    return null;
  }

  static String? validateDuration(String? inputValue) {

    int? newDuration = int.tryParse(inputValue?.split(" ").first ?? '0');

    if (inputValue != null && inputValue.isNotEmpty) {
      if (newDuration != null && newDuration > 60 * 12) {
        return 'Las duración debe ser menor a 12h';
      }
    }

    return null;
  }


  static String? validateKcal(String? inputValue) {

    double? newKcal = double.tryParse(inputValue?.split(" ").first ?? '0');

    if (inputValue != null && inputValue.isNotEmpty) {
      if (newKcal != null && newKcal > 2500) {
        return 'La kilocalorías deben ser menores a 2500';
      }
    }

    return null;
  }
}