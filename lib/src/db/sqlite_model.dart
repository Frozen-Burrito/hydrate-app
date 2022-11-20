import 'package:hydrate_app/src/models/map_options.dart';

/// Representa una entidad en una base de datos de SQLite.
/// 
/// Utilizada como clase base de las entidades.
abstract class SQLiteModel {

  const SQLiteModel();

  int get id;

  /// Retorna el nombre de la tabla del modelo en SQLite.
  String get table => 'default';

  /// Convierte la entidad a un mapa.
  Map<String, Object?> toMap({
    MapOptions options,
  });
}