import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';

class Country extends SQLiteModel {
  
  int id;
  String code;

  Country({ this.id = -1, this.code = '--' });

  static const String tableName = 'pais';

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      id ${SQLiteKeywords.idType},
      codigo ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType}
    )
  ''';

  static Country fromMap(Map<String, Object?> map) => Country(
    id: (map['id'] is int ? map['id'] as int : -1),
    code: map['codigo'].toString().substring(0, 2),
  );

  @override
  Map<String, Object?> toMap() {

    final Map<String, Object?> map = {
      'codigo': code,
    };
    
    if (id >= 0) map['id'] = id;

    return map;
  } 

  /// Verifica que [inputCode] no sea nulo, tenga exactamente dos caracteres.
  static String? validateCountryCode(String? inputCode) {
    return (inputCode == null || inputCode.length != 2)
        ? 'El código del país debe tener dos letras'
        : null;
  }
}