import 'package:flutter/material.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/models/article.dart';

class ArticleProvider with ChangeNotifier {

  //TODO: Obtener recursos informativos reales por medio de la API web.
  final List<Article> _allArticles = [ 
    Article(id: 0, title: 'Un articulo de prueba', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
    Article(id: 1, title: 'Un articulo de prueba', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
    Article(id: 2, title: 'Un articulo de prueba', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
    Article(id: 3, title: 'Un articulo de prueba', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
    Article(id: 4, title: 'Un articulo de prueba', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
    Article(id: 5, title: 'Un articulo de prueba', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
    Article(id: 6, title: 'Un articulo de prueba', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
    Article(id: 7, title: 'Un articulo de prueba', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
    Article(id: 8, title: 'Agua y los elefantes', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
    Article(id: 9, title: 'Un articulo de prueba', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
  ];
  
  final List<Article> _bookmarkedArticles = [];

  bool _shouldRefreshBookmarks = true;

  /// La lista de artículos obtenidos desde la API.
  List<Article> get articles {

    return _allArticles.map((article) {

      int bookmarkIdx = _bookmarkedArticles.indexWhere((bookmark) => bookmark.id == article.id);
      if (bookmarkIdx > -1) {
        article.isBookmarked = true;
      }

      return article;
    }).toList();
  }

  /// La lista de artículos marcados y guardados por el usuario.
  List<Article> get bookmarks {
    
    try {
      if (_shouldRefreshBookmarks) {
        // Solo obtener bookmarks desde BD si hubo un cambio importante.
        print('Loading bookmarks');
        refreshBookmarks();
      }
    } catch (e) {
      print('Error obteniendo bookmarks');
    } 

    return _bookmarkedArticles;
  }

  /// Obtiene de la BD los [Article] marcados para leer más tarde.
  Future<void> refreshBookmarks() async {

    try {
      _bookmarkedArticles.clear();
      final articles = await SQLiteDB.db.select<Article>(Article.fromMap, 'recurso_inf');

      _bookmarkedArticles.addAll(articles.map((a) {
        a.isBookmarked = true;
        return a;
      }));

      _shouldRefreshBookmarks = false;
      notifyListeners();

    } on Exception catch (e) {
      print('Error refrescando de DB:\n$e');
    }    
  }

  /// Guarda localmente un [Article] para leer más tarde.
  /// 
  /// Retorna el ID del artículo insertado, o -1 si no fue
  /// posible insertar en la BD.
  Future<int> bookmarkArticle(final Article article) async {

    int insertedId = -1;

    try {
      article.isBookmarked = true;
      insertedId = await SQLiteDB.db.insert(article);
      _bookmarkedArticles.insert(0, article);
      notifyListeners();
    } catch (e) {
      print('Unable to save article.');
    }

    return insertedId;
  }

  /// Remueve la marca para leer más tarde de un [Article].
  /// 
  /// Retorna el ID del artículo removido, o -1 si no fue
  /// posible removerlo.
  Future<int> removeArticle(final int id) async {

    int resultId = -1;

    try {
      resultId = await SQLiteDB.db.delete('article', id);
      _bookmarkedArticles.removeWhere((article) => article.id == id);
      notifyListeners();
    } catch (e) {
      print('Unable to remove article');
    }

    return resultId;
  }
}