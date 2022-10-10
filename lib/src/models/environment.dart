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

  static const int firstUnlockedId = 1;

  static const int _dryEnvironmentThresholdMl = -250;
  static const int _moistEnvironmentThresholdMl = 250;

  static const String _environmentsPath = "assets/img/entornos/";

  static const String _envImgFileExt = "png";

  static const String _defaultEnvAssetPathEnding = "default";
  static const String _dryEnvAssetPathEnding = "seco";
  static const String _moistEnvAssetPathEnding = "humedo";

  Environment.firstUnlocked() : this(
    id: firstUnlockedId,
    imagePath: "1",
    price: 0,
  );

  static const String tableName = "entorno";

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      id ${SQLiteKeywords.idType},
      archivo_img ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      precio ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType}
    )
  ''';

  static Environment fromMap(Map<String, Object?> map, { MapOptions options = const MapOptions(),}) {
    
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

  /// Retorna el path para el [AssetImage] de este entorno según la 
  /// diferencia entre [current] y [target].
  /// 
  /// Si [current] es notablemente menor que [target], el path retornado
  /// es para una imagen del entorno seco.
  /// 
  /// Alternativamente, si [current] es mucho mayor que [target], el 
  /// path retornadoes para una imagen del entorno con humedad e inundado.
  /// 
  /// Si ninguno de estos casos se cumple, el path es para la imagen "por 
  /// defecto" de este [Environment].
  String imagePathForHydration(int current, int target) {

    final int hydrationDifference = current - target;
    final envImagePathBuffer = StringBuffer(_environmentsPath);

    envImagePathBuffer.writeAll([imagePath, "/"]);

    if (hydrationDifference > _moistEnvironmentThresholdMl) {

      envImagePathBuffer.write(_moistEnvAssetPathEnding);

    } else if (hydrationDifference < _dryEnvironmentThresholdMl) {

      envImagePathBuffer.write(_dryEnvAssetPathEnding);
    } else {
      envImagePathBuffer.write(_defaultEnvAssetPathEnding);
    }

    envImagePathBuffer.writeAll([".", _envImgFileExt]);

    return envImagePathBuffer.toString();
  }
  
  String get baseImagePath => imagePathForHydration(0, 0);

  @override
  String toString() {
    return "Image path: $imagePath, price: $price";
  }

  @override
  bool operator==(covariant Environment other) {

    final areIdsEqual = id == other.id;
    final areImgFilesEqual = imagePath == other.imagePath;
    final arePricesEqual = price == other.price;

    return areIdsEqual && areImgFilesEqual && arePricesEqual;
  }
  
  @override
  int get hashCode => Object.hashAll([
    id,
    imagePath,
    price,
  ]);
}