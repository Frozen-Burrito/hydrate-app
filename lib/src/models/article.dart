import 'dart:math';

import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/map_options.dart';

/// Un modelo que representa un Recurso Informativo.
/// 
/// Contiene un método de factory [Article.fromMap(map)], que crea una nueva 
/// instancia a partir de un mapa JSON. [toMap()] retorna un mapa JSON que 
/// representa este objeto.
class Article extends SQLiteModel {
  
  final int id;
  final String title;
  final String? description;
  final Uri? url;
  final DateTime? publishDate;
  bool isBookmarked;

  Article({
    this.id = -1,
    this.title = '',
    this.description,
    String articleUrl = '',
    this.publishDate,
    this.isBookmarked = false,
  }) : url = Uri.tryParse(articleUrl);

  @override
  String get table => tableName;

  static const String tableName = 'recurso_inf';

  static const String idFieldName = "id";
  static const String titleFieldName = "titulo";
  static const String descriptionFieldName = "descripcion";
  static const String urlFieldName = "url";
  static const String publishDateFieldName = "fecha_pub";

  /// Una lista con todos los nombres base de los atributos de la entidad.
  static const baseAttributeNames = <String>[
    idFieldName,
    titleFieldName,
    descriptionFieldName,
    urlFieldName,
    publishDateFieldName,
  ];

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      $idFieldName ${SQLiteKeywords.idType},
      $titleFieldName ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      $descriptionFieldName ${SQLiteKeywords.textType},
      $urlFieldName ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      $publishDateFieldName ${SQLiteKeywords.textType}
    )
  ''';

  static Article fromMap(
    Map<String, Object?> map, 
    { MapOptions options = const MapOptions(), }
  ) {
    
    final String campoFechaPub = options.useCamelCasePropNames 
      ? 'fechaPublicacion' 
      : publishDateFieldName;


    final trimmedDateString = (map[campoFechaPub] is String) 
      ? map[campoFechaPub].toString().trim()
      : '';

    final int maxDateStrLength = min(trimmedDateString.length, 27);

    return Article(
      id: (map[idFieldName] is int ? map[idFieldName] as int : -1),
      title: map[titleFieldName].toString(),
      description: map[descriptionFieldName].toString(),
      articleUrl: map[urlFieldName].toString(),
      publishDate: DateTime.tryParse(trimmedDateString.substring(0, maxDateStrLength)),
      isBookmarked: false
    );
  }

  @override
  Map<String, Object?> toMap({ MapOptions options = const MapOptions(), }) {

    // Modificar los nombres de los atributos para el Map resultante, según 
    // [options].
    final attributeNames = MapOptions.mapAttributeNames(baseAttributeNames, options);

    // Comprobar que hay una entrada por cada atributo de ActivityRecord.
    assert(attributeNames.length == baseAttributeNames.length);

    final String campoFechaPub = options.useCamelCasePropNames 
      ? 'fechaPublicacion' 
      : publishDateFieldName;

    // Se asume que el mapa de attributeNames contiene entradas para todos los 
    // atributos de baseAttributeNames, y que acceder con los atributos de 
    // baseAttributeNames nunca producirá null.
    final Map<String, Object?> map = {};

    // Solo incluir el ID de la entidad si es una entidad existente.
    if (id >= 0) map[attributeNames[idFieldName]!] = id;

    map.addAll({
      attributeNames[titleFieldName]!: title, 
      attributeNames[urlFieldName]!: url.toString(),
      attributeNames[descriptionFieldName]!: description,
      attributeNames[campoFechaPub]!: publishDate?.toIso8601String() ?? '',
    });

    return Map.unmodifiable(map);
  }

  @override
  bool operator==(covariant Article other) {

    final areIdsEqual = id == other.id;
    final areTitlesEqual = title == other.title;
    final areUrlsEqual = url == other.url;
    final areDescriptionsEqual = description == other.description;
    final arePublishedAtSameMoment = (publishDate != null && other.publishDate != null)
      ? publishDate!.isAtSameMomentAs(other.publishDate!)
      : publishDate == other.publishDate;

    return areIdsEqual && areTitlesEqual && areUrlsEqual && areDescriptionsEqual 
        && arePublishedAtSameMoment;
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    description,
    url,
    publishDate,
  ]);
}