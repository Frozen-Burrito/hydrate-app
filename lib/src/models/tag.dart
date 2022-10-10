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
  
  @override
  String toString() {
    return value;
  }
}