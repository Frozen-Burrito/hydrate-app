import 'dart:io';

import 'package:flutter/material.dart';

import 'package:hydrate_app/src/api/data_api.dart';
import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/db/where_clause.dart';
import 'package:hydrate_app/src/exceptions/api_exception.dart';
import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/models/routine_occurrence.dart';
import 'package:hydrate_app/src/services/cache_state.dart';
import 'package:hydrate_app/src/utils/activities_with_routines.dart';
import 'package:hydrate_app/src/utils/datetime_extensions.dart';

/// Maneja el estado para los __[ActivityRecords]__, __[Routine]__ y 
/// __[ActivityTypes]__ asociados al perfil de usuario activo.
/// 
/// También permite sincronizar la información, ya sea de forma local en la BD o 
/// externa con el servicio web, cuando sea necesario.
class ActivityService extends ChangeNotifier {

  /// El ID del perfil local del usuario actual.
  int _profileId = -1;

  void forProfile(int newProfileId) {
    if (newProfileId != _profileId) {
      _profileId = newProfileId;

      // Refrescar los datos que dependen del perfil de usuario activo.
      _activitiesCache.shouldRefresh();
      _routinesCache.shouldRefresh();
    }
  }

  late final CacheState<List<ActivityRecord>> _activitiesCache = CacheState(
    fetchData: _queryActivityRecords,
    onDataRefreshed: (updatedRecords) {
      
      if (updatedRecords != null) {
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

  final Set<Routine> _routinesPendingSync = <Routine>{};
  final Set<ActivityRecord> _activityRecordsPendingSync = <ActivityRecord>{};

  final RoutineActivities _routineActivities = RoutineActivities.empty();

  final Map<DateTime, List<RoutineOccurrence>> _activitiesByDay = {};

  static const int maxHealthDataPointsPerFetch = 100;

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
  Map<DateTime, List<RoutineOccurrence>> get activitiesByDay => _activitiesByDay;

  /// Obtiene todos los [ActivityRecord] de los 7 días más recientes, agrupados 
  /// por día, con los registros más recientes primero. 
  Future<List<List<RoutineOccurrence>>> get activitiesFromPastWeek {
    final now = DateTime.now();
    final aWeekAgo = now.onlyDate.subtract(const Duration( days: 7 ));
    
    return _getActivitiesInDateRange(
      begin: aWeekAgo,
      end: now,
      sortByDateAscending: false,
    );
  }

  Future<int> get activitiesToday => _getNumberOfActivitiesRecordedToday();

  Future<RoutineActivities> get routineActivities async {
    await _activitiesCache.data;
    await _routinesCache.data;

    _joinDailyRecords(_routineActivities.activitiesWithRoutines);

    return Future.value(_routineActivities);
  }

  /// Calcula la cantidad total de kilocalorías quemadas en actividad física por
  /// cada uno de los 7 días anteriores.
  /// 
  /// El resultado tiene exactamente 7 elementos, con los días más recientes al 
  /// final. Si el día actual fuera martes, el primer elemento correspondería al 
  /// total del miércoles de la semana pasada y el último al día actual.
  Future<List<int>> get prevWeekKcalTotals => _previousSevenDaysTotals();

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
  bool hasExhaustingActivities(List<List<RoutineOccurrence>> activityRecords) {

    bool hasExhausting = false;

    // Solo buscar actividades si activityRecords no es nulo.
    for (final activitiesInDay in activityRecords) {
      if (activitiesInDay.any((record) => record.activity.isExhausting)) {
        hasExhausting = true;
        break;
      }
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
  Future<List<ActivityRecord>> isActivitySimilarToPrevious(
    ActivityRecord activityRecord, 
    { bool onlyPastWeek = false }
  ) async {

    final yesterday = DateTime.now().subtract(const Duration( days: 1 ));
    final aWeekAgo = yesterday.onlyDate.subtract(const Duration( days: 6 ));

    final activityRecords = onlyPastWeek 
      ? await _getActivitiesInDateRange(begin: aWeekAgo, end: yesterday) 
      : activitiesByDay.values.toList();

    final similarActivities = <ActivityRecord>[];

    for (final activitiesForDay in activityRecords) {
      final similarRecordsInDay = activitiesForDay
        .where((record) => record.activity.routine == null && activityRecord.isSimilarTo(record.activity))
        .map((similarRecord) => similarRecord.activity); 

      similarActivities.addAll(similarRecordsInDay);
    }

    return similarActivities;
  }

  Future<bool> shouldGiveRewardForNewActivity() async {
    final int numOfActivitiesToday = await _getNumberOfActivitiesRecordedToday();

    return numOfActivitiesToday <= ActivityService.actPerDayWithReward;
  }

  Future<List<ActivityRecord>> _queryActivityRecords() async {
    try {
      // Obtener solo los registros de actividad asociados con el perfil.
      final where = [
        WhereClause(ActivityRecord.profileIdPropName, _profileId.toString())
      ];

      // Query a la BD, ordenando resultados por fecha y orden descendiente.
      final queryResults = await SQLiteDB.instance.select<ActivityRecord>(
        ActivityRecord.fromMap, 
        ActivityRecord.tableName, 
        orderByColumn: ActivityRecord.datePropName,
        orderByAsc: false,
        includeOneToMany: true,
        where: where,
      );

      return queryResults.toList();

    } on Exception catch (e) {
      return Future.error(e);
    }
  }

  Future<Iterable<int>> saveActivityRecords(Iterable<ActivityRecord> activityRecords) async {

    final results = <int>[];

    for (final newActivityRecord in activityRecords) {
      final int result = await SQLiteDB.instance.insert(newActivityRecord);

      if (result >= 0) {
        results.add(result);
      }
    }

    if (results.isNotEmpty) _activitiesCache.shouldRefresh();

    return results;
  }

  /// Persiste a [newActivityRecord] en la base de datos.
  /// 
  /// Cuando [newActivityRecord] es persistido con éxito, este método refresca 
  /// la lista de registros de hidratación de [activityRecords] y retorna el 
  /// ID de [newActivityRecord]. 
  /// 
  /// Si [newActivityRecord] no pudo ser persistido, este método retorna un 
  /// entero negativo.
  Future<int> createActivityRecord(ActivityRecord newActivityRecord) async {
    // Asegurar que el nuevo registro de actividad sea asociado con el 
    // perfil de usuario activo.
    newActivityRecord.profileId = _profileId;

    final int createdActivityRecordId = await SQLiteDB.instance.insert(newActivityRecord);

    if (createdActivityRecordId >= 0) {
      newActivityRecord.id = createdActivityRecordId;
      // Refrescar el cache la próxima vez que sea utilizado.
      _activitiesCache.shouldRefresh();

      _activityRecordsPendingSync.add(newActivityRecord);
    }

    return createdActivityRecordId;
  }

  Future<void> syncLocalActivityRecordsWithAccount() async {
    if (DataApi.instance.isAuthenticated) {
      try {
        await DataApi.instance.updateData<ActivityRecord>(
          data: _activityRecordsPendingSync,
          mapper: (activityRecord, _) => activityRecord.toJson(),
        );

        _activityRecordsPendingSync.clear();
      //TODO: notificar al usuario que su perfil no pudo ser sincronizado.
      } on ApiException catch (ex) {
        debugPrint("Error al sincronizar cambios a perfil ($ex)");
      } on SocketException catch (ex) {
        debugPrint("Error al sincronizar cambios a perfil, el dispositivo tiene conexion? ($ex)");
      } on IOException catch (ex) {
        debugPrint("Error al sincronizar cambios a perfil, el dispositivo tiene conexion? ($ex)");
      }
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
    // Asegurar que el nuevo registro de actividad sea asociado con el 
    // perfil de usuario activo.
    newRoutine.profileId = _profileId;
  
    final int newRoutineId = await SQLiteDB.instance.insert(newRoutine);

    if (newRoutineId >= 0) {
      newRoutine.id = newRoutineId;
      _routinesCache.shouldRefresh();

      if (DataApi.instance.isAuthenticated) _routinesPendingSync.add(newRoutine);
    } 
    
    return newRoutineId;
  }

  Future<void> syncLocalRoutinesWithAccount() async {
    if (DataApi.instance.isAuthenticated) {
      try {
        await DataApi.instance.updateData<Routine>(
          data: _routinesPendingSync,
          mapper: (routine, mapOptions) => routine.toMap(options: mapOptions),
        );

        _routinesPendingSync.clear();
      //TODO: notificar al usuario que su perfil no pudo ser sincronizado.
      } on ApiException catch (ex) {
        debugPrint("Error al sincronizar cambios a perfil ($ex)");
      } on SocketException catch (ex) {
        debugPrint("Error al sincronizar cambios a perfil, el dispositivo tiene conexion? ($ex)");
      } on IOException catch (ex) {
        debugPrint("Error al sincronizar cambios a perfil, el dispositivo tiene conexion? ($ex)");
      }
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
  void _joinDailyRecords(List<RoutineOccurrence> allActivities) {

    _activitiesByDay.clear();

    for (var activityRecord in allActivities) {

      DateTime recordDate = activityRecord.date;
      DateTime day = DateTime(recordDate.year, recordDate.month, recordDate.day);

      if (_activitiesByDay[day] == null) _activitiesByDay[day] = <RoutineOccurrence>[]; 

      _activitiesByDay[day]?.add(activityRecord);
    }
  }

  Future<List<List<RoutineOccurrence>>> _getActivitiesInDateRange({
    required DateTime begin, 
    required DateTime end,
    bool sortByDateAscending = true,
  }) async {
    // Determinar si hace falta invertir las fechas para que begin sea antes
    // que end.
    if (begin.isAfter(end)) {
      // Invertir las fechas para formar un rango de fechas válido.
      final tempDate = begin;
      begin = end;
      end = tempDate;
    }

    assert(begin.isBefore(end), "'beginDate' debe ser antes que 'endDate'");

    final int daysBetweenDates = (end.difference(begin).inHours / 24).ceil();

    final List<List<RoutineOccurrence>> activitiesInDateRange = List
      .filled(daysBetweenDates, <RoutineOccurrence>[], growable: false);

    await _activitiesCache.data;
    await _routinesCache.data;

    _joinDailyRecords(_routineActivities.activitiesWithRoutines);

    for (int i = 0; i < daysBetweenDates; i++) {

      final DateTime previousDay = end.subtract(Duration( days: i)).onlyDate;

      // Asignar las actividades realizadas el día i.
      activitiesInDateRange[i] = _activitiesByDay[previousDay] ?? const <RoutineOccurrence>[];
    }

    // Asegurar que la lista tenga una colección de actividades por cada día en el rango.
    assert(activitiesInDateRange.length == daysBetweenDates);

    // Retornar los totales, ordenados con fecha ascendiente o descendiente, según
    // isSortByDateDescending.
    return sortByDateAscending 
      ? activitiesInDateRange
      : activitiesInDateRange.reversed.toList(); 
  }

  Future<int> _getNumberOfActivitiesRecordedToday() async {
    final now = DateTime.now();

    final activitiesToday = await _getActivitiesInDateRange(
      begin: now.onlyDate,
      end: now,
    );

    final int activityCount = activitiesToday.isNotEmpty ? activitiesToday.first.length : 0;

    return activityCount;
  }

  /// Retorna una lista con las cantidades totales de kilocalorías quemadas por 
  /// día en las actividades de los 7 días más recientes.
  Future<List<int>> _previousSevenDaysTotals() async {
    // Obtener la fecha de siete días atrás.
    final today = DateTime.now();
    final aWeekAgo = today.onlyDate.subtract(const Duration( days: 6 ));

    final List<int> kcalTotals = List.filled(7, 0, growable: false);

    // Obtener todos los registros de actividad en los últimos 7 días.
    final activitiesInPastWeek = await _getActivitiesInDateRange(
      begin: aWeekAgo,
      end: today,
      sortByDateAscending: false,
    );

    for (int i = 0; i < activitiesInPastWeek.length; i++) {
      for (int j = 0; j < activitiesInPastWeek[i].length; j++) {
        kcalTotals[i] += activitiesInPastWeek[i][j].activity.kiloCaloriesBurned;
      }
    }

    return kcalTotals.toList();
  }
}
