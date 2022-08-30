import 'dart:convert';

bool isTokenExpired(String token) {

  final claims = parseJWT(token);

  final int expDateMillis = claims['exp'] * 1000;

  return DateTime.fromMillisecondsSinceEpoch(expDateMillis).isBefore(DateTime.now());
}

/// Obtiene todos los claims encontrados en el payload de [token]. El [token]
/// debe ser un JWT.
/// 
/// Este método lanza una [FormatException] cuando:
/// - El [token] no tiene tres partes, separadas por puntos.
/// - Los claims no pueden ser de-serializados de JSON como un [Map].
/// - Los claims no incluyen a "id" o a "exp", que son obligatorios.
Map<String, dynamic> parseJWT(String token) {

  final parts = token.split('.');

  if (parts.length != 3) {
    throw FormatException("A JWT must contain three parts, separated by dots", token);
  }

  final claims = _decodeBase64(parts[1]);
  final claimMap = json.decode(claims);

  if (claimMap is! Map<String, dynamic>) {
    throw FormatException("The auth token could not provide any claims", claimMap);
  }

  if (!claimMap.containsKey("id") || !claimMap.containsKey("exp")) {
    throw FormatException("The auth token does not contain the required claims", claimMap);
  }

  return claimMap;
}

String _decodeBase64(String str) {
  String result = str.replaceAll('-', '+').replaceAll('_', '/');

  switch (result.length % 4) {
    case 0:
      break;
    case 2:
      result += '==';
      break;
    case 3:
      result += '=';
      break;
    default:
      throw ArgumentError.value(str, 'str', 'Url base 64 no valido.');
  }

  return utf8.decode(base64Url.decode(result));
}