import 'dart:io';

import 'package:flutter/material.dart';

import 'package:hydrate_app/src/api/articles_api.dart';
import 'package:hydrate_app/src/api/paged_result.dart';
import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/models/article.dart';
import 'package:hydrate_app/src/provider/cache_state.dart';

/// Describe el tipo de fuente para recursos informativos que va a 
/// usar un widget.
enum ArticleSource {
  /// Los artículos son obtenidos desde internet, usando la API web
  network, 
  /// Los artículos son los marcados, que están guardados localmente.
  bookmarks, 
}

/// Mantiene el estado para colecciones de [Article] con recursos informativos,
/// obtenidos de diversas [ArticleSource]. 
/// 
/// Implementa paginación de resultados y caching para optimizar el uso de 
/// recursos y tiempo de carga.
/// 
/// NOTA: los bookmarks todavía no implementan paginación de resultados.
class ArticleProvider with ChangeNotifier {

  /// Crea una nueva instancia simple de [ArticleProvider].
  ArticleProvider() : _scrollController = ScrollController() {
    // Registrar handler para escuchar cambios en el scroll de las listas.
    _scrollController.addListener(_handleScrollToBottom);
    
    // Iniciar a cargar los recursos informativos.
    _allArticlesCache.refresh();
    _bookmarkedArticlesCache.refresh();
  }

  /// Contiene todos los [Article] que han sido obtenidos desde la API, 
  /// independientemente de su página o momento de carga.
  late final CacheState<List<Article>> _allArticlesCache = CacheState(
    fetchData: _fetchArticles,
    dataUpdateHandler: _aggregateResults,
    onDataRefreshed: _handleOnArticlesLoaded
  );

  late final CacheState<List<Article>> _bookmarkedArticlesCache = CacheState(
    fetchData: _fetchBookmarks,
    onDataRefreshed: (fetchedBookmarks) {
      if (_isMounted && fetchedBookmarks != null) {
        notifyListeners();
      }
    }
  );

  /// El estado de este provider. Métodos como [notifyListeners()] no deben 
  /// invocados cuando este valor es **false**.
  bool _isMounted = true;

  /// Un cliente HTTP con la implementación de la API web de Hydrate 
  /// para recursos informativos.
  final _articlesApi = ArticlesApi();
  
  int _currentTabIndex = 0;
  static const int discoverTabIndex = 0;
  static const int bookmarksTabIndex = 1;
  static const int articleTabsLength = 2;

  /// Modifica el valor del índice de la pestaña actual de recursos informativos.
  set currentTabIndex(int tabIndex) => _currentTabIndex = tabIndex;

  final ScrollController _scrollController;
  static const double _doRefreshOffsetPixels = 10.0;

  /// El controlador que define cúando es necesario cargar más recursos.
  ScrollController get scrollController => _scrollController;

  /// El resultado paginado más reciente para cargar nuevos artículos.
  PagedResult? _latestArticleResults;

  /// Todos los [Article] obtenidos usando la API. Esta lista es actualizada
  /// por páginas, cada vez que el contenido de [scrollController] se 
  /// acerca al final de su extent
  List<Article> get allArticles 
      => List.unmodifiable(_allArticlesCache.cachedData ?? <Article>[]);

  /// Es **true** cuando este provider está haciendo una petición
  /// para cargar más [Article]s.
  bool get isFetchingAllArticles => _allArticlesCache.isLoading;

  /// Es **true** cuando este provider está haciendo una petición
  /// para cargar más bookmarks de [Article]s.
  bool get isFetchingBookmarks => _allArticlesCache.isLoading;

  /// Todos los [Article] que han sido marcados para leer más tarde y 
  /// guardados localmente. Esta lista no es actualizada con paginación.
  List<Article> get bookmarks 
      => List.unmodifiable(_bookmarkedArticlesCache.cachedData ?? <Article>[]);

