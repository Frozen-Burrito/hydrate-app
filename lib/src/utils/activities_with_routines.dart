import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/utils/datetime_extensions.dart';

class RoutineActivities { 

  final List<ActivityRecord> _activities;

  final List<Routine> _routines;

  final Map<DateTime, List<int>> _activitiesByDate;

  final Map<int, ActivityRecord> _activityByIdCache;

  RoutineActivities.empty({ bool growable = true }) 
    : _activities = List.empty(growable: growable),
      _routines = List.empty(growable: growable),
      _activitiesByDate = {},
      _activityByIdCache = {};

  Iterable<ActivityRecord> get activities => List.unmodifiable(_activities);

  set activities (Iterable<ActivityRecord> activityRecords) {
    _activities.clear();
    _activities.addAll(activityRecords);

    if (_routines.isNotEmpty) {
      _activitiesByDate.clear();
      _activitiesByDate.addAll(_groupDailyActivities());
    }
  }

  Iterable<Routine> get routines => List.unmodifiable(_routines);

  set routines (Iterable<Routine> routines) {
    _routines.clear();
    _routines.addAll(routines);

    if (_activities.isNotEmpty) {
      _activitiesByDate.clear();
      _activitiesByDate.addAll(_groupDailyActivities());
    }
  }

  Map<DateTime, List<int>> get activitiesByDate => Map.unmodifiable(_activitiesByDate);

  Iterable<ActivityRecord?> get allActivities {

    if (_activitiesByDate.isEmpty) return List<ActivityRecord>.empty();

    final allActivities = _activitiesByDate.values
      .reduce((all, recordsFromDay) {
        all.addAll(recordsFromDay);

        return all;
      })
      .map((activityId) => getActivityById(activityId));

    return allActivities;
  }

  int get length {
    int total = 0;

    for (var activityList in _activitiesByDate.values) {
      total += activityList.length;
    }

    return total;
  }

  /// Busca un [ActivityRecord] que tenga un [activity.id] igual a [id] y lo 
  /// retorna.
  /// 
  /// Si no lo encuentra, retorna [null].
  ActivityRecord? getActivityById(int id) {

    // Revisar si la actividad ya fue encontrada y mapeada con su ID.
    final ActivityRecord? cachedActivity = _activityByIdCache[id];

    if (cachedActivity != null) {
      return cachedActivity;
    }

    final matchingActivity = _activities.firstWhere(
      (activity) => activity.id == id, 
      orElse: () => ActivityRecord.uncommited()
    );

    final wasActivityFound = matchingActivity.id >= 0;

    if (wasActivityFound) {
      // La actividad fue encontrada, retornarla.
      _activityByIdCache[matchingActivity.id] = matchingActivity;
      return matchingActivity;

    } else {
      // El ActivityRecord no fue encontrado en cache ni en los registros.
      return null;
    }
  }

  /// Busca todos los [ActivityRecord] de los que [ids] contenga su [activity.id].
  /// 
  /// Si no hay un [ActivityRecord] con uno de los id de [ids], la colección
  /// de [ActivityRecord] tendrá menos elementos que [ids].
  Iterable<ActivityRecord> getActivitiesByIds(Iterable<int> ids) {
    final matchingActivities = _activities.where(
      (activity) => ids.contains(activity.id)
    );

    return matchingActivities;
  }

  Routine? getActivityRoutine(ActivityRecord activity) {

    final matchingRoutine = _routines.firstWhere(
      (routine) => routine.activityId == activity.id, 
      orElse: () => Routine.uncommited()
    );

    final wasRoutineFound = matchingRoutine.id >= 0;

    return wasRoutineFound ? matchingRoutine : null;
  }

  /// Crea un mapa con todos los [ActivityRecord] disponibles, agrupados 
  /// por día. 
  /// 
  /// Cada entrada del mapa contiene la fecha de un día en que el 
  /// usuario realizó actividad física, asociada con una lista de IDs de las 
  /// actividades que registró. 
  Map<DateTime, List<int>> _groupDailyActivities() {

    final records = <DateTime, List<int>>{};

    final routineActivities = <ActivityRecord, Routine>{};

    // Agregar todos los registros de actividad simples al mapa.
    for (var activity in _activities) {
      DateTime date = activity.date.onlyDate;

      if (routines.isNotEmpty) {

        final routineForActivity = getActivityRoutine(activity);

        if (routineForActivity != null) {
          activity.isRoutine = true;
          routineActivities[activity] = routineForActivity;
        }
      }

      if (records[date] == null) records[date] = <int>[]; 

      records[date]?.add(activity.id);
    }

    // Insertar referencias para actividades rutinarias.
    routineActivities.forEach((activity, routine) {

      // Obtener los días en donde sucede la rutina.
      final weekdays = routine.daysOfWeek.toList();

      if (weekdays.isNotEmpty) {

        final today = DateTime.now();

        //TODO: Quizas extrar esta logica en algo como "activityRecord.nextEvent(weekdays)"
        // Serviria para el problema con ActivitySliverList.
        DateTime nextDate = activity.date;
        
        int dayIndex = 0;

        // Obtener dias de diferencia entre dias de la semana.
        int weekdayDiff = DateTime.sunday - (nextDate.weekday - weekdays[dayIndex]).abs();

        // Mover la fecha de actividad a la siguiente.
        nextDate = nextDate.add(Duration( days: weekdayDiff ));

        while (nextDate.isBefore(today)) {

          if (records[nextDate.onlyDate] == null) records[nextDate] = <int>[];

          // Agregar el ID del registro de actividad.
          records[nextDate.onlyDate]?.add(activity.id);

          // Obtener dias de diferencia entre dias de la semana.
          weekdayDiff = DateTime.sunday - (nextDate.weekday - weekdays[dayIndex]).abs();

          // Mover la fecha de actividad a la siguiente.
          nextDate = nextDate.add(Duration( days: weekdayDiff ));

          dayIndex = (dayIndex + 1) % weekdays.length;
        }
      }
    });

    return records;
  }
}