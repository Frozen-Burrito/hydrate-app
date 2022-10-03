import 'dart:convert';

import 'package:http/http.dart' as http;

/// Sirve como intermediario con una API web, permitiendo acceder a sus
/// recursos y realizar operaciones con verbos GET, POST, PUT y DELETE sobre
/// ellos.
/// TODO: Refactorizar la interfaz de esta clase, no tiene buena abstracción.
class API {

  /// La URL base del servicio web, como un [String].
  static const String baseUrl = 'https://servicio-web-hydrate.azurewebsites.net';

  /// La URL del servicio web, como una instancia de [Uri].
  static final Uri baseUri = Uri.parse(baseUrl);

  static const String apiUrl = '$baseUrl/api/v1';

  static const String authorizationHeader = 'Authorization';
  static const String contentTypeHeader = 'content-type';

  static const String acceptJson = 'application/json';
  static const String bearerToken = 'Bearer ';

  /// Asocia nombres de rutas del servicio web con sus URIs específicas, 
  /// que llevan a cada recurso si se realiza una petición a ellas.
  static final Map<String, Uri> uriMap = {
    'aportarDatos/hidr': Uri.parse('$apiUrl/datos-abiertos/hidratacion'),
    'aportarDatos/act': Uri.parse('$apiUrl/datos-abiertos/act-fisica'),
    'guias': Uri.parse('$baseUrl/guias'),
    'guias-conexion': Uri.parse('$baseUrl/guias/conexion'),
    'guias-formularios': Uri.parse('$baseUrl/guias/recoleccion-datos'),
    'comentarios': Uri.parse('$baseUrl/comentarios'),
    'login': Uri.parse('$baseUrl/usuarios/login'),
    'signUp': Uri.parse('$baseUrl/usuarios/registro'), 
  };

  /// Un conjunto de encabezados base para todas las peticiones a la 
  /// API.
  static const defaultHeaders = {
    contentTypeHeader: acceptJson
  };

  /// Transforma el nombre de un recurso en la [Uri] asociada a él.
  /// 
  /// Si el [resourceName] no coincide con ninguna [Uri] registrada en 
  /// [API.uriMap], este método retorna [API.baseUri].
  static Uri uriFor(String resourceName) {

    final uri = uriMap[resourceName];

    return uri ?? baseUri;
  }

  /// Envía una petición GET al [endpoint] especificado.
  /// 
  /// Agrega [endpoint] al final de [API.apiUrl], para luego hacer
  /// la petición a ese recurso usando [API.defaultHeaders].  
  static Future<http.Response> get(String endpoint) {

    final parsedUrl = Uri.parse(apiUrl + endpoint);

    return http.get(parsedUrl, headers: defaultHeaders);
  }

  /// Envía una petición POST al [endpoint] especificado. Serializa el [body] a 
  /// JSON y lo incluye como el cuerpo de la petición
  /// 
  /// Agrega el [endpoint] al final de [API.apiUrl], para luego hacer
  /// la petición a ese recurso usando [API.defaultHeaders]. 
  /// 
  /// Si [authorization] no está vacío y [authType] no es nulo, incluye el 
  /// header [API.authorizationHeader] en la petición, usando el valor de 
  /// [authorization] como credenciales.
  static Future<http.Response> post(
    String endpoint, 
    dynamic body,
    { String authorization = '', ApiAuthType? authType }
  ) {
    final parsedUrl = uriFor(endpoint);

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
  /// Envía la petición con [API.defaultHeaders].
  static Future<http.Response> put(String endpoint, Map<String, Object?> body) {

    final parsedUrl = Uri.parse(apiUrl + endpoint);

    return http.put(parsedUrl, body: body, headers: defaultHeaders);
  }
   
  /// Envía una petición DELETE al [endpoint] especificado. Incluye [resourceId]
  /// en el path de la petición (directamente en la URL, no como un parámetro).
  /// 
  /// Envía la petición con [API.defaultHeaders] por defecto.
  static Future<http.Response> delete(String endpoint, String resourceId) {
    
    final parsedUrl = Uri.parse(apiUrl + endpoint + '/$resourceId');

    return http.delete(parsedUrl, headers: defaultHeaders);
  }
}

extension HttpResponseExtensions on http.Response {

  /// Retorna [true] si esta respuesta tiene un código de estatus __HTTP
  /// 200__ (OK, Creado, NoContent, etc.).
  bool get isOk => statusCode >= 200 && statusCode < 300; 
}

enum ApiAuthType {
  bearerToken,
  paramsApiKey,
  pathApiKey,
}