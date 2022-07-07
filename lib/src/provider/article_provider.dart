import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/models/api.dart';
import 'package:hydrate_app/src/models/article.dart';
import 'package:hydrate_app/src/provider/cache_state.dart';

class ArticleProvider with ChangeNotifier {

  late final CacheState<List<Article>> _allArticlesCache = CacheState(
    fetchData: _fetchArticles,
    onDataRefreshed: _isMounted ? (_) => notifyListeners() : null,
  );

  late final CacheState<List<Article>> _bookmarkedArticlesCache = CacheState(
    fetchData: _fetchBookmarks,
    onDataRefreshed: _isMounted ? (_) => notifyListeners() : null,
  );

  bool _isMounted = true;

  bool get hasNetArticlesData => _allArticlesCache.hasData;

  /// Retorna todos los [Article] disponibles a través de la API.
  Future<List<Article>?> get allArticles => _allArticlesCache.data;

  bool get hasBookmarkedArticlesData => _bookmarkedArticlesCache.hasData;

  /// Retorna todos los [Article] disponibles a través de la API.
  Future<List<Article>?> get bookmarks => _allArticlesCache.data;

  /// Intenta obtener una [List<Article>] desde la API web.
  /// 
  /// ! NECESITA conexión a internet.
  /// 
  /// Hace una petición GET a la API web de recursos informativos.
  /// Si logra obtener los recursos informativos, actualiza la lista local de
  /// recursos nuevos. Si surge un error, cambia el estado de [articlesError]
  /// a [true].
  Future<List<Article>> _fetchArticles() async {

    try {
      // Enviar petición GET a /recursos de la api.
      final response = await API.get('/recursos');

      if (response.statusCode == HttpStatus.ok) {
        // La petición fue exitosa. Obtener recursos informativos de su body.
        final jsonCollection = json.decode(response.body);

        // Transformar la respuesta en JSON a una colección de recursos informativos.
        final articles = ArticleCollection.fromJsonCollection(jsonCollection);

        // Obtener bookmarks, si están disponibles.
        final bookmarks = await _bookmarkedArticlesCache.data;

        return bookmarks == null 
          ? articles.items
          : articles.items.map((article) {
            // Ver si el recurso informativo se encuentra entre los marcadores del usuario.
            int bookmarkIdx = bookmarks.indexWhere((bookmark) => bookmark.id == article.id);

            // Si existe, el recurso informativo ha sido marcado.
            if (bookmarkIdx > -1) {
              article.isBookmarked = true;
            }

            return article;
          }).toList();

      } else {
        print('Hubo un error obteniendo los recursos informativos.');
      }

    } on IOException catch (e) {
      // Es lanzada por http si el dispositivo no tiene internet. 
      print('El dispositivo no cuenta con conexion a internet: $e');

    } on FormatException catch (e) {
      // Lanzada por http si no logra hacer el parse de la URL solicitada.
      print('Error de formato en url: ${e.message}');
    }

    return [];
  }

  /// Obtiene de la BD los [Article] marcados para leer más tarde.
  Future<List<Article>> _fetchBookmarks() async {

    final articles = await SQLiteDB.instance.select<Article>(
      Article.fromMap, 
      Article.tableName
    );

    return articles.where((article) => article.isBookmarked).toList();
  }

  /// Guarda localmente un [Article] para leer más tarde.
  /// 
  /// Retorna el ID del artículo insertado, o -1 si no fue
  /// posible insertar en la BD.
  Future<int> bookmarkArticle(final Article article) async {

    try {
      // Marcar el articulo y guardarlo en la BD.
      article.isBookmarked = true;
      int insertedId = await SQLiteDB.instance.insert(article);

      if (insertedId >= 0) {
        _bookmarkedArticlesCache.shouldRefresh();
        _allArticlesCache.shouldRefresh();
        return insertedId;

      } else {
        throw Exception('No se pudo crear un marcador para el articulo.');
      }
    }
    on Exception catch (e) {
      return Future.error(e);
    }
  }

  /// Remueve la marca para leer más tarde de un [Article].
  /// 
  /// Retorna [true] si el bookmark fue removido.
  Future<bool> removeArticle(final int id) async {

    try {
      int resultId = await SQLiteDB.instance.delete(Article.tableName, id);

      if (resultId > 0) {
        _bookmarkedArticlesCache.shouldRefresh();
        _allArticlesCache.shouldRefresh();

        return true;
      }

    } on Error catch (e) {
      print('No fue posible quitar el marcador del articulo: ${e.toString()}');
    }

    return false;
  }

  @override
  void dispose() {
    super.dispose();
    _isMounted = false;
  }
}