import 'package:flutter/material.dart';
import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/db/where_clause.dart';
import 'package:hydrate_app/src/models/goal.dart';
import 'package:hydrate_app/src/models/habits.dart';
import 'package:hydrate_app/src/models/tag.dart';

/// Maneja el estado para los [Goal], [Tag] y [Habits].
class GoalProvider extends ChangeNotifier {

  final List<Goal> _goals = <Goal>[];
  final List<Tag> _tags = <Tag>[];
  final List<Habits> _periodicReports = <Habits>[];

  bool _shouldRefreshGoals = true;
  bool _areGoalsLoading = false;

  bool _shouldRefreshTags = true;
  bool _areTagsLoading = false;

  int _profileId = -1;

  set activeProfileId (int profileId) => _profileId = profileId;

  /// Obtiene todos los [Goal] de hidratación.
  Future<List<Goal>> get goals {
    if (_shouldRefreshGoals && !_areGoalsLoading) {
      return _fetchGoals();
    }

    return Future.value(_goals);
  }

  /// Obtiene todos los [Tag] disponibles.
  Future<List<Tag>> get tags {
    if (_shouldRefreshTags && !_areTagsLoading) {
      return _fetchTags();
    }

    return Future.value(_tags);
  }

  Future<List<Goal>> _fetchGoals() async {
    try {
      _goals.clear();
      _areGoalsLoading = true;

      final queryResults = await SQLiteDB.instance.select<Goal>(
        Goal.fromMap, 
        Goal.tableName,
        where: [ WhereClause('id_perfil', _profileId.toString() )]
      );

      _goals.addAll(queryResults);

      _shouldRefreshGoals = false;

      return _goals;

    } on Exception catch (e) {
      return Future.error(e);

    } finally {
      _areGoalsLoading = false;
      notifyListeners();
    }
  }

  /// Agrega una nueva meta de hidratación.
  Future<int> createHydrationGoal(Goal newGoal) async {
    
    try {
      int result = await SQLiteDB.instance.insert(newGoal);

      if (result >= 0) {
        _shouldRefreshGoals = true;
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
          _shouldRefreshGoals = true;
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
        _shouldRefreshGoals = true;
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
    try {
      _tags.clear();
      _areTagsLoading = true;

      final queryResults = await SQLiteDB.instance.select<Tag>(
        Tag.fromMap, 
        Tag.tableName,
        where: [ WhereClause('id_perfil', _profileId.toString() )]
      );

      _tags.addAll(queryResults);

      _shouldRefreshTags = false;

      return _tags;

    } on Exception catch (e) {
      return Future.error(e);

    } finally {
      _areTagsLoading = false;
      notifyListeners();
    }
  }
}