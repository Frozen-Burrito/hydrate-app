import 'dart:math';
import 'package:flutter/material.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/db/where_clause.dart';
import 'package:hydrate_app/src/models/enums/time_term.dart';
import 'package:hydrate_app/src/models/goal.dart';
import 'package:hydrate_app/src/models/hydration_record.dart';
import 'package:hydrate_app/src/provider/cache_state.dart';
import 'package:hydrate_app/src/utils/datetime_extensions.dart';

class HydrationRecordProvider extends ChangeNotifier {

  HydrationRecordProvider.withProfile(int profileId) : _profileId = profileId;

  /// El ID del perfil local del usuario actual.
  final int _profileId;

  late final CacheState<List<HydrationRecord>> _hydrationRecordsCache = CacheState(
    fetchData: _fetchHydrationRecords,
    onDataRefreshed: (_) => notifyListeners(),
  );

  bool get hasHydrationData => _hydrationRecordsCache.hasData;

  Future<List<HydrationRecord>?> get allRecords => _hydrationRecordsCache.data;

  Future<List<HydrationRecord>> get recordsInPast24h async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    final hydrationRecords = (await _hydrationRecordsCache.data) ?? const <HydrationRecord>[];

    final recordsAfterYesterday = hydrationRecords
        .where((r) => r.date.isAfter(yesterday) && r.date.isBefore(now));

