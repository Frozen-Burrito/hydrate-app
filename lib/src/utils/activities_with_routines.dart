import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/models/routine_occurrence.dart';

/// Asocia [ActivityRecord] con sus [Routine], generando registros a partir
/// de las rutinas y sus dias de ocurrencia. 
class RoutineActivities { 

  final List<ActivityRecord> _activities;

  final List<Routine> _routines;

  final List<RoutineOccurrence> _routineOccurrences;

  final Map<int, ActivityRecord> _activityByIdCache;

  RoutineActivities.empty({ bool growable = true }) 
    : _activities = List.empty(growable: growable),
      _routines = List.empty(growable: growable),
      _routineOccurrences = List.empty(growable: growable),
      _activityByIdCache = {};

  /// Todas las actividades, incluyendo todos los registros producidos por 
  /// actividades rutinarias.
  List<RoutineOccurrence> get activitiesWithRoutines => List.unmodifiable(_routineOccurrences);

  /// Todos los [ActivityRecord] disponibles.
  Iterable<ActivityRecord> get activities => List.unmodifiable(_activities);

  /// Todos los [Routine] disponibles.
  Iterable<Routine> get routines => List.unmodifiable(_routines);

  set activities (Iterable<ActivityRecord> activityRecords) {
    _activities.clear();
    _activities.addAll(activityRecords);

    _routineOccurrences.clear();
    _routineOccurrences.addAll(_groupRoutineActivities());
  }

  set routines (Iterable<Routine> routines) {
    _routines.clear();
    _routines.addAll(routines);
    
    _routineOccurrences.clear();
    _routineOccurrences.addAll(_groupRoutineActivities());
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

  /// Busca y retorna una [Routine] asociada con [activity]. Si no encuentra una 
  /// rutina asociada, retorna [null].
  Routine? getActivityRoutine(ActivityRecord activity) {

    if (_routines.isEmpty) return null;

    // Buscar una rutina donde su activityId sea igual a activity.id.
    // si no, retornar una Routine no creada (orElse no permite retornar null).
    final matchingRoutine = _routines.firstWhere(
      (routine) => routine.activityId == activity.id, 
      orElse: () => Routine.uncommited()
    );

    // La rutina existe si el Id de la rutina es positivo.
    final wasRoutineFound = matchingRoutine.id >= 0;

    return wasRoutineFound ? matchingRoutine : null;
  }

  /// Genera una colección de [RoutineOccurrence] que incluye todos los 
  /// [ActivityRecord] de actividades, además de todas las repeticiones de 
  /// actividades rutinarias usando [Routine].  
  List<RoutineOccurrence> _groupRoutineActivities() {

    final records = <RoutineOccurrence>[];
    final today = DateTime.now();

    // Agregar todos los registros de actividad, incluyendo sus registros por 
    // rutinas (si los hay).
    for (var activity in _activities) {

      // Revisar si activity está asociada a una rutina.
      Routine? routineForActivity = getActivityRoutine(activity);

      // Agregar el registro original de la actividad, con su rutina si la tiene.
      records.add(RoutineOccurrence(activity.date, activity, routine: routineForActivity));

      // Si existe una rutina para la actividad, 
      if (routineForActivity != null && routineForActivity.hasWeekdays) {

        activity.isRoutine = true;
        final routineRecords = <RoutineOccurrence>[];

        DateTime nextDate = routineForActivity.getNextOccurrence(activity.date);

        // Obtener todas las ocurrencias de la rutina hasta la fecha.
        while (nextDate.isBefore(today)) {

          final routineOccurrence = RoutineOccurrence(
            nextDate, 
            activity, 
            routine: routineForActivity
          );

          // Agregar la ocurrencia de rutina a los registros de rutinas.
          routineRecords.add(routineOccurrence);

          // Obtener siguiente fecha de la rutina.
          nextDate = routineForActivity.getNextOccurrence(nextDate);
        }

        // Incluir todos los registros de rutinas.
        records.addAll(routineRecords);
      }
    }

    // Ordenar los registros de actividades por fecha, de forma descendiente. 
    // (Más recientes primero).
    records.sort((a, b) => b.date.compareTo(a.date));

    return records;
  }
}