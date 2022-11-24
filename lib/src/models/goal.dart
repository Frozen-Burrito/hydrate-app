import 'package:flutter/foundation.dart';
import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/enums/time_term.dart';
import 'package:hydrate_app/src/models/map_options.dart';
import 'package:hydrate_app/src/models/tag.dart';
import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/models/validators/goal_validator.dart';
import 'package:hydrate_app/src/models/validators/range.dart';
import 'package:hydrate_app/src/utils/map_extensions.dart';

class Goal extends SQLiteModel {

  @override
  int id;

  int profileId;
  TimeTerm term;
  DateTime startDate;
  DateTime endDate;
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
    startDate: DateTime.now(),
    endDate: DateTime.now().add(defaultGoalDuration),
    reward: 0,
    quantity: 0,
    isMainGoal: false,
    notes: '',
    tags: <Tag>[]
  );

  static const GoalValidator validator = GoalValidator();

  static const int maxSimultaneousGoals = 3;
  static const Duration defaultGoalDuration = Duration(days: 7);

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

  static final defaultFieldValues = <String, Object?>{
    termFieldName: TimeTerm.daily,
    startDateFieldName: DateTime.now(),
    endDateFieldName: DateTime.now().add(defaultGoalDuration),
    rewardFieldName: 0,
    quantityFieldName: 0,
    notesFieldName: null,
    tagsFieldName: <Tag>[],
  };

  static const requiredFields = <String>{
    startDateFieldName,
    endDateFieldName,
    rewardFieldName,
    quantityFieldName,
    notesFieldName,
  };

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
      attribute: attributeNames[idFieldName]!,
      defaultValue: -1
    );

    final DateTime startDate = map.getDateTimeOrDefault(
      attribute: attributeNames[startDateFieldName]!,
      defaultValue: DateTime.now()
    )!;
    final DateTime endDate = map.getDateTimeOrDefault(

      attribute: attributeNames[endDateFieldName]!,
      defaultValue: DateTime.now().add(defaultGoalDuration)
    )!;

    final int termIndex = map.getIntegerInRange(
      attribute: attributeNames[termFieldName]!, 
      range: Range( min: 0, max: TimeTerm.values.length ),
    );
    final TimeTerm goalTimeTerm = TimeTerm.values[termIndex];

    final int coinReward = map.getIntegerOrDefault(attribute: attributeNames[rewardFieldName]!);
    final int quantity = map.getIntegerOrDefault(attribute: attributeNames[quantityFieldName]!);

    final bool isMainGoal = map.getBoolOrDefault(attribute: attributeNames[isMainGoalFieldName]!);

    final String notes = map[attributeNames[notesFieldName]!] != null 
      ? map[attributeNames[notesFieldName]!].toString()
      : "";

    final List<Tag> tagsForHydrationGoal = map.getEntityCollection<Tag>(
      attribute: attributeNames[tagsFieldName]!, 
      mapper: (map, { options }) => Tag.fromMap(map, options: options ?? const MapOptions()),
    ).toList();

    final int profileId = map.getIntegerOrDefault(
      attribute: attributeNames[profileIdFieldName]!, 
      defaultValue: UserProfile.defaultProfile.id
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
      attributeNames[startDateFieldName]!: startDate.toIso8601String(), 
      attributeNames[endDateFieldName]!: endDate.toIso8601String(),
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

  @override
  bool operator==(Object? other) {

    if (other is! Goal) return false;

    final isIdEqual = id == other.id;
    final isProfileIdEqual = profileId == other.profileId;
    final isTermEqual = term.index == other.term.index;
    final isStartDateEqual = startDate.isAtSameMomentAs(other.startDate);
    final isEndDateEqual = endDate.isAtSameMomentAs(other.endDate);
    final isRewardEqual = reward == other.reward;
    final isWaterVolumeEqual = quantity == other.quantity;
    final areTagsEqual = listEquals(tags, other.tags);

    return isIdEqual && isProfileIdEqual && isTermEqual && isStartDateEqual &&
          isEndDateEqual && isRewardEqual && isWaterVolumeEqual && areTagsEqual;
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    profileId,
    term,
    startDate,
    endDate,
    reward,
    quantity,
    isMainGoal,
    notes,
    tags,
  ]);
}
