import 'package:flutter/material.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/db/where_clause.dart';
import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/services/cache_state.dart';

/// Maneja el estado para los [Goal], [Tag], [Habits] y [MedicalData].
class GoalsService extends ChangeNotifier {

  /// El ID del perfil local del usuario actual.
  int _profileId = -1;

  void forProfile(int newProfileId) {
    if (newProfileId != _profileId) {
      _profileId = newProfileId;

      // Refrescar los datos que dependen del perfil de usuario activo.
      _goalCache.shouldRefresh();
      _tagsCache.shouldRefresh();
      _weeklyDataCache.shouldRefresh();
      _medicalCache.shouldRefresh();
    }
  }

  late final CacheState<List<Goal>> _goalCache = CacheState(
    fetchData: _fetchGoals,
    onDataRefreshed: (_) => notifyListeners(),
  );

  late final CacheState<List<Tag>> _tagsCache = CacheState(
    fetchData: _fetchTags,
    onDataRefreshed: (_) => notifyListeners()
  );

  late final CacheState<List<Habits>> _weeklyDataCache = CacheState(
    fetchData: _fetchWeeklyReports,
    onDataRefreshed: (_) => notifyListeners()
  );

  late final CacheState<List<MedicalData>> _medicalCache = CacheState(
    fetchData: _fetchMedicalData,
    onDataRefreshed: (_) => notifyListeners()
  );

  bool _hasAskedForPeriodicalData = false;
  bool _hasAskedForMedicalData = false;
  
  void appAskedForPeriodicalData() {
    _hasAskedForPeriodicalData = true;
  }

  void appAskedForMedicalData() {
    _hasAskedForMedicalData = true;
  }

  /// Es [true] si hay una lista de [Goal] de hidratación, aunque esté vacía.
  bool get hasGoalData => _goalCache.hasData;

  /// Retorna todos los registros de [Goal] disponibles, de forma asíncrona.
  Future<List<Goal>> get goals async => (await _goalCache.data) ?? const <Goal>[];

  /// Es [true] si hay una lista de [Goal] de hidratación, aunque esté vacía.
  bool get hasTagData => _tagsCache.hasData;

  /// Retorna todos los registros de [Goal] disponibles, de forma asíncrona.
  Future<List<Tag>?> get tags => _tagsCache.data;

  /// Es [true] si hay una lista de [Goal] de hidratación, aunque esté vacía.
  bool get hasWeeklyData => _weeklyDataCache.hasData;

  /// Retorna todos los registros de [Goal] disponibles, de forma asíncrona.
  Future<List<Habits>?> get weeklyData => _weeklyDataCache.data;

  /// Retorna el reporte semanal de hábitos más reciente del usuario.
  Future<Habits?> get lastPeriodicReport async {

    final weeklyReportData = await _weeklyDataCache.data;

    Habits? lastReport;
    
    if (weeklyReportData != null && weeklyReportData.isNotEmpty) {
      // Asegurar que los datos de reportes son ordenados por fecha descendiente.
      weeklyReportData.sort((a, b) => b.date.compareTo(a.date));

      // Obtener el reporte mas reciente.
      lastReport = weeklyReportData.first;
    }

    return Future.value(lastReport);
  }

  /// Retorna el [DateTime] del reporte semanal de hábitos más reciente.
  Future<DateTime?> get lastWeeklyReportDate async => (await lastPeriodicReport)?.date;

  /// Es [true] si ha pasado más de una semana desde el último reporte con 
  /// [Habits], y todavía no ha solicitado al usuario responder el reporte.
  Future<bool> get isWeeklyReportAvailable async {
    final lastReportDate = await lastWeeklyReportDate;

    final aWeekAgo = DateTime.now().subtract(const Duration( days: 7 ));

    return (!_hasAskedForPeriodicalData && (lastReportDate?.isBefore(aWeekAgo) ?? true));
  }

  /// Es [true] si hay una lista de datos médicos, aunque esté vacía.
  bool get hasMedicalData => _medicalCache.hasData;

  /// Retorna todos los registros de [MedicalData] disponibles, de forma asíncrona.
  Future<List<MedicalData>?> get medicalData => _medicalCache.data;

