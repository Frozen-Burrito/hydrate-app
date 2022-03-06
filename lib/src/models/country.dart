

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
      id ${SQLiteModel.idType},
      codigo ${SQLiteModel.textType} ${SQLiteModel.notNullType}
    )
  ''';

  static Country fromMap(Map<String, dynamic> map) => Country(
    id: map['id'],
    code: map['codigo'],
  );

  @override
  Map<String, dynamic> toMap() {

    final Map<String, dynamic> map = {
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