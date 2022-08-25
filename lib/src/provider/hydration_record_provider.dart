import 'dart:math';
import 'package:flutter/material.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/models/enums/time_term.dart';
import 'package:hydrate_app/src/models/goal.dart';
import 'package:hydrate_app/src/models/hydration_record.dart';
import 'package:hydrate_app/src/provider/cache_state.dart';
import 'package:hydrate_app/src/utils/datetime_extensions.dart';

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

    await _hydrationRecordsCache.data;

    return _dailyHydration;
  }

  Future<List<int>> get pastWeekMlTotals => _totalsFromPrevDaysInMl(7, isSortByDateAscending: false);

  //TODO: Quitar esta funcion helper temporal.
  Future<void> insertTestRecords() async {

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

    final rand = Random();

    // Crear registros de hidratacion aleatorios para pruebas.
    for (var i = 0; i < 20; i++) {

      lastDate = lastDate.subtract(Duration(hours: 8 - rand.nextInt(3)));

      final randRecord = HydrationRecord.random(rand, lastDate, 0);

      newRecords.add(randRecord);
    }

    await saveHydrationRecords(newRecords);
  }

  /// Guarda una coleccion de registros de hidratación en la base de datos.
  Future<List<int>> saveHydrationRecords(List<HydrationRecord> newRecords) async {
    try {
      final results = <int>[];

      for (var newRecord in newRecords) { 
        int result = await saveHydrationRecord(newRecord, refreshImmediately: false);

        if (result < 0) {
          throw Exception('No se pudo crear el registro de  hidratacion.');
        } else {
          results.add(result);
        }
      }
      
      _hydrationRecordsCache.refresh();
      return results;
    }
    on Exception catch (e) {
      return Future.error(e);
    }
  }

  /// Guarda un nuevo registro de hidratación en la base de datos.
  /// 
  /// Retorna el ID del [HydrationRecord] persistido con éxito, o -1 si el 
  /// registro no pudo ser guardado.
  Future<int> saveHydrationRecord(
    HydrationRecord newRecord, 
    { refreshImmediately = true }
  ) async {
    
    try {
      int result = await SQLiteDB.instance.insert(newRecord);

      if (result >= 0) {
        if (refreshImmediately) {
          // Si se solicita, refrescar el cache inmediatamente.
          _hydrationRecordsCache.refresh();
        } else {
          // Si no, usar refresh perezozo.
          _hydrationRecordsCache.shouldRefresh();
        }
        
        return result;
      } else {
        //TODO: Evitar lanzar una excepcion para cacharla inmediatamente después.
        throw Exception('No se pudo crear el registro de actividad fisica.');
      }
    }
    on Exception catch (e) {
      print(e);
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

  /// Calcula el progreso de varios [Goal], invocando [getGoalProgressInMl()] 
  /// para obtener el progreso de cada meta.
  /// 
  /// La longitud de la lista resultante será igual a [goals.length].
  Future<Map<Goal, int>> getGoalsProgressValuesInMl(List<Goal> goals) async {

    final Map<Goal, int> progressForGoals = <Goal, int>{};

    for (final goal in goals) {
      // Obtener el progreso hacia la meta y asignarlo a la lista de totales.
      progressForGoals[goal] = await getGoalProgressInMl(goal);
    }

    assert(progressForGoals.length == goals.length);

    print("Progress towards goals: " + progressForGoals.toString());

    return progressForGoals;
  }

  /// Obtiene el consumo total de agua diario para __[numberOfDays]__ días anteriores 
  /// al día de hoy. 
  /// 
  /// La longitud de la lista retornada será __igual__ a __[numberOfDays]__.
  /// 
  /// Por ejemplo, si el día actual es martes y __[numberOfDays]__ = 3, este método
  /// retornará una lista con tres elementos, en la que el primer elemento es el
  /// total del día actual (martes) y el último es el total del domingo pasado.
  /// 
  /// Si el usuario no consumió agua en uno de los días incluidos en el rango, 
  /// el elemento de la lista que corresponde a ese día tendrá un valor de 0.
  /// 
  /// Si __[daysOffset]__ es mayor a 0, en vez de comenzar por el día actual, los
  /// totales comenzarán en la fecha del día de hoy menos __[daysOffset]__ días.  
  Future<List<int>> _totalsFromPrevDaysInMl(
    int numberOfDays, { 
      int daysOffset = 0, 
      bool isSortByDateAscending = true, 
  }) async {

    // Comprobar que [daysOffset] no sea negativo.
    assert(daysOffset >= 0);

    // Obtener la fecha de inicio de selección de totales.
    final DateTime startDate = DateTime.now().onlyDate
      .subtract(Duration( days: daysOffset ));

    // Inicializar la lista con los totales.
    final List<int> recentTotals = List.filled(numberOfDays, 0, growable: false);

    // Obtener registros de hidratación, ordenados por día.
    await _hydrationRecordsCache.data;

    for (int i = 0; i < numberOfDays; i++) {

      final DateTime previousDay = startDate.subtract(Duration( days: i));

      if (_dailyHydration[previousDay] != null) {
        // Existen registros de hidratación para el día. 
        // Obtener las cantidades de los registros de hidratacion y agregarlas. 
        int totalMililiters = _dailyHydration[previousDay]!
            .map((registroHidratacion) => registroHidratacion.amount)
            .reduce((total, cantidadConsumida) => total += cantidadConsumida);

        // Asignar el consumo total para el día i.
        recentTotals[i] = totalMililiters;
      }
    }

    // Asegurar que la lista de totales tenga un elemento por cada día.
    assert(recentTotals.length == numberOfDays);

    // Retornar los totales, ordenados con fecha ascendiente o descendiente, según
    // isSortByDateDescending.
    return isSortByDateAscending 
      ? recentTotals
      : recentTotals.reversed.toList(); 
  }

  /// Calcula el progreso de una [Goal] de hidratación, según su plazo temporal,
  /// cantidad objetivo en mililitros, y los [HydrationRecords].
  /// 
  /// Si ya se ha calculado el progreso de una meta anterior con un plazo menor, 
  /// se puede especificar el total para el número de días de la meta anterior.
  /// Así, si una meta previa diaria lleva 70 ml de progreso en 1 día, una fecha
  /// semanal puede usar ese total para su primer día. 
  Future<int> getGoalProgressInMl(Goal goal, { int? previousTotal, int dayOffset = 0 }) async {

    // Determinar el número de días de registros necesarios (segun plazo, fecha
    // de inicio de la meta y la fecha de hoy).
    final DateTime today = DateTime.now();
    final DateTime goalStartDate = goal.startDate!;
    final diffBetweenDates = today.difference(goalStartDate);
    
    // El número de días de registros de hidratación necesarios para calcular 
    // el progreso.
    int daysOfRecords = min(diffBetweenDates.inDays, goal.term.inDays);

    // Obtener los totales de registros de hidratación con la antiguedad para 
    // la meta.
    final totals = await _totalsFromPrevDaysInMl(daysOfRecords, daysOffset: dayOffset);

    // Agregar los totales diarios.
    int currentProgressMl = totals.isNotEmpty
      ? totals.reduce((value, dayTotal) => value + dayTotal)
      : 0;

    if (previousTotal != null) {
      // Si hay un total ya calculado, agregarlo a currentProgressMl.
      currentProgressMl += previousTotal;
    }

    // Retornar el progreso del usuario hacia la meta, en mililitros.
    return currentProgressMl;
  }
}