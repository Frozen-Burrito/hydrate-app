import 'package:flutter/material.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/models/activity_record.dart';
import 'package:hydrate_app/src/models/activity_type.dart';

/// Maneja el estado para los __[ActivityRecords]__, __[RoutineActivity]__ y 
/// __[ActivityTypes]__ asociados al perfil de usuario activo.
/// 
/// También permite sincronizar la información, ya sea de forma local en la BD o 
/// externa con el servicio web, cuando sea necesario.
class ActivityProvider extends ChangeNotifier {

  final List<ActivityRecord> _activityRecords = [];
  final List<ActivityType> _activityTypes = [];

  final Map<DateTime, List<ActivityRecord>> _activitiesByDay = {};

  bool _shouldRefreshActivities = true;
  bool _activitiesLoading = false;
  bool _shouldRefreshTypes = true;

  /// Es [true] si el provider está cargando los [ActivityRecords].
  bool get areActivitiesLoading => _activitiesLoading;

  /// Retorna una colección con todos los [ActivityRecord] disponibles.
  /// Solo hace un query a la BD si ha habido modificaciones a los registros.
  Future<List<ActivityRecord>> get activityRecords {

    if (_shouldRefreshActivities && !areActivitiesLoading) {
      return _queryActivityRecords();
    }

    return Future.value(_activityRecords);
  }

  /// Retorna una colección con todos los [ActivityType] disponibles.
  /// Solo hace un query a la BD si ha habido modificaciones a los datos.
  Future<List<ActivityType>> get activityTypes {

    if (_shouldRefreshTypes) {
      return _queryActivityTypes();
    }

    return Future.value(_activityTypes);
  }

  /// Obtiene todos los [ActivityRecord], agrupados por día, con los registros 
  /// más recientes primero.
  Map<DateTime, List<ActivityRecord>> get activitiesByDay => _activitiesByDay;

  /// Obtiene todos los [ActivityRecord] de los 7 días más recientes, agrupados 
  /// por día, con los registros más recientes primero. 
  Future<Map<DateTime, List<ActivityRecord>>> get activitiesFromPastWeek async {
    if (_shouldRefreshActivities) {
      await _queryActivityRecords();
    }

    return Future.value(_getActivitiesFromPastWeek());
  }

  /// Determina si hay al menos una actividad "extenuante" en un conjunto de 
  /// registros de actividad.
  /// 
  /// Retorna __true__ solo si en [activityRecords] hay al menos un registro donde 
  /// [activity.isExhausting] sea __true__. 
  /// 
  /// También retorna __false__ si [activityRecords] es nulo.
  bool hasExhaustingActivities(Map<DateTime, List<ActivityRecord>>? activityRecords) {

    bool hasExhausting = false;

    if (activityRecords != null) {
      // Solo buscar actividades si activityRecords no es nulo.
      activityRecords.forEach((date, activities) {
        
        if (activities.any((activity) => activity.isExhausting)) {
          hasExhausting = true;
          return;
        }
      });
    }
    
    return hasExhausting;
  }

  /// Calcula la cantidad total de kilocalorías quemadas en actividad física por
  /// cada uno de los 7 días anteriores.
  /// 
  /// El resultado tiene exactamente 7 elementos, con los días más recientes al 
  /// final. Si el día actual fuera martes, el primer elemento correspondería al 
  /// total del miércoles de la semana pasada y el último al día actual.
  List<int> get prevWeekKcalTotals => _previousSevenDaysTotals();

  Future<List<ActivityRecord>> _queryActivityRecords() async {
    try {
      _activityRecords.clear();
      _activitiesLoading = true;

      final queryResults = await SQLiteDB.instance.select<ActivityRecord>(
        ActivityRecord.fromMap, 
        ActivityRecord.tableName, 
        orderByColumn: 'fecha',
        orderByAsc: false,
        includeOneToMany: true,
      );

      _activityRecords.addAll(queryResults);

      _joinDailyRecords();

      _shouldRefreshActivities = false;

      return _activityRecords;

    } on Exception catch (e) {
      return Future.error(e);

    } finally {
      _activitiesLoading = false;
      notifyListeners();
    }
  }

