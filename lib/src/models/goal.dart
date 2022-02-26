import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/tag.dart';

enum GoalTerm {
  daily,
  weekly,
  monthly,
}

class Goal extends SQLiteModel {

  int id;
  GoalTerm term;
  DateTime? startDate;
  DateTime endDate;
  int reward;
  int quantity;
  String? notes;
  List<Tag> tags;

  Goal({
    required this.id,
    required this.term,
    this.startDate,
    required this.endDate,
    this.reward = 0,
    this.quantity = 0,
    this.notes,
  }) : tags = [];

  @override
  String get table => 'goal';

  static Goal fromMap(Map<String, dynamic> map) {
    final goal = Goal(
      id: map['id'],
      term: GoalTerm.values[ int.tryParse(map['plazo']) ?? 0],
      startDate: DateTime.parse(map['fecha_inicio']),
      endDate: DateTime.parse(map['fecha_fin']),
      reward: map['recompensa'],
      quantity: map['cantidad'],
      notes: map['notas']
    );

    goal.parseTags(map['etiquetas']);

    return goal;
  } 

  @override
  Map<String, dynamic> toMap() => {
    'id': id,
    'plazo': term.index,
    'fecha_inicio': startDate?.toIso8601String(), 
    'fecha_fin': endDate.toIso8601String(),
    'recompensa': reward,
    'cantidad': quantity,
    'notas': notes,
    'etiquetas': tags.map((e) => e.toMap()).toList()
  };

  /// Obtiene una [List<Tag>] a partir de un [inputValue], con cada etiquta 
  /// separada por comas.
  /// 
  /// Regresa el número de etiquetas asignadas.
  /// 
  /// ```dart
  /// parseTags('uno,naranja,arbol') // Resulta en ['uno', 'naranja', 'arbol']
  /// ```
  int parseTags(String? inputValue) {

    if (inputValue == null) return 0;

    final strTags = inputValue.split(',');

    if (strTags.isNotEmpty) {

      int tagCount = tags.length;
      int newTagCount = strTags.length;

      if (tagCount == newTagCount) {
        // Si el numero de tags es el mismo, solo cambió el valor de la última.
        tags.last.value = strTags.last;
      
      } else if (tagCount < newTagCount && strTags.last.isNotEmpty) {
        // Si hay un tag nuevo, agregarlo.
        tags.add(Tag(0, strTags.last));

      } else if (strTags.last.isNotEmpty) {
        // Si hay un tag menos, quita el último.
        tags.removeLast();
      }
    }

    return inputValue.isEmpty ? 0 : tags.length;
  }

  static String? validateTerm(int? termIndex) {

    if (termIndex == null) return 'Selecciona un plazo para la meta.';

    return (termIndex >= 0 && termIndex < GoalTerm.values.length) 
        ? null
        : 'Plazo para meta no válido';
  }

  static String? validateWaterQuantity(String? inputValue) {
    if (inputValue == null) return 'Escribe una cantidad';

    int? waterQuantity = int.tryParse(inputValue);
    
    if (waterQuantity != null) {
      return (waterQuantity > 0 && waterQuantity < 1000) 
          ? null 
          : 'La cantidad debe ser entre 0 y 1000 ml.'; 
    }
  }

  static String? validateReward(String? inputValue) {

    int? reward = int.tryParse(inputValue ?? '0');
    
    if (reward != null) {
      return (reward >= 0 && reward <= 1000) 
          ? null 
          : 'La recompensa debe estar entre 0 y 1000.'; 
    }
  }

  static String? validateTags(String? inputValue) {

    if (inputValue != null) {
      final strTags = inputValue.split(',');
      int totalLength = 0;

      for (var element in strTags) { 
        element.trim(); 
        totalLength += element.length;
      }

      if (totalLength > 30) return 'Exceso de caracteres para etiquetas.';

      return (strTags.length > 3 && strTags.last.isNotEmpty) 
        ? 'Una meta debe tener 3 etiquetas o menos.'
        : null;
    }
  } 

  static String? validateNotes(String? inputValue) {
    return (inputValue != null && inputValue.length > 100)
        ? 'Las notas deben tener menos de 100 caracteres'
        : null;
  }
}