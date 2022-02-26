import 'package:hydrate_app/src/db/sqlite_model.dart';

/// Un modelo que representa un Recurso Informativo.
/// 
/// Contiene un método de factory [Article.fromMap(map)], que crea una nueva 
/// instancia a partir de un mapa JSON. [toMap()] retorna un mapa JSON que 
/// representa este objeto.
class Article extends SQLiteModel {
  
  int id;
  String title;
  String? description;
  String url;
  DateTime? publishDate;
  bool isBookmarked;

  Article({
    required this.id,
    required this.title,
    this.description,
    required this.url,
    this.publishDate,
    this.isBookmarked = false,
  });

  @override
  String get table => 'recurso_inf';

  static const String createTableQuery = '''
    CREATE TABLE recurso_inf (
      id ${SQLiteModel.idType},
      titulo ${SQLiteModel.textType} ${SQLiteModel.notNullType},
      descripcion ${SQLiteModel.textType},
      url ${SQLiteModel.textType} ${SQLiteModel.notNullType},
      fecha_pub ${SQLiteModel.textType}
    )
  ''';

  static Article fromMap(Map<String, dynamic> map) => Article(
    id: map['id'],
    title: map['titulo'] ?? '',
    description: map['descripcion'],
    url: map['url'],
    publishDate: DateTime.parse(map['fecha_pub'] ?? ''),
    isBookmarked: false
  );

  @override
  Map<String, Object?> toMap() => {
    // 'id': id,
    'titulo': title,
    'descripcion': description,
    'url': url,
    'fecha_pub': publishDate?.toIso8601String() ?? 'No date',
  };
}