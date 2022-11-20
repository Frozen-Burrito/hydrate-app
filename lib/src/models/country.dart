import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/map_options.dart';

class Country extends SQLiteModel {
  
  @override
  final int id;
  final String code;

  const Country({ required this.id, required this.code });

  const Country.unspecified() : this(id: unspecifiedCountryId, code: "--");

  const Country.uncommitted() : this( id: -1, code: "--" );

  static const unspecifiedCountryId = 1;

  static const String tableName = 'pais';

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      id ${SQLiteKeywords.idType},
      codigo ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType}
    )
  ''';

  static Country fromMap(Map<String, Object?> map, { MapOptions options = const MapOptions(),}) => Country(
    id: (map['id'] is int ? map['id'] as int : -1),
    code: map['codigo'].toString().substring(0, 2),
  );

  @override
  Map<String, Object?> toMap({ MapOptions options = const MapOptions(), }) {

    final Map<String, Object?> map = {
      'codigo': code,
    };
    
    if (id >= 0) map['id'] = id;

    return map;
  } 

  @override
  bool operator ==(Object? other) {

    if (other is! Country) {
      return false;
    } 

    final otherCountry = other;

    final areIdsEqual = id == otherCountry.id;
    bool areCodesEqual = code == otherCountry.code;

    return areIdsEqual && areCodesEqual;
  }

  @override
  int get hashCode => Object.hashAll([ id, code ]);

  /// Verifica que [inputCode] no sea nulo, tenga exactamente dos caracteres.
  static String? validateCountryCode(String? inputCode) {
    return (inputCode == null || inputCode.length != 2)
        ? 'El código del país debe tener dos letras'
        : null;
  }
}