  /// Obtiene los elementos de la siguiente página de resultados de [Article] 
  /// desde la API web. Luego, si pudo obtener el resultado paginado con éxito,
  /// actualiza el estado de este provider con los resultados.
  /// 
  /// NOTA: Este método requiere de conexión a internet.
  Future<List<Article>> _fetchArticles() async {
    //TODO: (No esencial) remover articulos que ya no son necesarios (los que quedan hasta arriba en el scroll)
    final List<Article> fetchedArticles = <Article>[];

    print("Obteniendo recursos informativos...");

    final hasNextPage = _latestArticleResults?.uriForNextPage != null
                     || _latestArticleResults == null;

    // Revisar si la API puede dar más resultados.
    if (hasNextPage) {
      try {
        // Determinar el índice de la siguiente página.
        final nextPageIndex = _latestArticleResults != null 
          ? _latestArticleResults!.currentPage + 1
          : 0;

        assert(
          (_latestArticleResults != null && nextPageIndex < _latestArticleResults!.totalPages) || true, 
          'trying to fetch a page that does not exist'
        );

        // Intentar obtener los resultados de la siguiente pagina.
        final newArticles = await _articlesApi.fetchArticles(pageIndex: nextPageIndex);

        // Hacer que Article.isBookmarked sea true para todos los resultados que 
        // esten presentes en bookmarks.
        final resultsWithBookmarks = await _applyBookmarksToResults(newArticles.results);

        // Actualizar el valor del último resultado de la api.
        _latestArticleResults = newArticles;

        fetchedArticles.addAll(resultsWithBookmarks);

      } on IOException catch(ex) {
        // Es lanzada por http si el dispositivo no tiene internet. 
        print('El dispositivo no cuenta con conexion a internet: $ex');
      } on FormatException catch (ex) {
        //TODO: Revisar si FormatException puede ser lanzada por el codigo del try.
        // Lanzada por http si no logra hacer el parse de la URL solicitada.
        print('Error de formato en url: $ex');
      }
    } else {
      // Indicar de alguna forma a los listeners del provider que ya no hay mas 
      // resultados.
      //TODO: avisar cuando ya no hay mas recursos informativos que obtener.
      print("No more articles available");
    }

    print("${fetchedArticles.length} articles fetched.");

    return fetchedArticles;
  }

  /// Obtiene de la BD los [Article] marcados para leer más tarde.
  /// 
  /// Para todos los [Article] retornados, se asegura que [Article.isBookmarked] 
  /// será **true**.
  Future<List<Article>> _fetchBookmarks() async {
    // Todos los artículos obtenidos desde la base de datos local 
    // son bookmarks.
    final queryResults = await SQLiteDB.instance.select<Article>(
      Article.fromMap, 
      Article.tableName
    );

    // Marcar todos los bookmarks como tal.
    final bookmarkedArticles = queryResults.map((article) {
      article.isBookmarked = true;
      return article;
    });

    assert(
      bookmarkedArticles.every((a) => a.isBookmarked), 
      'Not every bookmark is marked as such'
    );

    return bookmarkedArticles.toList();
  }

  /// Obtiene los [Article] que fueron guardados con un marcador. Si un 
  /// [Article] está presente en los bookmarks y en [fetchedArticles], 
  /// se le asigna **true** a [Article.isBookmarked]. 
  Future<List<Article>> _applyBookmarksToResults(List<Article> fetchedArticles) async {
    // Obtener bookmarks, si están disponibles.
    final bookmarks = await _bookmarkedArticlesCache.data;

    if (bookmarks != null) {
      // Organizar los bookmarks por su ID.
      final bookmarksById = Map.fromEntries(
        bookmarks.map((b) => MapEntry(b.id, b))
      );

      for (final article in fetchedArticles) {
        // Revisar si el recurso informativo está en los bookmarks del perfil.
        final isArticleBookmarked = bookmarksById[article.id] == article;

        article.isBookmarked = isArticleBookmarked;
      }
    }

    return fetchedArticles;
  }

  /// Guarda localmente un [Article] para leer más tarde. Si puede
  /// ser marcado, actualiza [bookmarks] con el cambio.
  /// 
  /// Retorna **true** cuando el [Article] fue marcado con éxito y
  /// **false** cuando el artículo ya estaba marcado o hubo un error 
  /// al intentar marcarlo.
  Future<bool> bookmarkArticle(final Article article) async {

    // Si el artículo ya está marcado, no puede ser marcado otra vez.
    if (article.isBookmarked) return false;

    // Marcar el articulo y guardarlo en la BD.
    article.isBookmarked = true;
    final int newBookmarkId = await SQLiteDB.instance.insert(article);

    final wasBookmarkSuccessful = newBookmarkId >= 0;

    if (wasBookmarkSuccessful) {
      // Si el artículo fue marcado, refrescar los registros de bookmarks.
      _bookmarkedArticlesCache.refresh();
    }

    return wasBookmarkSuccessful;
  }

