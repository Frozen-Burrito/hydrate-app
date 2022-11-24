import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:hydrate_app/src/api/data_api.dart';
import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/db/where_clause.dart';
import 'package:hydrate_app/src/exceptions/api_exception.dart';
import 'package:hydrate_app/src/exceptions/entity_persistence_exception.dart';
import 'package:hydrate_app/src/models/enums/time_term.dart';
import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/models/validators/range.dart';
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

  final Map<DataSyncAction, Set<Goal>> _goalsPendingSync = <DataSyncAction, Set<Goal>>{
    DataSyncAction.fetch: <Goal>{},
    DataSyncAction.updated: <Goal>{},
    DataSyncAction.deleted: <Goal>{},
  };

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

  final List<Goal> _acceptedGoalRecommendations = <Goal>[];
  final List<Goal> _rejectedGoalRecommendations = <Goal>[];

  static const int goalRepetitionsNeededForRecommendation = 5;

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
  Future<List<Goal>> get goals async {
    final List<Goal>? activeGoals = await _goalCache.data;
    return activeGoals ?? const <Goal>[];
  }

  Future<Goal?> get mainActiveGoal => _goalCache.data.then((data) {
    final goals = data ?? const <Goal>[];

    if (goals.isEmpty) return null;

    return goals.firstWhere((goal) => goal.isMainGoal, orElse: () => goals.first);
  });

  /// Es [true] si hay una lista de [Goal] de hidratación, aunque esté vacía.
  bool get hasTagData => _tagsCache.hasData;

  /// Retorna todos los registros de [Goal] disponibles, de forma asíncrona.
  Future<List<Tag>> get tags => _tagsCache.data.then((data) {
    return data ?? const <Tag>[];
  });

  /// Es [true] si hay una lista de [Goal] de hidratación, aunque esté vacía.
  bool get hasWeeklyData => _weeklyDataCache.hasData;

  /// Retorna todos los registros de [Goal] disponibles, de forma asíncrona.
  Future<List<Habits>> get weeklyData => _weeklyDataCache.data.then((data) {
    return data ?? const <Habits>[];
  });

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
  Future<List<MedicalData>> get medicalData => _medicalCache.data.then((data) {
    return data ?? const <MedicalData>[];
  });

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
      newGoal.id = newGoalId;
      _goalCache.shouldRefresh();
      _goalsPendingSync[DataSyncAction.updated]!.add(newGoal);
    }

    return newGoalId;
  }

  /// Intenta persistir [newGoal] para el perfil de usuario activo. 
  /// 
  /// Retorna el ID de la meta de hidratación persistida, o un entero 
  /// negativo si no fue posible persistir la meta.
  /// 
  /// Lanza un [EntityPersistException] cuando le perfil activo ya ha alcanzado
  /// el límite de metas activas simultáneas.
  Future<int> createHydrationGoalWithLimit(Goal newGoal) async {

    final bool hasNotReachedMaxNumberOfGoals = !(await hasReachedGoalCountLimit());

    if (hasNotReachedMaxNumberOfGoals) {
      return createHydrationGoal(newGoal);
    } else {
      throw const EntityPersistException(
        EntityPersitExceptionType.hasReachedEntityCountLimit,
        "El perfil actual ha alcanzado el límite de metas activas. Debe eliminar una meta antes de crear una nueva."
      );
    }
  }

  Future<int> getNumberOfDaysForRecommendation() async {

    final activeGoals = (await _goalCache.data) ?? const <Goal>[];

    int requiredDaysOfRecords = 1;

    for (final activeGoal in activeGoals) {
      requiredDaysOfRecords = max(requiredDaysOfRecords, activeGoal.term.inDays);
    }

    requiredDaysOfRecords *= goalRepetitionsNeededForRecommendation;

    return requiredDaysOfRecords;
  }

  Future<List<Goal>> getRecommendedGoals({ List<int>? totalWaterIntakeForPeriod }) async {

    final List<Goal> recommendations = <Goal>[];
    final bool hasPreviousWaterIntake = totalWaterIntakeForPeriod != null && 
                                        totalWaterIntakeForPeriod.isNotEmpty;

    if (hasPreviousWaterIntake) {
      final activeGoals = (await _goalCache.data) ?? <Goal>[];

      for (final hydrationGoal in activeGoals) {
        
        final hydrationDuringGoal = _groupDailyHydrationForTerm(
          hydrationGoal.term, 
          totalHydrationPerDay: totalWaterIntakeForPeriod,
        );

        final Goal? recommendedGoal = _createGoalRecommendation(hydrationGoal, hydrationDuringGoal);

        if (recommendedGoal != null) {
          recommendations.add(recommendedGoal);
        }
      }
    }

    recommendations.removeWhere((recommendation) => _rejectedGoalRecommendations.contains(recommendation));

    recommendations.removeWhere((recommendation) {
      final goalsWithSameVolume = _acceptedGoalRecommendations.where((goal) => goal.quantity == recommendation.quantity);
      final goalsWithSameTerm = _acceptedGoalRecommendations.where((goal) => goal.term == recommendation.term);

      return goalsWithSameVolume.isNotEmpty && goalsWithSameTerm.isNotEmpty;
    });

    return recommendations;
  }

  List<int> _groupDailyHydrationForTerm(TimeTerm term, {List<int> totalHydrationPerDay = const <int>[]}) {

    final int daysOfHydrationToConsider = term.inDays * goalRepetitionsNeededForRecommendation; // 35

    final int endOfRange = min(daysOfHydrationToConsider, totalHydrationPerDay.length); // 27

    final List<int> dailyHydrationDuringGoal = totalHydrationPerDay.sublist(0, endOfRange); // 0 .. 27
    final int daysWithNoRecords = daysOfHydrationToConsider - totalHydrationPerDay.length;

    if (daysWithNoRecords > 0) {
      dailyHydrationDuringGoal.addAll(List<int>.filled(daysWithNoRecords, 0));
    }

    assert(dailyHydrationDuringGoal.length == daysOfHydrationToConsider);

    final List<int> hydrationDuringPeriod;

    if (dailyHydrationDuringGoal.length != goalRepetitionsNeededForRecommendation) {

      hydrationDuringPeriod = List<int>.filled(goalRepetitionsNeededForRecommendation, 0);

      for (int i = 0; i < goalRepetitionsNeededForRecommendation; i++) {
        final periodStart = i * term.inDays;
        final periodEnd = (i + 1) * term.inDays;

        final int totalForGoalRepetition = dailyHydrationDuringGoal
          .sublist(periodStart, periodEnd)
          .reduce((totalForPeriod, totalForDay) => totalForPeriod += totalForDay);

        hydrationDuringPeriod[i] = totalForGoalRepetition;
      }
    } else {
      hydrationDuringPeriod = dailyHydrationDuringGoal;
    }

    assert(hydrationDuringPeriod.length == goalRepetitionsNeededForRecommendation);

    return hydrationDuringPeriod;
  }

  Future<int> acceptRecommendedGoal(Goal acceptedGoal, { bool useActiveGoalLimit = false }) async {

    _acceptedGoalRecommendations.add(acceptedGoal);

    Future<int> goalCreation = useActiveGoalLimit
      ? createHydrationGoalWithLimit(acceptedGoal)
      : createHydrationGoal(acceptedGoal);
      
    final int result = await goalCreation;

    if (result >= 0) {
      _goalCache.refresh();
    }

    return goalCreation; 
  }

  void rejectRecommendedGoal(Goal rejectedRecommendation) {
    _rejectedGoalRecommendations.add(rejectedRecommendation);
    notifyListeners();
  }

  Future<void> syncUpdatedHydrationGoalsWithAccount() async {

    final bool canSyncHydrationGoals = DataApi.instance.isAuthenticated && _goalsPendingSync.isNotEmpty;
    if (!canSyncHydrationGoals) return; 

    final Map<DataSyncAction, Set<Goal>> synchronizedGoals = {};

    for (final hydrationGoalsToSync in _goalsPendingSync.entries) {

      final syncAction = hydrationGoalsToSync.key;
      final modifiedHydrationGoals = hydrationGoalsToSync.value;

      try {

        synchronizedGoals[syncAction] = await _syncHydrationGoals(syncAction, modifiedHydrationGoals);
      //TODO: notificar al usuario que su perfil no pudo ser sincronizado.
      } on ApiException catch (ex) {
        debugPrint("Error al sincronizar cambios a perfil ($ex)");
      } on SocketException catch (ex) {
        debugPrint("Error al sincronizar cambios a perfil, el dispositivo tiene conexion? ($ex)");
      } on IOException catch (ex) {
        debugPrint("Error al sincronizar cambios a perfil, el dispositivo tiene conexion? ($ex)");
      }
    }

    for (final synchronizedGoalsForAction in synchronizedGoals.entries) {

      final syncAction = synchronizedGoalsForAction.key;
      final synchronizedGoals = synchronizedGoalsForAction.value;

      if (_goalsPendingSync[syncAction] != null && _goalsPendingSync[syncAction]!.isNotEmpty) {
        _goalsPendingSync[syncAction]!.removeWhere((goalPendingSync) {
          return synchronizedGoals.contains(goalPendingSync);
        });
      }

    }
  }

  Future<Set<Goal>> _syncHydrationGoals(DataSyncAction syncAction, Set<Goal> recordsToSync) async {

    final goalsSynchronizedWithSuccess = <Goal>{};

    switch (syncAction) {
      case DataSyncAction.fetch:
        //TODO: Implementar sincronización de datos.
        break;
      case DataSyncAction.updated:
        await DataApi.instance.updateData<Goal>(
          data: recordsToSync,
          mapper: (goal, mapOptions) => goal.toMap(options: mapOptions),
        );

        goalsSynchronizedWithSuccess.addAll(recordsToSync);
        break;
      case DataSyncAction.deleted:
        final idsOfDeletedRecords = await DataApi.instance.deleteCollection(
          data: recordsToSync, 
          ids: recordsToSync.map((goal) => goal.id.toString()).toSet(),
        );

        goalsSynchronizedWithSuccess.addAll(
          recordsToSync.where(
            (hydrationGoal) => idsOfDeletedRecords.contains(hydrationGoal.id.toString())
          )
        );

        break;
    }

    return goalsSynchronizedWithSuccess;
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

  Goal? _createGoalRecommendation(Goal activeGoal, List<int> hydrationDuringPeriod) {

    final bool goalIsNotDaily = activeGoal.term != TimeTerm.daily;

    final bool hasThreeDaysWithNoHydration = _hasConsecutiveItemsInRange(
      hydrationDuringPeriod,
      3, 
      const Range(min: -1, max: 1),
    );

    final int lowHydrationThreshold = (activeGoal.quantity * 2.0).round();
    final bool everyGoalIterationHasLessHydration = hydrationDuringPeriod
        .every((totalForGoalIteration) => totalForGoalIteration < lowHydrationThreshold);

    final int excessHydrationThreshold = (activeGoal.quantity * 0.5).round();
    final bool everyGoalIterationHasExcessHydration = hydrationDuringPeriod
        .every((totalForGoalIteration) => totalForGoalIteration > excessHydrationThreshold);

    Goal? recommendedGoal;

    if (goalIsNotDaily && hasThreeDaysWithNoHydration) {

      recommendedGoal ??= _copyActiveGoal(activeGoal);

      recommendedGoal.term = TimeTerm.daily;
    }

    if (everyGoalIterationHasExcessHydration) {
      recommendedGoal ??= _copyActiveGoal(activeGoal);

      recommendedGoal.quantity = (activeGoal.quantity * 0.75).round();
    }

    if (everyGoalIterationHasLessHydration) {
      recommendedGoal ??= _copyActiveGoal(activeGoal);

      recommendedGoal.quantity = (activeGoal.quantity * 1.25).round();
    }

    return recommendedGoal;
  }

  Goal _copyActiveGoal(Goal activeGoal) {
    return Goal(
      id: -1,
      term: activeGoal.term,
      startDate: activeGoal.startDate,
      endDate: activeGoal.endDate,
      quantity: activeGoal.quantity,
      notes: activeGoal.notes,
      reward: activeGoal.reward,
      tags: activeGoal.tags,
      profileId: activeGoal.profileId,
      isMainGoal: false,
    );
  }

  bool _hasConsecutiveItemsInRange(List<int> items, int itemCount, Range range) {

    int previous = -1;
    int consecutiveCount = 0;

    for (final item in items) {
      if (item == previous && range.compareTo(item) == 0) {
        consecutiveCount++;
      } else {
        consecutiveCount = 0;
      }

      if (consecutiveCount >= itemCount) {
        return true;
      }

      previous = item;
    }

    return false;
  }

  /// Elimina una meta de hidratación existente.
  Future<int> deleteHydrationGoal(int id) async {
    
    final modifiedRowsCount = await SQLiteDB.instance.delete(Goal.tableName, id);

    if (modifiedRowsCount >= 0) {
      final deletedGoal = Goal.uncommited();
      deletedGoal.id = id;

      _goalsPendingSync[DataSyncAction.deleted]!.add(deletedGoal);
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
    
    final int newWeeklyReportId = await SQLiteDB.instance.insert(newReport);

    if (newWeeklyReportId >= 0) {
      _weeklyDataCache.shouldRefresh();
    }

    return newWeeklyReportId;
  }

  /// Persiste a [newReport] en la base de datos local. 
  /// 
  /// Cuando [newReport] es persistido con éxito, este método refresca la lista 
  /// de reportes médicos de [medicalData] y retorna el ID de [newReport]. 
  /// 
  /// Si [newReport] no pudo ser persistido, retorna un entero negativo.
  Future<int> saveMedicalReport(MedicalData newReport) async {
    // Asegurar que el nuevo reporte médico sea asociado con el perfil de usuario actual.
    newReport.profileId = _profileId;
    
    final int newMedicalReportId = await SQLiteDB.instance.insert(newReport);

    if (newMedicalReportId >= 0) {
      _medicalCache.shouldRefresh();
    }

    return newMedicalReportId;
  }

  Future<bool> hasReachedGoalCountLimit() async {
    final currentHydrationGoals = await _fetchGoals();
    final int numberOfExistingGoals = currentHydrationGoals.length;

    final hasReachedMaxAmountOfGoals = numberOfExistingGoals >= Goal.maxSimultaneousGoals;

    return hasReachedMaxAmountOfGoals;
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