  /// Retorna el reporte de [MedicalData] más reciente del usuario.
  Future<MedicalData?> get lastMedicalReport async {

    final medicalReportData = await _medicalCache.data;

    MedicalData? lastReport;
    
    if (medicalReportData != null && medicalReportData.isNotEmpty) {
      // Asegurar que los datos de reportes son ordenados por fecha descendiente.
      medicalReportData.sort((a, b) => b.nextAppointment.compareTo(a.nextAppointment));

      // Obtener el reporte mas reciente.
      lastReport = medicalReportData.first;
    }

    return Future.value(lastReport);
  }

  /// Es [true] si ha pasado más de una semana desde el último reporte con 
  /// [MedicalData].
  Future<bool> get isMedicalReportAvailable async {

    final lastReportDate = (await lastMedicalReport)?.nextAppointment;

    final nextAppointmentHasPassed = lastReportDate?.isBefore(DateTime.now()) ?? true;

    return (!_hasAskedForMedicalData && nextAppointmentHasPassed);
  }
      
  /// Persiste a [newGoal] en la base de datos local. 
  /// 
  /// Cuando [newGoal] es persistida con éxito, este método refresca la lista 
  /// de metas [goals] y retorna el ID de [newGoal]. 
  /// 
  /// Si [newGoal] no pudo ser persistida, retorna un entero negativo.
  Future<int> createHydrationGoal(Goal newGoal) async {
    
    // Asegurar que la nueva meta sea asociada con el perfil de usuario actual.
    newGoal.profileId = _profileId;

    final int newGoalId = await SQLiteDB.instance.insert(newGoal);

    if (newGoalId >= 0) {
      _goalCache.shouldRefresh();
    }

    return newGoalId;
  }

  /// Cambia la meta principal a la meta que tenga [newMainGoalId] como su ID.
  /// 
  /// [newMainGoalId] siempre debe ser un ID de una meta activa existente. De lo 
  /// contrario, este método retornará un valor entero negativo. 
  /// 
  /// Cuando [newMainGoalId] es el ID de la meta principal actual, la meta es 
  /// definida como común y deja de haber una meta principal.
  /// 
  /// Retorna el ID de la nueva meta principal, o un número entero negativo si
  /// hubo un error configurando la meta principal.
  Future<int> setMainGoal(int newMainGoalId) async {

    assert(newMainGoalId >= 0, '<newMainGoalId> debe ser un número positivo');

    // Obtener la meta principal y la meta que tenga un ID que coincida con 
    // newMainGoalId (puede que sean la misma meta).
    final queryResults = await SQLiteDB.instance.select<Goal>(
      Goal.fromMap, 
      Goal.tableName,
      where: [
        const WhereClause(Goal.isMainGoalFieldName, "1" ),
        WhereClause(Goal.idFieldName, newMainGoalId.toString() )
      ],
      whereUnions: [ 'OR' ]
    );

    // Transformar los resultados a una lista.
    final resultsAsList = queryResults.toList();
      
    // Si queryResults no tiene elementos, significa que este método fue 
    // invocado sin que existan metas. 
    assert(resultsAsList.isNotEmpty, 'La query para cambiar la meta principal no retornó ninguna meta');
    // Si tiene más de dos elementos, hay más de una meta con el mismo ID o hay
    // más de una meta principal.
    assert(resultsAsList.length <= 2, 'La query para cambiar la meta principal retornó más de dos metas');

    // Determinar cuál de los dos resultados es la meta principal.
    final int mainGoalIdx = resultsAsList.indexWhere((goal) => goal.isMainGoal);
    final int newMainGoalIdx = (mainGoalIdx == 0 && resultsAsList.length > 1) ? 1 : 0;

    final currentMainGoal = mainGoalIdx >= 0 ? resultsAsList[mainGoalIdx] : null;
    final newMainGoal = resultsAsList[newMainGoalIdx];

    int totalRowsModified = 0;

    if (currentMainGoal != null) {
      // Actualizar la meta principal actual para que sea una meta activa común y 
      // sumar las filas modificadas por el update al número de filas totales.
      currentMainGoal.isMainGoal = !currentMainGoal.isMainGoal;
      totalRowsModified += await SQLiteDB.instance.update(currentMainGoal);
    }

    if (currentMainGoal != newMainGoal) {
      // Si esta operación está cambiando la meta principal (en vez de solo
      // alternar su estado como principal), convertir la nueva especificada en 
      // la nueva meta principal.
      newMainGoal.isMainGoal = true;
      totalRowsModified += await SQLiteDB.instance.update(newMainGoal);
    }

    // if meta principal no existe (currentMainGoal == null) = 1
    // if meta principal es la misma (currentMainGoal == newMainGoal) = 1
    // if meta principal es distinta (currentMainGoal != newMainGoal) = 1

    final int expectedModifiedRows = (currentMainGoal != newMainGoal && currentMainGoal != null) ? 2 : 1;

    if (totalRowsModified != expectedModifiedRows) return -1;

    _goalCache.refresh();
    return newMainGoal.id;
  }

