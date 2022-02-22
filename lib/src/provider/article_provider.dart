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
  
  final List<Article> _bookmarkedArticles = [
    Article(id: 0, title: 'Un articulo guardado', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now(), isBookmarked: true),
    Article(id: 1, title: 'Un articulo guardado', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now(), isBookmarked: true),
    Article(id: 2, title: 'Un articulo para guardar', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now(), isBookmarked: true),
    Article(id: 3, title: 'Un articulo guardado', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now(), isBookmarked: true),
  ];

  /// La lista de artículos obtenidos desde la API.
  List<Article> get articles => _allArticles;

  /// La lista de artículos marcados y guardados por el usuario.
  List<Article> get bookmarks => _bookmarkedArticles;

  Future<int> bookmarkArticle(final Article article) async {

    int insertedId = -1;

    try {
      insertedId = await SQLiteDB.db.insert(article);
      _bookmarkedArticles.insert(0, article);
      notifyListeners();
    } catch (e) {
      print('Unable to save article.');
    }

    return insertedId;
  }
}