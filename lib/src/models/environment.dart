import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/map_options.dart';

class Environment extends SQLiteModel {

  final int id;
  final String imagePath;
  final int price;

  Environment({
    required this.id, 
    required this.imagePath, 
    required this.price
  });

  Environment.uncommited() : this(
    id: -1,
    imagePath: 'assets/img/entorno_1_agua.png',
    price: 999,
  );

  static const String tableName = 'entorno';

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      id ${SQLiteKeywords.idType},
      archivo_img ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      precio ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType}
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
  Map<String, Object?> toMap({ MapOptions options = const MapOptions(), }) {
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