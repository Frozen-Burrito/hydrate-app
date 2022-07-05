import 'package:flutter/material.dart';
import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/db/where_clause.dart';
import 'package:hydrate_app/src/models/goal.dart';
import 'package:hydrate_app/src/models/habits.dart';
import 'package:hydrate_app/src/models/tag.dart';

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

  Future<List<Goal>> get goals {
    if (_shouldRefreshGoals && !_areGoalsLoading) {
      return _fetchGoals();
    }

    return Future.value(_goals);
  }

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