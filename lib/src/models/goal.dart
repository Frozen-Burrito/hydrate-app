import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/enums/time_term.dart';
import 'package:hydrate_app/src/models/map_options.dart';
import 'package:hydrate_app/src/models/tag.dart';
import 'package:hydrate_app/src/models/user_profile.dart';

class Goal extends SQLiteModel {

  int id;
  int profileId;
  TimeTerm term;
  DateTime? startDate;
  DateTime? endDate;
  int reward;
  int quantity;
  bool isMainGoal;
  String? notes;
  final List<Tag> tags;

  Goal({
    required this.id,
    required this.profileId,
    required this.term,
    required this.startDate,
    required this.endDate,
    required this.reward,
    required this.quantity,
    required this.isMainGoal,
    required this.notes,
    required this.tags,
  });

  Goal.uncommited() : this(
    id: -1,
    profileId: -1,
    term: TimeTerm.daily,
    startDate: null,
    endDate: null,
    reward: 0,
    quantity: 0,
    isMainGoal: false,
    notes: '',
    tags: <Tag>[]
  );

  static const int maxSimultaneousGoals = 3;

  static const String tableName = 'meta';

  static const String idFieldName = "id";
  static const String profileIdFieldName = "id_perfil";
  static const String termFieldName = "plazo";
  static const String startDateFieldName = "fecha_inicio";
  static const String endDateFieldName = "fecha_final";
  static const String rewardFieldName = "recompensa";
  static const String quantityFieldName = "cantidad";
  static const String isMainGoalFieldName = "es_principal";
  static const String notesFieldName = "notas";
  static const String tagsFieldName = "${Tag.tableName}s";

  /// Una lista con todos los nombres base de los atributos de la entidad.
  static const baseAttributeNames = <String>[
    idFieldName,
    profileIdFieldName,
    termFieldName,
    startDateFieldName,
    endDateFieldName,
    rewardFieldName,
    quantityFieldName,
    isMainGoalFieldName,
    notesFieldName,
    tagsFieldName,
  ];

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      $idFieldName ${SQLiteKeywords.idType},
      $termFieldName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      $startDateFieldName ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      $endDateFieldName ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      $rewardFieldName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      $quantityFieldName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      $isMainGoalFieldName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      $notesFieldName ${SQLiteKeywords.textType},
      $profileIdFieldName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},

      ${SQLiteKeywords.fk} (id_perfil) ${SQLiteKeywords.references} ${UserProfile.tableName} (id)
          ${SQLiteKeywords.onDelete} ${SQLiteKeywords.cascadeAction}
    )
  ''';

  static Goal fromMap(Map<String, Object?> map) {

    var tags = map['etiquetas'];
    List<Tag> tagList = <Tag>[];

    if (tags is List<Map<String, Object?>> && tags.isNotEmpty) {
      tagList = tags.map((tagMap) => Tag.fromMap(tagMap)).toList();
    }

    int indexPlazo = (map['plazo'] is int ? map['plazo'] as int : 0);

    const profileKey = 'id_${UserProfile.tableName}';
    final valProfileId = (map[profileKey] is int ? map[profileKey] as int : -1);

    final goal = Goal(
      id: (map['id'] is int ? map['id'] as int : -1),
      term: TimeTerm.values[indexPlazo],
      startDate: DateTime.parse(map['fecha_inicio'].toString()),
      endDate: DateTime.parse(map['fecha_final'].toString()),
      reward: (map['recompensa'] is int ? map['recompensa'] as int : -1),
      quantity: (map['cantidad'] is int ? map['cantidad'] as int : -1),
      isMainGoal: (int.tryParse(map['es_principal'].toString()) ?? 0) != 0,
      notes: map['notas'].toString(),
      tags: tagList,
      profileId: valProfileId
    );

    return goal;
  } 

  @override
  Map<String, Object?> toMap({ MapOptions options = const MapOptions(), }) {
    final Map<String, Object?> map = {
      'plazo': term.index,
      'fecha_inicio': startDate?.toIso8601String(), 
      'fecha_final': endDate?.toIso8601String(),
      'recompensa': reward,
      'cantidad': quantity,
      'es_principal': isMainGoal ? 1 : 0, 
      'notas': notes,
      'etiquetas': tags,
      'id_${UserProfile.tableName}': profileId,
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
  int parseTags(String? inputValue, List<Tag> existingTags) {

    if (inputValue == null) return 0;

    final strTags = inputValue.split(',');

    if (strTags.isNotEmpty) {

      int tagCount = tags.length;
      int newTagCount = strTags.length;

      if (tagCount == newTagCount) {
        // Si el numero de tags es el mismo, solo cambió el valor de la última.
        tags.last.value = strTags.last;
      
      } else if (tagCount < newTagCount && strTags.last.isNotEmpty) {
        // Revisar si la etiqueta introducida ya fue creado por el usuario.
        final tagsFound = existingTags.where((t) => t.value == strTags.last);

        if (tagsFound.isNotEmpty) {
          // Ya existe una etiqueta con el valor, hacer referencia a ella.
          tags.add(tagsFound.first);
        } else {
          // Crear una nueva etiqueta para el usuario.
          tags.add(Tag(strTags.last));
        }

      } else if (strTags.last.isNotEmpty) {
        // Si hay un tag menos, quita el último.
        tags.removeLast();
      }
    }

    return inputValue.isEmpty ? 0 : tags.length;
  }

  static String? validateTerm(int? termIndex) {

    if (termIndex == null) return 'Selecciona un plazo para la meta.';

    return (termIndex >= 0 && termIndex < TimeTerm.values.length) 
        ? null
        : 'Plazo para meta no válido';
  }

  static String? validateEndDate(DateTime? startDateValue, String? endDateInput) {
    
    if (endDateInput != null) {
      DateTime? endDateValue = DateTime.tryParse(endDateInput);

      if (endDateValue != null && startDateValue != null)
      {
        if (endDateValue.isBefore(startDateValue) || endDateValue.isAtSameMomentAs(startDateValue)) {
          return 'La fecha de termino debe ser mayor que la fecha de inicio.';
        }
      }
    }

    return null;
  }

  static String? validateWaterQuantity(String? inputValue) {
    if (inputValue == null) return 'Escribe una cantidad';

    int? waterQuantity = int.tryParse(inputValue);
    
    if (waterQuantity != null) {
      if (waterQuantity < 1 || waterQuantity > 1000) {
        return 'La cantidad debe ser entre 0 y 1000 ml.';
      }
    }

    return null;
  }

  static String? validateReward(String? inputValue) {

    int? reward = int.tryParse(inputValue ?? '0');
    
    if (reward != null) {
      if (reward < 0 || reward > 1000) {
        return 'La recompensa debe estar entre 0 y 1000.';
      }
    }

    return null;
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

      if (strTags.length > 3 && strTags.last.isNotEmpty) {
        return 'Una meta debe tener 3 etiquetas o menos.';
      }
    }

    return null;
  } 

  static String? validateNotes(String? inputValue) {
    return (inputValue != null && inputValue.length > 100)
        ? 'Las notas deben tener menos de 100 caracteres'
        : null;
  }
}