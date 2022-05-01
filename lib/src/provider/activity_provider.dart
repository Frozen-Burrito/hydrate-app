import 'dart:math';
import 'package:flutter/material.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/models/activity_record.dart';
import 'package:hydrate_app/src/models/activity_type.dart';

class ActivityProvider extends ChangeNotifier {

  final List<ActivityRecord> _activityRecords = [];
  final List<ActivityType> _activityTypes = [];

  final Map<DateTime, List<ActivityRecord>> _activitiesByDay = {};

  bool _recordsQueried = false;
  bool _typesQueried = false;
  bool _isLoading = false;
  bool _areTypesLoading = false;
  bool _hasError = false;

  List<ActivityRecord> get activityRecords {

    if (!_recordsQueried && !_isLoading) {
      _queryActivityRecords();
    }

    return _activityRecords;
  }

  List<ActivityType> get activityTypes {

    if (!_typesQueried && !_areTypesLoading) {
      _queryActivityRecords();
    }

    return _activityTypes;
  }

  Map<DateTime, List<ActivityRecord>> get activitiesByDay => _activitiesByDay;

  List<int> get weekDailyTotals => _previousSevenDaysTotals();

  bool get isLoading => _isLoading;

  bool get hasError => _hasError;

  bool get areTypesLoading => _areTypesLoading;

  Future<void> _queryActivityRecords() async {
    try {
      _isLoading = true;
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

      _isLoading = false;
      _hasError = false;

    } on Exception catch (_) {
      _hasError = true;

    } finally {
      _recordsQueried = true;
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