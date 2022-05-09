import 'package:flutter/material.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/models/activity_record.dart';
import 'package:hydrate_app/src/models/activity_type.dart';

class ActivityProvider extends ChangeNotifier {

  final List<ActivityRecord> _activityRecords = [];
  final List<ActivityType> _activityTypes = [];

  final List<int> _dailyKcalTotals = [];

  final Map<DateTime, List<ActivityRecord>> _activitiesByDay = {};

  bool _shouldRefreshActivities = true;
  bool _activitiesLoading = true;
  bool _shouldRefreshTypes = true;

  Future<List<ActivityRecord>> get activityRecords {

    if (_shouldRefreshActivities) {
      return _queryActivityRecords();
    }

    return Future.value(_activityRecords);
  }

  bool get activitiesLoading => _activitiesLoading;

  Future<List<ActivityType>> get activityTypes {

    if (_shouldRefreshTypes) {
      return _queryActivityTypes();
    }

    return Future.value(_activityTypes);
  }

  Map<DateTime, List<ActivityRecord>> get activitiesByDay => _activitiesByDay;

  List<int> get prevWeekDailyTotals => _previousSevenDaysTotals();

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

  /// Retorna una lista con la cantidad total de kilocalorías quemadas por día de los 
  /// 7 días más recientes.
  List<int> _previousSevenDaysTotals() {

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    _dailyKcalTotals.clear();

    for (int i = 0; i < 7; i++) {

      final DateTime previousDay = today.subtract(Duration( days: i));

      if (_activitiesByDay[previousDay] != null) {
        // Existen registros de actividad para el día.
        int totalKcal = 0;

        for (var record in _activitiesByDay[previousDay]!) {
          totalKcal += record.kiloCaloriesBurned;
        }

        _dailyKcalTotals.add(totalKcal);
      } else {
        // No hubo actividades registradas, agregar 0 por defecto.
        _dailyKcalTotals.add(0);
      }
    }

    assert(_dailyKcalTotals.length == 7);

    return _dailyKcalTotals.reversed.toList();
  }
}