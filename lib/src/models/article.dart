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

  static Article fromMap(Map<String, dynamic> map) => Article(
    id: map['id'],
    title: map['title'],
    description: map['description'],
    url: map['url'],
    publishDate: DateTime.parse(map['publishDate']),
    isBookmarked: false
  );

  @override
  String get table => 'article';

  @override
  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'url': url,
    'publishDate': publishDate?.toIso8601String() ?? 'No date',
  };
}