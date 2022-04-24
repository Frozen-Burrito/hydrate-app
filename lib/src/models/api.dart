import 'dart:convert';

import 'package:http/http.dart' as http;

class API {

  static const String baseUrl = 'https://servicio-web-hydrate.azurewebsites.net';

  static final Uri baseUri = Uri.parse(baseUrl);

  static const String apiUrl = '$baseUrl/api/v1';

  static const String contentTypeHeader = 'content-type';

  static const String acceptJson = 'application/json';

  static final Map<String, Uri> uriMap = {
    'guias': Uri.parse('$baseUrl/guias'),
    'guias-conexion': Uri.parse('$baseUrl/guias/conexion'),
    'guias-formularios': Uri.parse('$baseUrl/guias/recoleccion-datos'),
    'comentarios': Uri.parse('$baseUrl/comentarios'),
  };

  static const defaultHeaders = {
    contentTypeHeader: acceptJson
  };

  static Uri uriFor(String resource) {

    final uri = uriMap[resource];

    return uri ?? baseUri;
  }

  static Future<http.Response> get(String url) {

    final parsedUrl = Uri.parse(apiUrl + url);

    return http.get(parsedUrl, headers: defaultHeaders);
  }

  static Future<http.Response> post(String url, Map<String, dynamic> body) {

    final parsedUrl = Uri.parse(apiUrl + url);

    final jsonBody = json.encode(body);

    return http.post(parsedUrl, body: jsonBody, headers: defaultHeaders);
  }

  static Future<http.Response> put(String url, Map<String, dynamic> body) {

    final parsedUrl = Uri.parse(apiUrl + url);

    return http.put(parsedUrl, body: body, headers: defaultHeaders);
  }

  static Future<http.Response> delete(String url, String resourceId) {
    
    final parsedUrl = Uri.parse(apiUrl + url + '/$resourceId');

    return http.delete(parsedUrl, headers: defaultHeaders);
  }
}