import 'package:hydrate_app/src/db/sqlite_keywords.dart';
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
    this.id = -1,
    this.title = '',
    this.description,
    this.url = '',
    this.publishDate,
    this.isBookmarked = false,
  });

  @override
  String get table => tableName;

  static const String tableName = 'recurso_inf';

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      id ${SQLiteKeywords.idType},
      titulo ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      descripcion ${SQLiteKeywords.textType},
      url ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      fecha_pub ${SQLiteKeywords.textType}
    )
  ''';

  static Article fromMap(Map<String, Object?> map, { bool usarNombresDeAPI = false}) {
    
    String campoFechaPub = usarNombresDeAPI ? 'fechaPublicacion' : 'fecha_pub';

    return Article(
      id: (map['id'] is int ? map['id'] as int : -1),
      title: map['titulo'].toString(),
      description: map['descripcion'].toString(),
      url: map['url'].toString(),
      publishDate: DateTime.tryParse(map[campoFechaPub] is String ? map[campoFechaPub].toString(): ''),
      isBookmarked: false
    );
  }

  @override
  Map<String, Object?> toMap() {
    final Map<String, Object?> map = {
      'titulo': title,
      'descripcion': description,
      'url': url,
      'fecha_pub': publishDate?.toIso8601String() ?? 'No date',
    };

    if (id >= 0) map['id'] = id;

    return map;
  }
}

class ArticleCollection {

  List<Article> items = <Article>[];

  ArticleCollection.fromJsonCollection(List<dynamic> json) {

    for (var articleMap in json) {
      final article = Article.fromMap(articleMap, usarNombresDeAPI: true);
      items.add(article);
    }
  }
}