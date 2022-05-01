import 'dart:math';
import 'package:flutter/material.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/models/hydration_record.dart';

class HydrationRecordProvider extends ChangeNotifier {

  final List<HydrationRecord> _hydrationRecords = [];

  final Map<DateTime, List<HydrationRecord>> _dailyHydration = {};

  bool _recordsQueried = false;
  bool _isLoading = false;
  bool _hasError = false;

  List<HydrationRecord> get hydrationRecords {

    if (!_recordsQueried && !_isLoading) {
      _queryHydrationRecords();
    }

    return _hydrationRecords;
  }

  Map<DateTime, List<HydrationRecord>> get dailyHidration => _dailyHydration;

  List<int> get weekDailyTotals => _previousSevenDaysTotals();

  bool get isLoading => _isLoading;

  bool get hasError => _hasError;

  //TODO: Quitar esta funcion helper temporal.
  Future<void> insertTestRecords() async {
    final rand = Random();

    final queryResults = await SQLiteDB.instance.select<HydrationRecord>(
        HydrationRecord.fromMap
    );

    final existingRecords = List<HydrationRecord>.from(queryResults);

    for (var i = 0; i < existingRecords.length; i++) {
      await SQLiteDB.instance.delete(HydrationRecord.tableName, existingRecords[i].id);
    }

    DateTime lastDate = DateTime.now();

    // Crear registros de hidratacion aleatorios para pruebas.
    for (var i = 0; i < 10; i++) {
      lastDate = lastDate.subtract(Duration(hours: 8 - rand.nextInt(3)));

      final randRecord = HydrationRecord(
        amount: rand.nextInt(200), 
        batteryPercentage: rand.nextInt(100), 
        date: lastDate
      );

      await SQLiteDB.instance.insert(randRecord);
    }

    _queryHydrationRecords();
  }

  Future<void> _queryHydrationRecords() async {
    try {
      _isLoading = true;
      _hydrationRecords.clear();

      final queryResults = await SQLiteDB.instance.select<HydrationRecord>(
        HydrationRecord.fromMap, 
        orderByColumn: 'fecha',
        orderByAsc: false
      );

      _hydrationRecords.addAll(queryResults);

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

  /// Crea un mapa en donde todos los valores de [_hydrationRecords] son agrupados
  /// por día.
  void _joinDailyRecords() {

    _dailyHydration.clear();

    for (var hydrationRecord in _hydrationRecords) {

      DateTime recordDate = hydrationRecord.date;
      DateTime day = DateTime(recordDate.year, recordDate.month, recordDate.day);

      if (_dailyHydration[day] == null) _dailyHydration[day] = <HydrationRecord>[]; 

      _dailyHydration[day]?.add(hydrationRecord);
    }
  }

  /// Retorna una lista con la cantidad total en ml diaria de consumo de agua de los 
  /// 7 días más recientes.
  List<int> _previousSevenDaysTotals() {

    final List<int> recentTotals = [];
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < 7; i++) {

      final DateTime previousDay = today.subtract(Duration( days: i));

      if (_dailyHydration[previousDay] != null) {
        // Existen registros de hidratación para el día.
        int totalMililiters = 0;

        for (var record in _dailyHydration[previousDay]!) {
          totalMililiters += record.amount;
        }
        // _dailyHydration[previousDay].reduce((total, registro) => total + registro);

        recentTotals.add(totalMililiters);
      } else {
        // No hubo consumo registrado, agregar 0 por default.
        recentTotals.add(0);
      }
    }

    assert(recentTotals.length == 7);

    return recentTotals.reversed.toList();
  }
}