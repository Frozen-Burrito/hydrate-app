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
    required this.activityType,
    required this.profileId
  }) {
    // TODO: Quitar esta logica del constructor, solo usarla en formulario.
    if (activityType.hasAverageSpeed() && distance < 0.001 && duration > 0) {
      // Si no se registró una distancia específica y la actividad tiene una 
      // velocidad promedio asociada, calcular la distancia con la duración y 
      // la velocidad.
      distance = distanceFromSpeedAndDuration(duration, activityType);
    }
  }

  static const String tableName = 'actividad';

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
      ActivityType.tableName: activityType,
      'id_perfil': profileId
    };

    if (id >= 0) map['id'] = id;

    return map;
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

  bool get isIntense => (duration > 60 * 3 || distance > 10 || kiloCaloriesBurned > 1500);

  bool get isExhausting => (duration > 60 * 5 || distance > 20 || kiloCaloriesBurned > 2000);

  String get formattedDuration => '$duration min.';

  String get formattedDistance => '${distance.toStringAsFixed(1)} km';

  String get formattedKcal => '${kiloCaloriesBurned.toString()} kCal';

  //TODO: Localizar el formato de la fecha.
  String get formattedDate {
    String dateStr = '${date.day} de ${date.month} de ${date.year}, ';
    String hour = 'a la${date.hour > 1 ? 's' : ''} ${date.hour}:${date.minute}';

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

    return date.toString();
  }


  static String? validateTitle(String? inputValue) {
    return (inputValue != null && inputValue.length > 40)
        ? 'El título debe tener menos de 40 caracteres'
        : null;
  }

  static String? validateDitance(String? inputValue) {

    double? newDistance = double.tryParse(inputValue?.split(" ").first ?? '0');

    if (inputValue != null && inputValue.isNotEmpty) {
      return (newDistance != null && newDistance > 30)
          ? 'Las distancia debe ser menor a 30 km'
          : null;
    }
  }

  static String? validateDuration(String? inputValue) {

    int? newDuration = int.tryParse(inputValue?.split(" ").first ?? '0');

    if (inputValue != null && inputValue.isNotEmpty) {
      return (newDuration != null && newDuration > 60 * 12)
          ? 'Las duración debe ser menor a 12h'
          : null;
    }
  }


  static String? validateKcal(String? inputValue) {

    double? newKcal = double.tryParse(inputValue?.split(" ").first ?? '0');

    if (inputValue != null && inputValue.isNotEmpty) {
      return (newKcal != null && newKcal > 2500)
          ? 'La kilocalorías deben ser menores a 2500'
          : null;
    }
  }
}