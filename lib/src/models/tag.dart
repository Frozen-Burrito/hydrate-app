import 'package:hydrate_app/src/db/sqlite_model.dart';

class Tag extends SQLiteModel {

  int id;
  String value;

  Tag(this.id, this.value);

  static Tag fromMap(Map<String, dynamic> map) => Tag(
    map['id'],
    map['value'],
  );

  @override 
  String get table => 'tag';

  @override
  Map<String, dynamic> toMap() => {
    'id': id,
    'value': value,
  };
  
  @override
  String toString() {
    return value;
  }
}