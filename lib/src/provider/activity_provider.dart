import 'package:flutter/material.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/models/activity_record.dart';
import 'package:hydrate_app/src/models/activity_type.dart';
import 'package:hydrate_app/src/provider/provider_data_state.dart';

class ActivityProvider extends ChangeNotifier {

  final List<ActivityRecord> _activityRecords = [];
  final List<ActivityType> _activityTypes = [];

  final Map<DateTime, List<ActivityRecord>> _activitiesByDay = {};

  DataState _activityDataState = DataState.initial;
  DataState _actTypesDataState = DataState.initial;

  List<ActivityRecord> get activityRecords {

    if (_activityDataState != DataState.loading && _activityDataState != DataState.loaded) {
      _queryActivityRecords();
    }

    return _activityRecords;
  }

  List<ActivityType> get activityTypes {

    if (_actTypesDataState != DataState.loading && _actTypesDataState != DataState.loaded) {
      _queryActivityTypes();
    }

    return _activityTypes;
  }

  Map<DateTime, List<ActivityRecord>> get activitiesByDay => _activitiesByDay;

  List<int> get weekDailyTotals => _previousSevenDaysTotals();

  bool get isLoading => _activityDataState == DataState.loading;

  bool get hasError => _activityDataState == DataState.error;

  bool get areTypesLoading => _actTypesDataState == DataState.loading;

  bool get doTypesHaveError => _actTypesDataState == DataState.error;

  Future<void> _queryActivityRecords() async {
    try {
      _activityDataState = DataState.loading;
      _activityRecords.clear();

      final queryResults = await SQLiteDB.instance.select<ActivityRecord>(
        ActivityRecord.fromMap, 
        ActivityRecord.tableName, 
        orderByColumn: 'fecha',
        orderByAsc: false,
        includeOneToMany: true,
      );

      _activityRecords.addAll(queryResults);

      _joinDailyRecords();

      _activityDataState = DataState.loaded;

    } on Exception catch (_) {
      _activityDataState = DataState.error;

    } finally {
      notifyListeners();
    }
  }

  Future<int> createActivityRecord(ActivityRecord newRecord) async {
    
    try {
      int result = await SQLiteDB.instance.insert(newRecord);

      if (result >= 0) {
        _activityDataState = DataState.initial;
        return result;
      } else {
        throw Exception('Error creando el registro de actividad fisica.');
      }
    }
    on Exception catch (e) {
      _activityDataState = DataState.error;
      print(e);

    } finally {
      notifyListeners();
    }

    return -1;
  }

  Future<void> _queryActivityTypes() async {
    try {
      _actTypesDataState = DataState.loading;
      _activityTypes.clear();

      final queryResults = await SQLiteDB.instance.select<ActivityType>(
        ActivityType.fromMap, 
        ActivityType.tableName,
      );

      _activityTypes.addAll(queryResults);

      _actTypesDataState = DataState.loaded;

    } on Exception catch (_) {
      _actTypesDataState = DataState.error;

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

    final List<int> recentTotals = [];
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < 7; i++) {

      final DateTime previousDay = today.subtract(Duration( days: i));

      if (_activitiesByDay[previousDay] != null) {
        // Existen registros de actividad para el día.
        int totalKcal = 0;

        for (var record in _activitiesByDay[previousDay]!) {
          totalKcal += record.kiloCaloriesBurned;
        }

        recentTotals.add(totalKcal);
      } else {
        // No hubo actividades registradas, agregar 0 por defecto.
        recentTotals.add(0);
      }
    }

    assert(recentTotals.length == 7);

    return recentTotals.reversed.toList();
  }
}