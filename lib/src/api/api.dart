import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Sirve como intermediario con una API web, permitiendo acceder a sus
/// recursos y realizar operaciones con verbos GET, POST, PUT y DELETE sobre
/// ellos.
/// TODO: Refactorizar la interfaz de esta clase, no tiene buena abstracción.
class ApiClient {

  final client = http.Client();  

  // La URL base del servicio web.
  static const String _baseUrl = 'https://servicio-web-hydrate.azurewebsites.net';
  static const String _apiUrl = '$_baseUrl/api/v1';

  static final _baseUri = Uri.parse(_baseUrl);

  static const String authorizationHeader = 'Authorization';
  static const String contentTypeHeader = 'content-type';

  static const String acceptJson = 'application/json';
  static const String bearerToken = 'Bearer ';

  static const String notValidUrl = "::Not valid URI::";

  /// Asocia nombres de rutas del servicio web con sus URIs específicas, 
  /// que llevan a cada recurso si se realiza una petición a ellas.
  static final Map<String, Uri> webPageMap = {
    'guias': Uri.parse('$_baseUrl/guias'),
    'guias-conexion': Uri.parse('$_baseUrl/guias/conexion'),
    'guias-formularios': Uri.parse('$_baseUrl/guias/recoleccion-datos'),
    'comentarios': Uri.parse('$_baseUrl/comentarios'),
  };

  static final Map<String, String> _apiMap = {
    'aportarDatos/hidr': '$_apiUrl/datos-abiertos/hidratacion',
    'aportarDatos/act': '$_apiUrl/datos-abiertos/act-fisica',
    'login': '$_apiUrl/usuarios/login',
    'signUp': '$_apiUrl/usuarios/registro', 
    'recursos': '$_apiUrl/recursos',
  };

  /// Un conjunto de encabezados base para todas las peticiones a la 
  /// API.
  static const defaultHeaders = {
    contentTypeHeader: acceptJson
  };

  /// Transforma el nombre de una página web en la [Uri] asociada a él.
  /// 
  /// Si el [resourceName] no coincide con ninguna [Uri] registrada en 
  /// [ApiClient.uriMap], este método retorna [ApiClient.baseUri].
  static Uri urlForPage(String pageName) {

    final uri = webPageMap[pageName];

    return uri ?? _baseUri;
  }

  /// Transforma el nombre de un recurso de API en la [Uri] asociada a él.
  /// 
  /// Si el [resourceName] no coincide con ninguna [Uri] registrada, este 
  /// método retorna la URL base de la API.
  static Uri? uriForResource(
    String resourceName, 
    Map<String, String> queryParameters
  ) {

    String uri = _apiMap[resourceName] ?? notValidUrl;

    if (uri != notValidUrl && queryParameters.isNotEmpty) {
      final strBuf = StringBuffer("?");

      for (final parameter in queryParameters.entries) {
        strBuf.writeAll([ parameter.key, "=", parameter.value ]);

        if (parameter != queryParameters.entries.last) {
          strBuf.write("&");
        }
      }

      uri = uri + strBuf.toString();
    }

    return Uri.tryParse(uri);
  }

  /// Envía una petición GET al [endpoint] especificado.
  /// 
  /// Agrega [endpoint] al final de [ApiClient.apiUrl], para luego hacer
  /// la petición a ese recurso usando [ApiClient.defaultHeaders].  
  Future<http.Response> get(
    String resource, 
    { Map<String, String>? queryParameters
  }) {

    final parsedUrl = uriForResource(resource, queryParameters ?? {});

    if (parsedUrl != null && parsedUrl.isScheme("HTTPS")) {
      // Enviar la petición a la URL especificada.
      return client.get(parsedUrl, headers: defaultHeaders);
    } else {
      return Future.error(const FormatException("requested url could not be parsed"));
    }
  }

  /// Envía una petición POST al [endpoint] especificado. Serializa el [body] a 
  /// JSON y lo incluye como el cuerpo de la petición
  /// 
  /// Agrega el [endpoint] al final de [ApiClient.apiUrl], para luego hacer
  /// la petición a ese recurso usando [ApiClient.defaultHeaders]. 
  /// 
  /// Si [authorization] no está vacío y [authType] no es nulo, incluye el 
  /// header [ApiClient.authorizationHeader] en la petición, usando el valor de 
  /// [authorization] como credenciales.
  static Future<http.Response> post(
    String endpoint, 
    dynamic body,
    { String authorization = '', ApiAuthType? authType }
  ) {
    final parsedUrl = Uri.parse(_apiUrl + endpoint);

    final jsonBody = json.encode(body);

    final reqHeaders = Map<String, String>.from(defaultHeaders);

    if (authorization.isNotEmpty && authType != null) {
      // Si recibe opciones de autenticación, incluirlas en la petición.
      final authCredential = authType == ApiAuthType.bearerToken 
        ? bearerToken + authorization
        : authorization;

      reqHeaders[authorizationHeader] = authCredential;
    }

    return http.post(parsedUrl, body: jsonBody, headers: reqHeaders);
  }

  /// Envía una petición PUT al [endpoint] especificado. Serializa [body] 
  /// a JSON y lo incluye como el cuerpo de la petición.
  /// 
  /// Envía la petición con [ApiClient.defaultHeaders].
  static Future<http.Response> put(String endpoint, Map<String, Object?> body) {

    final parsedUrl = Uri.parse(_apiUrl + endpoint);

    return http.put(parsedUrl, body: body, headers: defaultHeaders);
  }
   
  /// Envía una petición DELETE al [endpoint] especificado. Incluye [resourceId]
  /// en el path de la petición (directamente en la URL, no como un parámetro).
  /// 
  /// Envía la petición con [ApiClient.defaultHeaders] por defecto.
  static Future<http.Response> delete(String endpoint, String resourceId) {
    
    final parsedUrl = Uri.parse(_apiUrl + endpoint + '/$resourceId');

    return http.delete(parsedUrl, headers: defaultHeaders);
  }

  void close() {
    client.close();
  }
}

extension HttpResponseExtensions on http.Response {

  /// Retorna [true] si esta respuesta tiene un código de estatus __HTTP
  /// 200__ (OK, Creado, NoContent, etc.).
  bool get isOk => statusCode >= HttpStatus.ok && statusCode < HttpStatus.permanentRedirect; 
}

enum ApiAuthType {
  bearerToken,
  paramsApiKey,
  pathApiKey,
}