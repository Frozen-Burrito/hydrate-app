
class SQLiteKeywords {

  /// Tipos de dato
  static const textType = 'TEXT';
  static const boolType = 'BOOLEAN';
  static const integerType = 'INTEGER';
  static const realType = 'REAL';
  static const idType = '$integerType PRIMARY KEY AUTOINCREMENT';
  static const notNullType = 'NOT NULL';

  /// Llaves foráneas.
  static const fk = 'FOREIGN KEY';
  static const references = 'REFERENCES';

  /// Eventos en restricciones de llaves foráneas.
  static const onUpdate = 'ON UPDATE';
  static const onDelete = 'ON DELETE';

  /// Acciones
  static const cascadeAction = 'CASCADE';
  static const noAction = 'NO ACTION';
  static const setDefaultAction = 'SET DEFAULT';
  static const setNullAction = 'SET NULL';
  static const restrictAction = 'RESTRICT';

  /// Comandos
  static const dropTableIfExists = 'DROP TABLE IF EXISTS';
}