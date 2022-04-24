import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/models/api.dart';
import 'package:hydrate_app/src/models/article.dart';

class ArticleProvider with ChangeNotifier {

  final List<Article> _allArticles = [];
  
  final List<Article> _bookmarkedArticles = [];

  bool articlesLoading = true;
  bool articlesError = false;

  bool _shouldRefreshArticles = true;

  bool _bookmarksLoading = true;
  bool _bookmarksError = false;

  bool _shouldRefreshBookmarks = true;

  bool _mounted = true;

  bool get areBookmarksLoading => _bookmarksLoading;
  bool get bookmarksError => _bookmarksError;

  /// La lista de artículos obtenidos desde la API.
  List<Article> get articles {

    if (_shouldRefreshArticles) {
      fetchArticles();
    }

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
        _bookmarksLoading = true;
        refreshBookmarks();
      }
    } catch (e) {
      _bookmarksLoading = false;
      _bookmarksError = true;
    } 

    return _bookmarkedArticles;
  }

  /// Intenta obtener una [List<Article>] desde la API web.
  /// 
  /// ! NECESITA conexión a internet.
  /// 
  /// Hace una petición GET a la API web de recursos informativos.
  /// Si logra obtener los recursos informativos, actualiza la lista local de
  /// recursos nuevos. Si surge un error, cambia el estado de [articlesError]
  /// a [true].
  Future fetchArticles() async {

    _allArticles.clear();

    articlesLoading = true;
    articlesError = false;

    try {
      _shouldRefreshArticles = false;

      // Enviar petición GET a /recursos de la api.
      final response = await API.get('/recursos');

      if (response.statusCode == 200) {
        // La petición fue exitosa. Obtener recursos informativos de su body.
        final jsonCollection = json.decode(response.body);

        final articles = ArticleCollection.fromJsonCollection(jsonCollection);

        _allArticles.addAll(articles.items);

        articlesError = false;
      } else {
        articlesError = true;
        print('Hubo un error obteniendo los recursos informativos.');
      }

    } on IOException catch (e) {
      // Es lanzada por http si el dispositivo no tiene internet. 
      print('El dispositivo no cuenta con conexion a internet: $e');
      articlesError = true;

    } on FormatException catch (e) {
      // Lanzada por http si no logra hacer el parse de la URL solicitada.
      print('Error de formato en url: ${e.message}');
      articlesError = true;
      
    } finally {
      // Evitar que se vuelva a refrescar, indiacar que ya no se están cargando
      // los artículos.
      _shouldRefreshArticles = false;
      articlesLoading = false;

      if (_mounted) {
        notifyListeners();
      }
    }
  }

  /// Obtiene de la BD los [Article] marcados para leer más tarde.
  Future<void> refreshBookmarks() async {

    try {
      _bookmarkedArticles.clear();
      final articles = await SQLiteDB.instance.select<Article>(Article.fromMap, Article.tableName);

      _bookmarkedArticles.addAll(articles.map((a) {
        a.isBookmarked = true;
        return a;
      }));

      _shouldRefreshBookmarks = false;
      _bookmarksError = false;

    } on Exception catch (e) {
      
      _bookmarksError = true;
    } finally {
      if (_mounted) {
        _bookmarksLoading = false;
        notifyListeners();
      }
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
      insertedId = await SQLiteDB.instance.insert(article);
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
      resultId = await SQLiteDB.instance.delete('recurso_inf', id);

      _allArticles.firstWhere((article) => article.id == id).isBookmarked = false;
      _bookmarkedArticles.removeWhere((article) => article.id == id);

      notifyListeners();
    } on Exception catch (e) {
      print('Unable to remove article: ${e.toString()}');
    }

    return resultId;
  }

  @override
  void dispose() {
    super.dispose();
    _mounted = false;
  }
}