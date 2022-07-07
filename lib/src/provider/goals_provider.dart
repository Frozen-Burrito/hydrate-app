import 'package:flutter/material.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/db/where_clause.dart';
import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/provider/cache_state.dart';

/// Maneja el estado para los [Goal], [Tag], [Habits] y [MedicalData].
class GoalProvider extends ChangeNotifier {

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

  int _profileId = -1;

  set activeProfileId (int profileId) => _profileId = profileId;

  /// Es [true] si hay una lista de [Goal] de hidratación, aunque esté vacía.
  bool get hasGoalData => _goalCache.hasData;

  /// Retorna todos los registros de [Goal] disponibles, de forma asíncrona.
  Future<List<Goal>?> get goals => _goalCache.data;

  /// Es [true] si hay una lista de [Goal] de hidratación, aunque esté vacía.
  bool get hasTagData => _tagsCache.hasData;

  /// Retorna todos los registros de [Goal] disponibles, de forma asíncrona.
  Future<List<Tag>?> get tags => _tagsCache.data;

  /// Es [true] si hay una lista de [Goal] de hidratación, aunque esté vacía.
  bool get hasWeeklyData => _weeklyDataCache.hasData;

  /// Retorna todos los registros de [Goal] disponibles, de forma asíncrona.
  Future<List<Habits>?> get weeklyData => _weeklyDataCache.data;

  /// Es [true] si hay una lista de datos médicos, aunque esté vacía.
  bool get hasMedicalData => _medicalCache.hasData;

  /// Retorna todos los registros de [MedicalData] disponibles, de forma asíncrona.
  Future<List<MedicalData>?> get medicalData => _medicalCache.data;

  /// Agrega una nueva meta de hidratación.
  Future<int> createHydrationGoal(Goal newGoal) async {
    
    try {
      int result = await SQLiteDB.instance.insert(newGoal);

      if (result >= 0) {
        _goalCache.shouldRefresh();
        return result;
      } else {
        throw Exception('No se pudo crear la meta de hidratación.');
      }
    }
    on Exception catch (e) {
      return Future.error(e);

    } finally {
      notifyListeners();
    }
  }

  /// Cambia la meta principal a la meta en donde su ID sea [newMainGoalId].
  Future<int> setMainGoal(int newMainGoalId) async {
    try {
      // Obtener la meta principal y la meta que tenga un ID que coincida con 
      // newMainGoalId (puede que sean la misma meta).
      final queryResults = await SQLiteDB.instance.select<Goal>(
        Goal.fromMap, 
        Goal.tableName,
        where: [
          WhereClause('es_principal', '1' ),
          WhereClause('id', newMainGoalId.toString() )
        ],
        whereUnions: [ 'OR' ]
      );

      // Transformar los resultados a una lista.
      final queryList = queryResults.toList();

      Goal? currentMainGoal;
      Goal? newMainGoal;

      switch(queryList.length) {
        case 1:
          if (queryList.first.isMainGoal) {
            currentMainGoal = queryList.first;
          }

          newMainGoal = queryList.first;
          break;
        case 2:
          int mainGoalIdx = queryList.indexWhere((goal) => goal.isMainGoal);
          currentMainGoal = queryList.removeAt(mainGoalIdx);
          newMainGoal = queryList.first;
          break;
      }

      if (currentMainGoal != null) {
        // Convertir la meta principal actual en una meta normal.
        currentMainGoal.isMainGoal = false;
        int result = await SQLiteDB.instance.update(currentMainGoal);

        if (result <= 0) {
          throw Exception('No se pudo modificar la meta principal de hidratación.');
        }
      }

      if (newMainGoal != null) {
        // Convertir la meta seleccionada en la meta principal.
        newMainGoal.isMainGoal = !newMainGoal.isMainGoal;
        int result = await SQLiteDB.instance.update(newMainGoal);

        if (result >= 0) {
          _goalCache.shouldRefresh();
          return result;
        } else {
          throw Exception('No se pudo modificar la meta principal de hidratación.');
        }
      } else {
        throw ArgumentError.value(
          newMainGoalId, 
          'newMainGoalId', 
          'No se encontró un Goal con este ID.'
        );
      }
    }
    on Exception catch (e) {
      return Future.error(e);

    } finally {
      notifyListeners();
    }
  }

  /// Elimina una meta de hidratación existente.
  Future<int> deleteHydrationGoal(int id) async {
    
    try {
      int result = await SQLiteDB.instance.delete(
        Goal.tableName,
        id
      );

      if (result >= 0) {
        _goalCache.shouldRefresh();
        return result;
      } else {
        throw Exception('No se pudo eliminar la meta de hidratación.');
      }
    }
    on Exception catch (e) {
      return Future.error(e);

    } finally {
      notifyListeners();
    }
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
      where: [ WhereClause('id_perfil', _profileId.toString() )]
    );

    return Future.value(queryResults.toList());
  }

  /// Obtener todos los [Habits] de hidratación del perfil de 
  /// usuario activo, como una [List].
  Future<List<Habits>> _fetchWeeklyReports() async {
    // Query a la base de datos.
    final queryResults = await SQLiteDB.instance.select<Habits>(
      Habits.fromMap,
      Habits.tableName,
      where: [ WhereClause('id_perfil', _profileId.toString() )]
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