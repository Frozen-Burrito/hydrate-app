import 'package:hydrate_app/src/db/sqlite_model.dart';

class Environment extends SQLiteModel {

  int id;
  final String imagePath;
  int price;

  Environment({
    this.id = -1, 
    this.imagePath = 'assets/img/placeholder.png', 
    this.price = 0 
  });

  static const String tableName = 'entorno';

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      id ${SQLiteModel.idType},
      archivo_img ${SQLiteModel.textType} ${SQLiteModel.notNullType},
      precio ${SQLiteModel.integerType} ${SQLiteModel.notNullType}
    )
  ''';

  static Environment fromMap(Map<String, Object?> map) {
    
    return Environment(
      id: (map['id'] is int ? map['id'] as int : -1),
      imagePath: map['archivo_img'].toString(),
      price: (map['precio'] is int ? map['precio'] as int : -1),
    );
  }

  @override
  Map<String, Object?> toMap() {
    final Map<String, Object?> map = {
      'archivo_img': imagePath,
      'precio': price
    };

    if (id >= 0) map['id'] = id;

    return map;
  } 
  
  @override
  String toString() {
    return 'Image path: $imagePath, price: $price';
  }
}