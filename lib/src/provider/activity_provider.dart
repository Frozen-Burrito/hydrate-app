import 'package:flutter/material.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/provider/cache_state.dart';
import 'package:hydrate_app/src/utils/activities_with_routines.dart';
import 'package:hydrate_app/src/utils/datetime_extensions.dart';

/// Maneja el estado para los __[ActivityRecords]__, __[Routine]__ y 
/// __[ActivityTypes]__ asociados al perfil de usuario activo.
/// 
/// También permite sincronizar la información, ya sea de forma local en la BD o 
/// externa con el servicio web, cuando sea necesario.
class ActivityProvider extends ChangeNotifier {

  late final CacheState<List<ActivityRecord>> _activitiesCache = CacheState(
    fetchData: _queryActivityRecords,
    onDataRefreshed: (updatedRecords) {
      
      if (updatedRecords != null) {
        _joinDailyRecords(updatedRecords);
        _routineActivities.activities = updatedRecords;
      }
      notifyListeners();
    }
  );

  late final CacheState<List<ActivityType>> _activityTypesCache = CacheState(
    fetchData: _queryActivityTypes,
    onDataRefreshed: (_) => notifyListeners(),
  );

  late final CacheState<List<Routine>> _routinesCache = CacheState(
    fetchData: _queryRoutines,
    onDataRefreshed: (updatedRoutines) {

      if (updatedRoutines != null) {
        _routineActivities.routines = updatedRoutines;
      }
      notifyListeners();
    }
  );

  final RoutineActivities _routineActivities = RoutineActivities.empty();

  final Map<DateTime, List<ActivityRecord>> _activitiesByDay = {};

  /// Es [true] si el provider está cargando los [ActivityRecords].
  bool get hasActivityData => _activitiesCache.hasData;

  /// Retorna una colección con todos los [ActivityRecord] disponibles.
  /// Solo hace un query a la BD si ha habido modificaciones a los registros.
  Future<List<ActivityRecord>?> get activityRecords => _activitiesCache.data;

  /// Retorna una colección con todos los [ActivityType] disponibles.
  /// Solo hace un query a la BD si ha habido modificaciones a los datos.
  Future<List<ActivityType>?> get activityTypes => _activityTypesCache.data;

  /// Obtiene todos los [ActivityRecord], agrupados por día, con los registros 
  /// más recientes primero.
  Map<DateTime, List<ActivityRecord>> get activitiesByDay => _activitiesByDay;

  /// Obtiene todos los [ActivityRecord] de los 7 días más recientes, agrupados 
  /// por día, con los registros más recientes primero. 
  Future<Map<DateTime, List<ActivityRecord>>> get activitiesFromPastWeek async {
    return Future.value(_getActivitiesFromPastWeek());
  }

  Future<RoutineActivities> get routineActivities async {
    await _activitiesCache.data;
    await _routinesCache.data;

    return Future.value(_routineActivities);
  }

  /// El número máximo de actividades por día que otorgan una recompensa al 
  /// usuario por registrarlas.
  /// 
  /// Por ejemplo, si el usuario registra su cuarta actividad y [actPerDayWithReward]
  /// es 3, no debería recibir una recomensa.
  static const actPerDayWithReward = 3;

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

