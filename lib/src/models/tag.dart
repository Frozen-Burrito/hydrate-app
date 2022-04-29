import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/user_profile.dart';

class Tag extends SQLiteModel {

  int id;
  String value;
  int profileId;

  Tag(
    this.value, {
      this.id = -1, 
      this.profileId = -1
    }
  );

  static const String tableName = 'etiqueta';

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      id ${SQLiteKeywords.idType},
      valor ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      id_perfil ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},

      ${SQLiteKeywords.fk} (id_perfil) ${SQLiteKeywords.references} ${UserProfile.tableName} (id)
          ${SQLiteKeywords.onDelete} ${SQLiteKeywords.cascadeAction}
    )
  ''';

  static Tag fromMap(Map<String, Object?> map) => Tag(
    map['valor'].toString(),
    id: int.tryParse(map['id'].toString()) ?? -1,
    profileId: int.tryParse(map['id_perfil'].toString()) ?? -1,
  );

  @override
  Map<String, Object?> toMap() {
    final Map<String, Object?> map = {
      'valor': value,
      'id_perfil': profileId
    };

    if (id >= 0) map['id'] = id;

    return map;
  } 
  
  @override
  String toString() {
    return value;
  }
}