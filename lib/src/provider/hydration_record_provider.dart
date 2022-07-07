import 'dart:math';
import 'package:flutter/material.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/models/hydration_record.dart';
import 'package:hydrate_app/src/provider/cache_state.dart';

class HydrationRecordProvider extends ChangeNotifier {

  late final CacheState<List<HydrationRecord>> _hydrationRecordsCache = CacheState(
    fetchData: _fetchHydrationRecords,
    onDataRefreshed: (updatedRecords) {

      _sortRecordsByDay(updatedRecords ?? <HydrationRecord>[]);
      notifyListeners();
    }
  );

  final Map<DateTime, List<HydrationRecord>> _dailyHydration = {};

  bool get hasHydrationData => _hydrationRecordsCache.hasData;

  Future<List<HydrationRecord>?> get allRecords => _hydrationRecordsCache.data;

  Future<Map<DateTime, List<HydrationRecord>>> get dailyHidration async {

    final records = await _hydrationRecordsCache.data;

    if (records != null) {
      _sortRecordsByDay(records);
    }

    return _dailyHydration;
  }

  List<int> get pastWeekMlTotals => _previousSevenDaysTotals();

  //TODO: Quitar esta funcion helper temporal.
  Future<void> insertTestRecords() async {
    final rand = Random();

    final queryResults = await SQLiteDB.instance.select<HydrationRecord>(
        HydrationRecord.fromMap,
        HydrationRecord.tableName
    );

    final existingRecords = List<HydrationRecord>.from(queryResults);

    for (var i = 0; i < existingRecords.length; i++) {
      await SQLiteDB.instance.delete(HydrationRecord.tableName, existingRecords[i].id);
    }

    DateTime lastDate = DateTime.now();

    final newRecords = <HydrationRecord>[];

    // Crear registros de hidratacion aleatorios para pruebas.
    for (var i = 0; i < 10; i++) {
      lastDate = lastDate.subtract(Duration(hours: 8 - rand.nextInt(3)));

      final randRecord = HydrationRecord(
        amount: rand.nextInt(200), 
        batteryPercentage: rand.nextInt(100), 
        date: lastDate
      );

      newRecords.add(randRecord);
    }

    await saveHydrationRecords(newRecords);
  }

  /// Guarda una coleccion de registros de hidratación en la base de datos.
  Future<List<int>> saveHydrationRecords(List<HydrationRecord> newRecords) async {
    try {
      final results = <int>[];

      for (var newRecord in newRecords) { 
        int result = await SQLiteDB.instance.insert(newRecord);

        if (result < 0) {
          throw Exception('No se pudo crear el registro de  hidratacion.');
        } else {
          results.add(result);
        }
      }
      
      _hydrationRecordsCache.shouldRefresh();
      return results;
    }
    on Exception catch (e) {
      return Future.error(e);
    }
  }

  /// Guarda un nuevo registro de hidratación en la base de datos.
  Future<int> saveHydrationRecord(HydrationRecord newRecord) async {
    
    try {
      int result = await SQLiteDB.instance.insert(newRecord);

      if (result >= 0) {
        _hydrationRecordsCache.shouldRefresh();
        return result;
      } else {
        throw Exception('No se pudo crear el registro de actividad fisica.');
      }
    }
    on Exception catch (e) {
      return Future.error(e);
    }
  }

  /// Obtiene todos los registros de hidratación de la base de datos.
  /// 
  /// Los registros son ordendos cronológicamente por sus fechas, con los más 
  /// recientes primero.
  Future<List<HydrationRecord>> _fetchHydrationRecords() async {

    try {
      // Query a la BD.
      final queryResults = await SQLiteDB.instance.select<HydrationRecord>(
        HydrationRecord.fromMap, 
        HydrationRecord.tableName, 
        orderByColumn: 'fecha',
        orderByAsc: false
      );

      return queryResults.toList();

    } on Exception catch (e) {
      return Future.error(e);
    } 
  }

  /// Crea un mapa en donde todos los valores de [_hydrationRecords] son agrupados
  /// por día.
  Map<DateTime, List<HydrationRecord>> _sortRecordsByDay(List<HydrationRecord> records) {

    _dailyHydration.clear();

    for (var hydrationRecord in records) {

      DateTime recordDate = hydrationRecord.date;
      DateTime day = DateTime(recordDate.year, recordDate.month, recordDate.day);

      if (_dailyHydration[day] == null) _dailyHydration[day] = <HydrationRecord>[]; 

      _dailyHydration[day]?.add(hydrationRecord);
    }

    return _dailyHydration;
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