  /// Remueve la marca para leer más tarde (bookmark) de un [Article] y 
  /// actualiza las listas de [allArticles] [bookmarks] con el cambio.
  /// 
  /// Retorna **true** si el bookmark fue removido, o **false** si hubo un 
  /// error al intentar eliminar el bookmark.
  Future<bool> removeBookmark(final Article article) async {
    // Eliminar la copia local del artículo. 
    final int removedBookmarkID = await SQLiteDB.instance.delete(
      Article.tableName, 
      article.id
    );

    final wasRemoveSuccessful = removedBookmarkID >= 0;

    if (wasRemoveSuccessful) {
      // Revisar si el artículo removido está disponible en la colección de 
      // todos los artículos. Si es así, actualizar su registro.
      final existingArticles = (await _allArticlesCache.data) ?? <Article>[];

      final articleInAllArticles = existingArticles.where((a) => a.id == article.id);
      if (articleInAllArticles.length == 1) {
        // Si el artículo existe en la lista con todos los artículos, indicar
        // que ya no está marcado.
        articleInAllArticles.single.isBookmarked = false;
      } 

      // Notificar el cambio en los bookmarks y obtener bookmarks actualizados.
      _bookmarkedArticlesCache.refresh();
    }

    return wasRemoveSuccessful;
  }

  /// Si es necesario, inicia a cargar más [Article]s desde la API.
  /// 
  /// Es invocado cuando cambia la posición de [_scrollController] Si la 
  /// posición está cerca de su [maxExtent] y no hay una petición en progreso,
  /// invoca a [_allArticlesCache.refresh()]. 
  void _handleScrollToBottom() {

    final hasNextPage = _latestArticleResults?.uriForNextPage != null
                  || _latestArticleResults == null;

    // Si el caché no está cargando más datos, hay una página siguiente y el 
    // scroll está próximo al fondo del scrollview, cargar más resultados.
    if (!_allArticlesCache.isLoading && hasNextPage && _currentTabIndex == discoverTabIndex) {

      final nextPosition = scrollController.position.pixels + _doRefreshOffsetPixels;
      final bottomPosition = scrollController.position.maxScrollExtent;

      if (bottomPosition >= 0.0 && nextPosition >= bottomPosition) {
        _allArticlesCache.refresh();
      }
    }
  }

  /// Agrega los [Article] de [newResults] al final de [existing] y retorna 
  /// [existing]. Si [existing] o [newResults] son **null**, este método
  /// solo retorna [newResults] sin modificar ninguna de las colecciones.
  List<Article>? _aggregateResults(List<Article>? existing, List<Article>? newResults) {
    if (existing != null && newResults != null) {
      // Agregar recursos informativos obtenidos del último fetch a la API
      // a la colección de todos los recursos cargados.
      existing.addAll(newResults);
      return existing;
    }

    return newResults;
  }

  /// Notifica a los listeners de este provider si hay resultados nuevos en
  /// [fetchedArticles] (no es null y isNotEmpty == true) y este provider está 
  /// "montado". 
  /// 
  /// Si no hay resultados o el provider no está activo, este método retorna de
  /// inmediato.
  void _handleOnArticlesLoaded(List<Article>? fetchedArticles) {

    final shouldNotify = _isMounted && fetchedArticles != null 
                      && fetchedArticles.isNotEmpty;
    
    // Si no es apropiado notificar a los listeners con los nuevos resultados,
    // retornar de inmediato.
    if (!shouldNotify) return;

    notifyListeners();

    final isNotFirstPage = _latestArticleResults!.currentPage > 1;

    if (isNotFirstPage && _currentTabIndex == discoverTabIndex) {
      // Si no son los primeros resultados y el Tab activo es el de descubrir 
      // recursos, animar la posición del scroll hacia abajo.
      final double posToAnimate = scrollController.position.pixels + 50.0;

      scrollController.animateTo(
        posToAnimate, 
        duration: const Duration( milliseconds: 250 ), 
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    _isMounted = false;
    _scrollController.dispose();
  }
}