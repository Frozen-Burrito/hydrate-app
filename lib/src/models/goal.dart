import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/enums/time_term.dart';
import 'package:hydrate_app/src/models/map_options.dart';
import 'package:hydrate_app/src/models/tag.dart';
import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/utils/numbers_common.dart';

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

  static const String tableName = "meta";

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

  static Goal fromMap(Map<String, Object?> map, { MapOptions options = const MapOptions(), }) {

    final attributeNames = options.mapAttributeNames(
      baseAttributeNames,
      specificAttributeMappings: options.useCamelCasePropNames ? { 
        endDateFieldName: "fechaTermino",
        rewardFieldName: "recompensaDeMonedas",
        quantityFieldName: "cantidadEnMl",
      } : const {}
    );

    final int hydrationGoalId = map.getIntegerOrDefault(
      attributeName: attributeNames[idFieldName]!,
      defaultValue: -1
    );

    final startDate = map.getDateTimeOrDefault(attributeName: attributeNames[startDateFieldName]!);
    final endDate = map.getDateTimeOrDefault(attributeName: attributeNames[endDateFieldName]!);

    final int termIndex = map.getEnumIndex(
      attributeName: attributeNames[termFieldName]!, 
      enumValuesLength: TimeTerm.values.length
    );
    final TimeTerm goalTimeTerm = TimeTerm.values[termIndex];

    final int coinReward = map.getIntegerOrDefault(attributeName: attributeNames[rewardFieldName]!);
    final int quantity = map.getIntegerOrDefault(attributeName: attributeNames[quantityFieldName]!);

    final bool isMainGoal = map.getBoolean(attributeNames[isMainGoalFieldName]!);

    final String notes = map[attributeNames[notesFieldName]!] != null 
      ? map[attributeNames[notesFieldName]!].toString()
      : "";

    final List<Tag> tagsForHydrationGoal = map.getGoalTags(
      attributeName: attributeNames[tagsFieldName]!, 
      mapOptions: options
    );

    final int profileId = map.getIntegerOrDefault(
      attributeName: attributeNames[profileIdFieldName]!, 
      defaultValue: UserProfile.defaultProfileId
    );

    final goal = Goal(
      id: hydrationGoalId,
      term: goalTimeTerm,
      startDate: startDate,
      endDate: endDate,
      reward: coinReward,
      quantity: quantity,
      isMainGoal: isMainGoal,
      notes: notes,
      tags: tagsForHydrationGoal,
      profileId: profileId
    );

    return goal;
  } 

  @override
  Map<String, Object?> toMap({ MapOptions options = const MapOptions(), }) {

    final attributeNames = options.mapAttributeNames(
      baseAttributeNames, 
      specificAttributeMappings: options.useCamelCasePropNames ? const { 
        endDateFieldName: "fechaTermino",
        rewardFieldName: "recompensaDeMonedas",
        quantityFieldName: "cantidadEnMl",
      } : const {
        profileIdFieldName: profileIdFieldName,
      }
    );

    final Map<String, Object?> map = {};

    if (id >= 0) map[attributeNames[idFieldName]!] = id;

    final List<Object?> mappedTags;
    final bool shouldIncludeTags;

    switch(options.subEntityMappingType) {
      case EntityMappingType.noMapping:
        mappedTags = tags;
        shouldIncludeTags = true;
        break;
      case EntityMappingType.asMap:
        mappedTags = tags
          .map((tag) => tag.toMap( options: options ))
          .toList();
        shouldIncludeTags = true;
        break;
      case EntityMappingType.idOnly:
        mappedTags = tags
          .map((tag) => tag.id)
          .toList();
        shouldIncludeTags = true;
        break;
      case EntityMappingType.notIncluded:
        mappedTags = <Object?>[];
        shouldIncludeTags = false;
        break;
    }

    map.addAll({
      attributeNames[termFieldName]!: term.index,
      attributeNames[startDateFieldName]!: startDate?.toIso8601String(), 
      attributeNames[endDateFieldName]!: endDate?.toIso8601String(),
      attributeNames[rewardFieldName]!: reward,
      attributeNames[quantityFieldName]!: quantity,
      attributeNames[notesFieldName]!: notes,
      attributeNames[profileIdFieldName]!: profileId,
    });

    if (shouldIncludeTags) {
      map[attributeNames[tagsFieldName]!] = mappedTags;
    }

    if (!options.useCamelCasePropNames) {
      map[attributeNames[isMainGoalFieldName]!] = isMainGoal ? 1 : 0; 
    }

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

    final strTags = inputValue.split(',').toList();

    if (strTags.isNotEmpty && strTags.first.isNotEmpty) {

      int tagCount = tags.length;
      int newTagCount = strTags.length;

      if (tagCount == newTagCount) {
        // Si el numero de tags es el mismo, solo cambió el valor de la última.
        tags.last = _tryToFindExistingTag(strTags.last, existingTags);
      
      } else {
        if (strTags.last.isNotEmpty) {
          if (tagCount < newTagCount) {
            // Crear una nueva etiqueta para el usuario.
            tags.add(_tryToFindExistingTag(strTags.last, existingTags));
          } else {
            // Si hay un tag menos, quita el último.
            tags.removeLast();
          }
        }
      }
    } else {
      tags.clear();
    }

    return inputValue.isEmpty ? 0 : tags.length;
  }

  Tag _tryToFindExistingTag(String inputTagValue, List<Tag> existingTags) {
    // Revisar si la etiqueta introducida ya fue creado por el usuario.
    final matchingTags = existingTags.where((tag) => tag.value == inputTagValue);

    if (matchingTags.isNotEmpty) {
      // Ya existe una etiqueta con el valor, hacer referencia a ella.
      final existingTag = matchingTags.first;

      return Tag(
        existingTag.value, 
        id: existingTag.id, 
        profileId: existingTag.profileId
      );
    } else {
      return Tag(
        inputTagValue,
        id: -1,
        profileId: -1,
      );
    }
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

extension _GoalMapExtension on Map<String, Object?> {

  List<Tag> getGoalTags({
    required String attributeName,
    required MapOptions mapOptions,
    List<Tag> availableTags = const <Tag>[],
  }) {
    final List<Tag> tagList = <Tag>[];
    final Object? tagsFromMap = this[attributeName];

    if (tagsFromMap is List<Map<String, Object?>>) {
      tagList.addAll(tagsFromMap.map((tagAsMap) => Tag.fromMap(tagAsMap, options: mapOptions)));

    } else if (tagsFromMap is List<int>) {
      final tagsForGoal = availableTags.where((tag) => tagsFromMap.contains(tag.id));
      tagList.addAll(tagsForGoal);
    }

    return tagList;
  }

  int getEnumIndex({
    required String attributeName,
    required int enumValuesLength,
  }) 
  {
    final int parsedIndex = int.tryParse(this[attributeName].toString()) ?? 0;
    final int constrainedIndex = constrain(
      parsedIndex, 
      min: 0,
      max: enumValuesLength - 1,
    );

    return constrainedIndex;
  }

  int getIntegerOrDefault({ required String attributeName, int defaultValue = 0 }) {
    return int.tryParse(this[attributeName].toString()) ?? defaultValue;
  }

  bool getBoolean(String attributeName) {

    final attributeValue = this[attributeName];
    final bool parsedValue;

    if (attributeValue is bool) {
      parsedValue =  attributeValue;
    } else if (attributeValue is int) {
      parsedValue = attributeValue != 0;
    } else if (attributeValue is String) {
      parsedValue = (attributeValue == "true");
    } else {
      parsedValue = false;
    }

    return parsedValue;
  }

  DateTime? getDateTimeOrDefault({
    required String attributeName, 
    DateTime? defaultValue,
  }) {
    final parsedDateTime = DateTime.tryParse(this[attributeName].toString()) 
        ?? defaultValue;

    return parsedDateTime;
  }
}
