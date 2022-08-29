import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:hydrate_app/src/exceptions/api_exception.dart';

/// Sirve como intermediario con una API web, permitiendo acceder a sus
/// recursos y realizar operaciones con verbos GET, POST, PUT y DELETE sobre
/// ellos.
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
    { Map<String, String> queryParameters = const {} }
  ) {

    final parsedUrl = uriForResource(resource, queryParameters);

    if (parsedUrl != null && parsedUrl.isScheme("HTTPS")) {
      // Enviar la petición a la URL especificada.
      return client.get(parsedUrl, headers: defaultHeaders);
    } else {
      return Future.error(const FormatException("requested url could not be parsed"));
    }
  }

  /// Envía una petición POST al [resource] especificado. Serializa el [body] a 
  /// JSON y lo incluye como el cuerpo de la petición
  /// 
  /// Obtiene la URI completa de [resource] invocando a [uriForResource]. Si
  /// la URI completa no es válida o no usa el esquema HTTPS, lanza un 
  /// [FormatException]. 
  /// 
  /// Si [authorization] no está vacío y [authType] es [ApiAuthType.bearerToken],
  /// incluye el header [ApiClient.authorizationHeader] en la petición,
  /// usando el valor de [authorization] como el token de autorización.
  Future<http.Response> post(
    String resource, 
    dynamic body, { 
      String authorization = '', 
      Map<String, String> queryParameters = const {},
      ApiAuthType authType = ApiAuthType.anonymous,
    }
  ) {

    final parsedUrl = uriForResource(resource, queryParameters);

    final isUrlValid = parsedUrl != null && parsedUrl.isScheme("HTTPS");

    if (isUrlValid) {
      // Serializar el cuerpo a JSON y configurar los headers, incluyendo 
      // los de autenticación.
      final jsonBody = json.encode(body);

      final reqHeaders = Map<String, String>.from(defaultHeaders);

      final requiredAuthHeader = authorization.isNotEmpty && 
                                 authType == ApiAuthType.bearerToken;

      if (requiredAuthHeader) {
        // Si recibe opciones de autenticación, incluirlas en la petición.
        final authCredential = authType == ApiAuthType.bearerToken 
          ? bearerToken + authorization
          : authorization;

        reqHeaders[authorizationHeader] = authCredential;
      }

      // Enviar la petición a la URL especificada, usando el cliente HTTP.
      return client.post(
        parsedUrl!, 
        body: jsonBody, 
        headers: reqHeaders
      );
    } else {
      return Future.error(
        const FormatException("requested url could not be parsed")
      );
    }
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

  Future<void> defaultErrorResponseHandler(http.Response response) {
    if (response.statusCode >= HttpStatus.internalServerError) {
      // La respuesta indica un problema del servidor. No debería seguir 
      // haciendo peticiones.
      throw const ApiException(
        ApiErrorType.serviceUnavailable, 
        "Service is not available"
      );

    } else if (response.statusCode >= HttpStatus.badRequest) {
      // Por alguna razón, la petición tenía una forma incorrecta. 
      throw const ApiException(
        ApiErrorType.requestError,
        "Articles could not be requested",
      );
    } else {
      // Algo más salió mal.
      throw ApiException(
        ApiErrorType.unknown,
        "Unexpected HTTP status code in response: ${response.statusCode}"
      );
    }
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
  anonymous,
  bearerToken,
  paramsApiKey,
  pathApiKey,
}