import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/tag.dart';
import 'package:hydrate_app/src/models/user_profile.dart';

enum GoalTerm {
  daily,
  weekly,
  monthly,
}

class Goal extends SQLiteModel {

  int id;
  int profileId;
  GoalTerm term;
  DateTime? startDate;
  DateTime? endDate;
  int reward;
  int quantity;
  String? notes;
  List<Tag> tags;

  Goal({
    this.id = -1,
    this.profileId = -1,
    required this.term,
    this.startDate,
    required this.endDate,
    this.reward = 0,
    this.quantity = 0,
    this.notes,
    required this.tags,
  });

  static const String tableName = 'meta';

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      id ${SQLiteModel.idType},
      plazo ${SQLiteModel.integerType} ${SQLiteModel.notNullType},
      fecha_inicio ${SQLiteModel.textType} ${SQLiteModel.notNullType},
      fecha_final ${SQLiteModel.textType} ${SQLiteModel.notNullType},
      recompensa ${SQLiteModel.integerType} ${SQLiteModel.notNullType},
      cantidad ${SQLiteModel.integerType} ${SQLiteModel.notNullType},
      notas ${SQLiteModel.textType},
      id_perfil ${SQLiteModel.integerType} ${SQLiteModel.notNullType},

      ${SQLiteModel.fk} (id_perfil) ${SQLiteModel.references} ${UserProfile.tableName} (id)
          ${SQLiteModel.onDelete} ${SQLiteModel.cascadeAction}
    )
  ''';

  static Goal fromMap(Map<String, Object?> map) {

    var tags = map['etiquetas'];
    List<Tag> tagList = <Tag>[];

    if (tags is List<Map<String, Object?>> && tags.isNotEmpty) {
      tagList = tags.map((tagMap) => Tag.fromMap(tagMap)).toList();
    }

    int indexPlazo = (map['plazo'] is int ? map['plazo'] as int : 0);

    final goal = Goal(
      id: (map['id'] is int ? map['id'] as int : -1),
      term: GoalTerm.values[indexPlazo],
      startDate: DateTime.parse(map['fecha_inicio'].toString()),
      endDate: DateTime.parse(map['fecha_final'].toString()),
      reward: (map['recompensa'] is int ? map['recompensa'] as int : -1),
      quantity: (map['cantidad'] is int ? map['cantidad'] as int : -1),
      notes: map['notas'].toString(),
      tags: tagList,
    );

    return goal;
  } 

  @override
  Map<String, Object?> toMap() {
    final Map<String, Object?> map = {
      'plazo': term.index,
      'fecha_inicio': startDate?.toIso8601String(), 
      'fecha_final': endDate?.toIso8601String(),
      'recompensa': reward,
      'cantidad': quantity,
      'notas': notes,
      'etiquetas': tags
    };

    if (id >= 0) map['id'] = id;

    return map;
  }

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
        tags.add(Tag(strTags.last));

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

  static String? validateEndDate(DateTime? startDateValue, String? endDateInput) {
    
    if (endDateInput != null) {
      DateTime? endDateValue = DateTime.tryParse(endDateInput);

      if (endDateValue != null && startDateValue != null)
      {
        return (endDateValue.isBefore(startDateValue) || endDateValue.isAtSameMomentAs(startDateValue))
          ? 'La fecha de termino debe ser mayor que la fecha de inicio.' 
          : null;
      }
    }
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