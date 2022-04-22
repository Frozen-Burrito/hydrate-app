import 'package:hydrate_app/src/db/sqlite_model.dart';

class Tag extends SQLiteModel {

  int id;
  String value;

  Tag(this.value, {this.id = -1});

  static const String tableName = 'etiqueta';

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      id ${SQLiteModel.idType},
      valor ${SQLiteModel.textType} ${SQLiteModel.notNullType}
    )
  ''';

  static Tag fromMap(Map<String, Object?> map) => Tag(
    map['valor'].toString(),
    id: int.tryParse(map['id'].toString()) ?? -1,
  );

  @override
  Map<String, Object?> toMap() {
    final Map<String, Object?> map = {
      'valor': value,
    };

    if (id >= 0) map['id'] = id;

    return map;
  } 
  
  @override
  String toString() {
    return value;
  }
}