  /// Determina si en [activityRecords] existe uno o más registros de actividad
  /// que sean similares a [record], como es definido en [record.isSimilarTo(other)].
  /// 
  /// Si [onlyPastWeek] es __true__, sólo los registros de la semana pasada 
  /// serán analizadaos para obtener las actividades similares.
  /// 
  /// Retorna todos los registros en donde [record.isSimilarTo(other)] retorne 
  /// [true].
  List<ActivityRecord> isActivitySimilarToPrevious(
    ActivityRecord record, 
    { bool onlyPastWeek = false }
  ) {

    final activityRecords = onlyPastWeek 
      ? _getActivitiesFromPastWeek(includeToday: false) 
      : activitiesByDay;

    final similarActivities = <ActivityRecord>[];

    activityRecords.forEach((date, activities) { 
      final similarRecords = activities.where((activity) => record.isSimilarTo(activity));

      similarActivities.addAll(similarRecords);
    });

    return similarActivities;
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
      // Query a la BD, ordenando resultados por fecha y orden descendiente.
      final queryResults = await SQLiteDB.instance.select<ActivityRecord>(
        ActivityRecord.fromMap, 
        ActivityRecord.tableName, 
        orderByColumn: 'fecha',
        orderByAsc: false,
        includeOneToMany: true,
      );

      return queryResults.toList();

    } on Exception catch (e) {
      return Future.error(e);
    }
  }

  /// Agrega un nuevo registro de actividad física.
  Future<int> createActivityRecord(ActivityRecord newRecord) async {
    
    try {
      int result = await SQLiteDB.instance.insert(newRecord);

      if (result >= 0) {
        _activitiesCache.shouldRefresh();
        return result;
      } else {
        throw Exception('No se pudo crear el registro de actividad fisica.');
      }
    }
    on Exception catch (e) {
      return Future.error(e);
    }
  }

  Future<List<Routine>> _queryRoutines() async {
    try {
      final queryResults = await SQLiteDB.instance.select<Routine>(
        Routine.fromMap, 
        Routine.tableName, 
        includeOneToMany: false,
      );

      return queryResults.toList();

    } on Exception catch (e) {
      return Future.error(e);
    }
  }

  /// Agrega una nueva rutina de actividad física.
  Future<int> createRoutine(Routine newRoutine) async {
    
    try {
      int result = await SQLiteDB.instance.insert(newRoutine);

      if (result >= 0) {
        _routinesCache.shouldRefresh();
        return result;
      } else {
        throw Exception('No se pudo crear la nueva rutina.');
      }
    }
    on Exception catch (e) {
      return Future.error(e);
    }
  }

  Future<List<ActivityType>> _queryActivityTypes() async {
    try {
      final queryResults = await SQLiteDB.instance.select<ActivityType>(
        ActivityType.fromMap, 
        ActivityType.tableName, 
      );
      
      return queryResults.toList();

    } on Exception catch (e) {
      return Future.error(e);
    }
  }

  /// Crea un mapa en donde todos los valores de [_activityRecords] son agrupados
  /// por día.
  void _joinDailyRecords(List<ActivityRecord> allActivities) {

    _activitiesByDay.clear();

    for (var hydrationRecord in allActivities) {

      DateTime recordDate = hydrationRecord.date;
      DateTime day = DateTime(recordDate.year, recordDate.month, recordDate.day);

      if (_activitiesByDay[day] == null) _activitiesByDay[day] = <ActivityRecord>[]; 

      _activitiesByDay[day]?.add(hydrationRecord);
    }
  }

  /// Crea un mapa con los [ActivityRecord] de la semana pasada, agrupados por 
  /// día.  
  /// 
  /// Si __[includeToday]__ es __true__, los registros abarcarán 7 días, incluyendo
  /// el día actual. Por ejemplo, si el día actual es martes e __[includeToday]__ 
  /// es __true__, el resultado incluirá todos los registros hasta el miércoles
  /// de la semana pasada, sin incluir el martes pasado.
  Map<DateTime, List<ActivityRecord>> _getActivitiesFromPastWeek({ bool includeToday = true}) {

    int dayOffset = includeToday ? 0 : -1;

    // Obtener la fecha de hoy y la fecha de siete días atrás.
    final DateTime now = DateTime.now();
    final DateTime aWeekAgo = DateTime(now.year, now.month, now.day - 6 + dayOffset);

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

    // Obtener la fecha de siete días atrás.
    final aWeekAgo = DateTime.now().onlyDate.subtract(const Duration( days: 6 ));

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
      kcalTotals[daysAgo] = totalKcal;
    });

    return kcalTotals.toList();
  }
}