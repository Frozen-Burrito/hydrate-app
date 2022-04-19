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

  static Environment fromMap(Map<String, dynamic> map) {
    
    return Environment(
      id: map['id'],
      imagePath: map['archivo_img'],
      price: map['precio'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
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