    return recordsAfterYesterday.toList();
  }

  Future<List<BatteryRecord>> get last24hBatteryUsage => _getBatteryRecordsSinceYesterday();

  Future<Map<DateTime, List<HydrationRecord>>> get dailyHidration => _groupDailyHydration();

  Future<List<int>> get pastWeekMlTotals {

    final now = DateTime.now();

    return _totalsFromPrevDaysInMl(
      begin: now.subtract(const Duration( days: 6 )).onlyDate, 
      end: now,
      sortByDateAscending: false
    );
  }

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

      final randRecord = HydrationRecord.random(rand, lastDate, _profileId);

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
  Future<int> saveHydrationRecord(HydrationRecord newRecord, { refreshImmediately = true }) async {
    
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
      // Formar el WHERE para el query.
      final where = WhereClause(HydrationRecord.profileIdFieldName, _profileId.toString());

      // Query a la BD.
      final queryResults = await SQLiteDB.instance.select<HydrationRecord>(
        HydrationRecord.fromMap, 
        HydrationRecord.tableName, 
        orderByColumn: HydrationRecord.dateFieldName,
        orderByAsc: false,
        where: [ where ],
      );

      return queryResults.toList();

    } on Exception catch (e) {
      return Future.error(e);
    } 
  }

  Future<Map<DateTime, List<HydrationRecord>>> _groupDailyHydration() async {
    // Obtener los registros de hidratación más recientes y ordenarlos.
    final hydrationRecords = await _hydrationRecordsCache.data;

    return _sortRecordsByDay(hydrationRecords ?? <HydrationRecord>[]);
  }

  /// Crea un mapa en donde todos los valores de [_hydrationRecords] son agrupados
  /// por día.
  Map<DateTime, List<HydrationRecord>> _sortRecordsByDay(List<HydrationRecord> records) {

    final dailyHydration = <DateTime, List<HydrationRecord>>{};

    for (final hydrationRecord in records) {

      final DateTime recordDate = hydrationRecord.date.onlyDate;

      if (dailyHydration[recordDate] == null) {
        dailyHydration[recordDate] = <HydrationRecord>[];
      } 

      dailyHydration[recordDate]?.add(hydrationRecord);
    }

    return dailyHydration;
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

  Future<List<BatteryRecord>> _getBatteryRecordsSinceYesterday() async {

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    final batteryRecords = <BatteryRecord>[];

    final hydrationRecords = (await _hydrationRecordsCache.data) ?? <HydrationRecord>[];

    final recordsAfterYesterday = hydrationRecords.where((r) => r.date.isAfter(yesterday));

    if (recordsAfterYesterday.isNotEmpty) {

      batteryRecords.addAll(recordsAfterYesterday
        .where((r) => r.date.isBefore(now))
        .map((r) => r.batteryRecord)
      );

      final idxOfEarliestRecordYesterday = hydrationRecords.indexOf(recordsAfterYesterday.last);

      final hasEarlierRecord = idxOfEarliestRecordYesterday > 0 
          && idxOfEarliestRecordYesterday < hydrationRecords.length -1;

      if (hasEarlierRecord) {
        final prevRecord = hydrationRecords[idxOfEarliestRecordYesterday +1];
        batteryRecords.add(prevRecord.batteryRecord);
      }
    } 

    return List.unmodifiable(batteryRecords);
  }

  /// Obtiene el consumo total de agua diario, en mililitros, durante el 
  /// periodo de tiempo entre __[begin]__ y __[end]__.
  /// 
  /// Si el usuario no consumió agua en uno de los días incluidos en el rango, 
  /// el elemento de la lista que corresponde a ese día tendrá un valor de 0.
  /// 
  /// La longitud de la lista retornada será __igual__ al número de días 
  /// entre __[begin]__ y __[end]__, redondeado hacia arriba. 
  /// 
  /// Por ejemplo, si la diferencia entre __[begin]__ y __[end]__ son cuatro 
  /// días y tres horas, este método producirá resultados para cinco días:
  /// 
  /// ```dart
  /// final totals = _totalsFromPrevDaysInMl({
  ///   begin: DateTime(2022, 8, 17),
  ///   end: DateTime(2022, 8, 21, 3)
  /// });
  /// 
  /// print(totals.length); // 5
  /// ```
  /// 
  /// En el ejemplo anterior, __totals__ tiene los totales para los días 
  /// [17,21], inclusivo.
  /// 
  /// Si __[sortByDateAscending]__ es __true__, los totales serán ordenados 
  /// con los más antiguos primero (el más antiguo será el primero). Si este 
  /// argumento es __false__, los totales serán ordenados con los más recientes 
  /// primero. 
  Future<List<int>> _totalsFromPrevDaysInMl({
    required DateTime begin, 
    required DateTime end,
    bool sortByDateAscending = true, 
  }) async {

    // Determinar si hace falta invertir las fechas para que beginDate sea antes
    // que endDate.
    if (begin.isAfter(end)) {
      // Invertir las fechas para formar un rango de fechas válido.
      final tempDate = begin;
      begin = end;
      end = tempDate;
    }

    // Comprobar que el rango de fechas sea correcto.
    assert(begin.isBefore(end), "'beginDate' debe ser antes que 'endDate'");

    final int daysBetweenDates = (end.difference(begin).inHours / 24).ceil();

    // Inicializar la lista con los totales.
    final List<int> recentTotals = List.filled(daysBetweenDates, 0, growable: false);

    // Obtener registros de hidratación, ordenados por día.
    final hydrationRecords = await _groupDailyHydration();

    for (int i = 0; i < daysBetweenDates; i++) {

      final DateTime previousDay = end.subtract(Duration( days: i)).onlyDate;

      if (hydrationRecords[previousDay] != null) {
        // Existen registros de hidratación para el día. 
        // Obtener las cantidades de los registros de hidratacion y agregarlas. 
        int totalMililiters = hydrationRecords[previousDay]!
            .map((registroHidratacion) => registroHidratacion.amount)
            .reduce((total, cantidadConsumida) => total += cantidadConsumida);

        // Asignar el consumo total para el día i.
        recentTotals[i] = totalMililiters;
      }
    }

    // Asegurar que la lista de totales tenga un elemento por cada día.
    assert(recentTotals.length == daysBetweenDates);

    // Retornar los totales, ordenados con fecha ascendiente o descendiente, según
    // isSortByDateDescending.
    return sortByDateAscending 
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
  Future<int> getGoalProgressInMl(Goal goal) async {

    // Determinar el número de días de registros necesarios (segun plazo, fecha
    // de inicio de la meta y la fecha de hoy).
    final DateTime now = DateTime.now();
    final DateTime goalStartDate = goal.startDate!;
    final diffBetweenDates = now.difference(goalStartDate);

    // El número de días de registros de hidratación necesarios para calcular 
    // el progreso.
    final int daysOfRecords = diffBetweenDates.inDays % goal.term.inDays;

    assert(daysOfRecords >= 0, "No es posible obtener el progreso para una cantidad negativa de días.");

    final goalProgressBegin = now.subtract(Duration( days: daysOfRecords )).onlyDate;
    // final bool isCompleteTerm = diffBetweenDates.inDays > 0
    //                          && diffBetweenDates.inDays >= goal.term.inDays;

    // Obtener los totales de registros de hidratación con la antiguedad para 
    // la meta.
    final totals = await _totalsFromPrevDaysInMl(
      // begin: (isCompleteTerm) ? goalProgressBegin.onlyDate : goalProgressBegin, 
      begin: goalProgressBegin, 
      end: now,
      sortByDateAscending: true
    );

    // Agregar los totales diarios.
    final int currentProgressMl = totals.isNotEmpty
      ? totals.reduce((value, dayTotal) => value + dayTotal)
      : 0;

    // Retornar el progreso del usuario hacia la meta, en mililitros.
    return currentProgressMl;
  }
}