  /// Elimina una meta de hidratación existente.
  Future<int> deleteHydrationGoal(int id) async {
    
    final modifiedRowsCount = await SQLiteDB.instance.delete(Goal.tableName, id);

    if (modifiedRowsCount >= 0) {
      _goalCache.shouldRefresh();
    } 

    return modifiedRowsCount;
  }

  /// Persiste a [newReport] en la base de datos local. 
  /// 
  /// Cuando [newReport] es persistido con éxito, este método refresca la lista 
  /// de reportes habituales de [weeklyData] y retorna el ID de [newReport]. 
  /// 
  /// Si [newReport] no pudo ser persistido, retorna un entero negativo.
  Future<int> saveWeeklyReport(Habits newReport) async {
    // Asegurar que el reporte sea guardado con el perfil del usuario actual.
    newReport.profileId = _profileId;
    
    final int newReportId = await SQLiteDB.instance.insert(newReport);

    if (newReportId >= 0) {
      _weeklyDataCache.shouldRefresh();
    }

    return newReportId;
  }

  /// Persiste a [newReport] en la base de datos local. 
  /// 
  /// Cuando [newReport] es persistido con éxito, este método refresca la lista 
  /// de reportes médicos de [medicalData] y retorna el ID de [newReport]. 
  /// 
  /// Si [newReport] no pudo ser persistido, retorna un entero negativo.
  Future<int> saveMedicalReport(MedicalData newReport) async {
    
    int result = await SQLiteDB.instance.insert(newReport);

    if (result >= 0) {
      _medicalCache.shouldRefresh();
    }

    return result;
  }

  Future<List<Tag>> _fetchTags() async {
    // Query a la base de datos.
    final queryResults = await SQLiteDB.instance.select<Tag>(
      Tag.fromMap, 
      Tag.tableName,
      where: [ WhereClause('id_perfil', _profileId.toString() )]
    );

    return Future.value(queryResults.toList());
  }

  /// Obtener todos los [Goal] de hidratación del perfil de 
  /// usuario activo, como una [List].
  Future<List<Goal>> _fetchGoals() async {
    // Query a la base de datos.
    final queryResults = await SQLiteDB.instance.select<Goal>(
      Goal.fromMap,
      Goal.tableName,
      where: [ WhereClause(Goal.profileIdFieldName, _profileId.toString() )],
      includeOneToMany: true,
      queryManyToMany: true,
    );

    if (queryResults.isEmpty) return <Goal>[];

    final goalList = queryResults.toList();

    // Ordenar metas para que la meta principal sea la primera.
    final mainGoalIdx = goalList.indexWhere((goal) => goal.isMainGoal);

    if (mainGoalIdx >= 0) {
      // Si hay una meta principal, reordenarla para ponerla como primera 
        // Si hay una meta principal, reordenarla para ponerla como primera 
      // Si hay una meta principal, reordenarla para ponerla como primera 
      // en la lista de metas.
      final mainGoal = goalList.removeAt(mainGoalIdx);
      goalList.insert(0, mainGoal);
    }

    return List.unmodifiable(goalList);
  }

  /// Obtener todos los [Habits] de hidratación del perfil de 
  /// usuario activo, como una [List].
  Future<List<Habits>> _fetchWeeklyReports() async {
    // Query a la base de datos.
    final queryResults = await SQLiteDB.instance.select<Habits>(
      Habits.fromMap,
      Habits.tableName,
      where: [ WhereClause(Habits.profileIdFieldName, _profileId.toString() )],
      orderByColumn: Habits.dateFieldName,
      orderByAsc: false,
    );

    return Future.value(queryResults.toList());
  }

  /// Obtener todos los registros de reportes de [MedicalData] del perfil de 
  /// usuario activo, como una [List].
  Future<List<MedicalData>> _fetchMedicalData() async {
    // Query a la base de datos.
    final queryResults = await SQLiteDB.instance.select<MedicalData>(
      MedicalData.fromMap,
      MedicalData.tableName,
      where: [ WhereClause('id_perfil', _profileId.toString() )]
    );

    return Future.value(queryResults.toList());
  }
}