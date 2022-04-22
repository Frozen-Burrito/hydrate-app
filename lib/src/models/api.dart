import 'dart:convert';

import 'package:http/http.dart' as http;

class API {

  static const String baseUrl = 'https://servicio-web-hydrate.azurewebsites.net/api/v1';

  static const String contentTypeHeader = 'content-type';

  static const String acceptJson = 'application/json';

  static const defaultHeaders = {
    contentTypeHeader: acceptJson
  };

  static Future<http.Response> get(String url) {

    final parsedUrl = Uri.parse(baseUrl + url);

    return http.get(parsedUrl, headers: defaultHeaders);
  }

  static Future<http.Response> post(String url, Map<String, Object?> body) {

    final parsedUrl = Uri.parse(baseUrl + url);

    final jsonBody = json.encode(body);

    return http.post(parsedUrl, body: jsonBody, headers: defaultHeaders);
  }

  static Future<http.Response> put(String url, Map<String, Object?> body) {

    final parsedUrl = Uri.parse(baseUrl + url);

    return http.put(parsedUrl, body: body, headers: defaultHeaders);
  }

  static Future<http.Response> delete(String url, String resourceId) {
    
    final parsedUrl = Uri.parse(baseUrl + url + '/$resourceId');

    return http.delete(parsedUrl, headers: defaultHeaders);
  }
}