import 'package:hydrate_app/src/models/activity_record.dart';
import 'package:hydrate_app/src/models/routine.dart';

/// Un registro de actividad que puede incluir una rutina. 
class RoutineOccurrence {

  /// La fecha de realización de la actividad. Si [routine] no es nulo, será una 
  /// fecha en que ocurre la rutina. Si no, [date] es igual a [activity.date].
  final DateTime date;

  /// Los datos de la actividad física.
  final ActivityRecord activity;
  
  /// Una rutina opcional asociada con la actividad.
  final Routine? routine;

  RoutineOccurrence(this.date, this.activity, { this.routine });
}