  /// Agrega un nuevo registro de actividad física.
  Future<int> createActivityRecord(ActivityRecord newRecord) async {
    
    try {
      int result = await SQLiteDB.instance.insert(newRecord);

      if (result >= 0) {
        _shouldRefreshActivities = true;
        return result;
      } else {
        throw Exception('No se pudo crear el registro de actividad fisica.');
      }
    }
    on Exception catch (e) {
      return Future.error(e);

    } finally {
      notifyListeners();
    }
  }

  Future<List<ActivityType>> _queryActivityTypes() async {
    try {
      _activityTypes.clear();

      final queryResults = await SQLiteDB.instance.select<ActivityType>(
        ActivityType.fromMap, 
        ActivityType.tableName, 
      );

      _activityTypes.addAll(queryResults);

      _shouldRefreshTypes = false;
      
      return _activityTypes;

    } on Exception catch (e) {
      return Future.error(e);
    } finally {
      notifyListeners();
    }
  }

  /// Crea un mapa en donde todos los valores de [_activityRecords] son agrupados
  /// por día.
  void _joinDailyRecords() {

    _activitiesByDay.clear();

    for (var hydrationRecord in _activityRecords) {

      DateTime recordDate = hydrationRecord.date;
      DateTime day = DateTime(recordDate.year, recordDate.month, recordDate.day);

      if (_activitiesByDay[day] == null) _activitiesByDay[day] = <ActivityRecord>[]; 

      _activitiesByDay[day]?.add(hydrationRecord);
    }
  }

  /// Crea un mapa con los [ActivityRecord] de la semana pasada, agrupados por 
  /// día.  
  Map<DateTime, List<ActivityRecord>> _getActivitiesFromPastWeek() {

    // Obtener la fecha de hoy y la fecha de siete días atrás.
    final DateTime now = DateTime.now();
    final DateTime aWeekAgo = DateTime(now.year, now.month, now.day - 6);

    Map<DateTime, List<ActivityRecord>> activitiesOfWeek = {};

    // Iterar los registros de los siete días más recientes, comenzando por el 
    // el día actual.
    for (int i = 0; i < 7; i++) {
      
      // Agregar [i] días a la fecha de hace siete días, hasta llegar al día actual.
      final DateTime pastDay = aWeekAgo.add(Duration( days: i ));

      final pastDayActivities = _activitiesByDay[pastDay];

      if (pastDayActivities != null) {
        // Existen registros de actividad para el día.
        activitiesOfWeek[pastDay] = List.from(pastDayActivities);

      } else {
        // No hubo actividades registradas, agregar una lista vacia.
        activitiesOfWeek[pastDay] = List.empty();
      }
    }

    // Asegurar que el mapa resultante tiene exactamente 7 entradas.
    assert(activitiesOfWeek.length == 7);

    return activitiesOfWeek;
  }

  /// Retorna una lista con las cantidades totales de kilocalorías quemadas por 
  /// día en las actividades de los 7 días más recientes.
  List<int> _previousSevenDaysTotals() {

    final List<int> kcalTotals = List.filled(7, 0);

    // Obtener la fecha de hoy y la fecha de siete días atrás.
    final DateTime now = DateTime.now();
    final DateTime aWeekAgo = DateTime(now.year, now.month, now.day - 7);

    // Obtener todos los registros de actividad en los últimos 7 días.
    final activitiesInPastWeek = _getActivitiesFromPastWeek();

    activitiesInPastWeek.forEach((day, activities) {
      // Sumar la cantidad de kCal quemadas de cada actividad en el día pasado.
      int totalKcal = 0;

      for (var activity in activities) {
        totalKcal += activity.kiloCaloriesBurned;
      }

      // El número de días entre el día de los registros y el día de hace una semana.
      // Este valor puede estar entre 0 y 6.
      final daysAgo = day.difference(aWeekAgo).inDays;

      // La diferencia en días es la posición en el array.
      kcalTotals[daysAgo -1] = totalKcal;
    });

    return kcalTotals.toList();
  }
}