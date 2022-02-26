import 'package:hydrate_app/src/db/sqlite_model.dart';

class Tag extends SQLiteModel {

  int id;
  String value;

  Tag(this.id, this.value);

  String get table => 'etiqueta';

  static const String createTableQuery = '''
    CREATE TABLE etiqueta (
      id ${SQLiteModel.idType},
      valor ${SQLiteModel.textType} ${SQLiteModel.notNullType}
    )
  ''';

  static Tag fromMap(Map<String, dynamic> map) => Tag(
    map['id'],
    map['valor'],
  );

  @override 

  @override
  Map<String, dynamic> toMap() => {
    // 'id': id,
    'valor': value,
  };
  
  @override
  String toString() {
    return value;
  }
}