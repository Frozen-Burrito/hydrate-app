import 'package:hydrate_app/src/api/api.dart';
import 'package:hydrate_app/src/api/paged_result.dart';
import 'package:hydrate_app/src/models/article.dart';
import 'package:hydrate_app/src/models/map_options.dart';

/// Sirve como un wrapper para hacer operaciones con la api de recursos 
/// informativos, usando un [ApiClient].
/// 
/// Por el momento, la única acción soportada es obtener recursos informativos
/// por páginas, usando [PagedResult].
class ArticlesApi {

  static const int defaultArticlesPerPage = 5;

  static final _apiClient = ApiClient();

  /// Hace una petición a la API de artículos y produce un [PagedResult] con los
  /// artículos solicitados.
  /// 
  /// [pageIndex] es el número de página de resultados que debería ser obtenido.
  /// Si es mayor que el número de páginas disponibles, este método retorna un
  /// resultado vacío. Debe ser mayor o igual a 0.
  /// 
  /// El usuario de este método es responsable de manejar adecuadamente las 
  /// siguientes situaciones:
  /// - La petición no puede ser completada, ya sea por mala conectividad o 
  /// error en su creación.
  /// - El servicio web no está disponible.
  /// - El resultado no es el esperado.
  Future<PagedResult<Article>> fetchArticles({
    int pageIndex = 0,
    int articlesPerPage = defaultArticlesPerPage
  }) async {

    assert(pageIndex >= 0, "pageIndex debe ser un número entero positivo, o 0");

    final Map<String, String> pageParams = {
      "pagina": pageIndex.toString(),
      "sizePagina": articlesPerPage.toString(),
    };

    // Enviar petición GET a la api de recursos informativos.
    final response = await _apiClient.get("recursos", queryParameters: pageParams);

    final responseHasBody = response.body.isNotEmpty;

    if (response.isOk && responseHasBody) {
      // La petición fue exitosa. Obtener recursos informativos del cuerpo de la 
      // respuesta.
      final pagedResult = PagedResult.fromJson(
        response.body, 
        mapper: (Map<String, Object?> source) {
          return Article.fromMap(source, options: const MapOptions(
            useCamelCasePropNames: true
          ));
        }
      );

      return pagedResult;

    } else {
      return Future.error(_apiClient.defaultErrorResponseHandler(response));
    }
  }

  /// Cierra el cliente HTTP usado para realizar peticiones a la API de 
  /// recursos informativos.
  void dispose() {
    _apiClient.close();
  }
} 