
/// Representa una entidad en una base de datos de SQLite.
/// 
/// Utilizada como clase base de las entidades.
class SQLiteModel {

  /// Retorna el nombre de la tabla del modelo en SQLite.
  String get table => 'default';

  /// Convierte la entidad a un mapa.
  Map<String, Object?> toMap() => {};
}