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

  static Tag fromMap(Map<String, dynamic> map) => Tag(
    map['valor'],
    id: map['id']
  );

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
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