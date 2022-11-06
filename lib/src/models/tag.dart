import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/map_options.dart';
import 'package:hydrate_app/src/models/user_profile.dart';

class Tag extends SQLiteModel {

  final int id;
  final String value;
  int profileId;

  Tag(this.value, {
      this.id = -1, 
      this.profileId = -1
    }
  );

  static const String tableName = "etiqueta";

  static const String idFieldName = "id";
  static const String valueFieldName = "valor";
  static const String profileIdFieldName = "id_perfil";

  static const List<String> baseAttributeNames = <String>[
    idFieldName,
    valueFieldName,
    profileIdFieldName,
  ];

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      $idFieldName ${SQLiteKeywords.idType},
      $valueFieldName ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      $profileIdFieldName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},

      ${SQLiteKeywords.fk} ($profileIdFieldName) ${SQLiteKeywords.references} ${UserProfile.tableName} (${UserProfile.idFieldName})
          ${SQLiteKeywords.onDelete} ${SQLiteKeywords.cascadeAction}
    )
  ''';

  static Tag fromMap(Map<String, Object?> map, { MapOptions options = const MapOptions(), }) {

    final attributeNames = options.mapAttributeNames(baseAttributeNames); 

    final int id = int.tryParse(map[attributeNames[idFieldName]!].toString()) ?? -1;
    final String value = map[attributeNames[valueFieldName]!].toString();
    final int profileId = int.tryParse(map[attributeNames[profileIdFieldName]!].toString()) ?? -1;

    return Tag(
      value,
      id: id,
      profileId: profileId,
    );
  }

  @override
  Map<String, Object?> toMap({ MapOptions options = const MapOptions(), }) {

    final attributeNames = options.mapAttributeNames(
      baseAttributeNames,
      specificAttributeMappings: options.useCamelCasePropNames 
        ? const {}
        : const {
        profileIdFieldName: profileIdFieldName,
      }
    );

    final Map<String, Object?> map = {};

    if (id >= 0) map[attributeNames[idFieldName]!] = id;

    map.addAll({
      attributeNames[valueFieldName]!: value,
      attributeNames[profileIdFieldName]!: profileId,
    });

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
  static List<Tag> parseFromString(List<Tag> currentTags, String? inputValue, List<Tag> existingTags) {

    if (inputValue == null) return const <Tag>[];

    final strTags = inputValue.split(',').toList();

    final List<Tag> updatedTags = List.from(currentTags);

    if (strTags.isNotEmpty && strTags.first.isNotEmpty) {

      int tagCount = currentTags.length;
      int newTagCount = strTags.length;

      if (tagCount == newTagCount) {
        // Si el numero de tags es el mismo, solo cambió el valor de la última.
        updatedTags.last = _tryToFindExistingTag(strTags.last, existingTags);
      
      } else {
        if (strTags.last.isNotEmpty) {
          if (tagCount < newTagCount) {
            // Crear una nueva etiqueta para el usuario.
            updatedTags.add(_tryToFindExistingTag(strTags.last, existingTags));
          } else {
            // Si hay un tag menos, quita el último.
            updatedTags.removeLast();
          }
        }
      }
    } else {
      updatedTags.clear();
    }

    return updatedTags;
  }

  static Tag _tryToFindExistingTag(String inputTagValue, List<Tag> existingTags) {
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

  @override
  String toString() {
    return value;
  }
}