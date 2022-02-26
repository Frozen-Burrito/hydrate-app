
/// Representa una entidad en una base de datos de SQLite.
/// 
/// Utilizada como clase base de las entidades.
abstract class SQLiteModel {

  const SQLiteModel();

  static const textType = 'TEXT';
  static const boolType = 'BOOLEAN';
  static const integerType = 'INTEGER';
  static const idType = '$integerType PRIMARY KEY AUTOINCREMENT';
  static const notNullType = 'NOT NULL';

  static const fk = 'FOREIGN KEY';
  static const references = 'REFERENCES';

  static const onUpdate = 'ON UPDATE';
  static const onDelete = 'ON DELETE';

  static const cascadeAction = 'CASCADE';
  static const noAction = 'NO ACTION';
  static const setDefaultAction = 'SET DEFAULT';
  static const setNullAction = 'SET NULL';
  static const restrictAction = 'RESTRICT';

  /// Retorna el nombre de la tabla del modelo en SQLite.
  String get table => 'default';

  /// Convierte la entidad a un mapa.
  Map<String, Object?> toMap() => {};
}