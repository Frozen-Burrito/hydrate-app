import 'dart:convert';

bool isTokenExpired(String token) {

  final claims = parseJWT(token);

  final int expDateMillis = claims['exp'] * 1000;

  return DateTime.fromMillisecondsSinceEpoch(expDateMillis).isBefore(DateTime.now());
}

Map<String, dynamic> parseJWT(String token) {

  final parts = token.split('.');

  if (parts.length != 3) {
    throw ArgumentError.value(token, 'token', 'El token debe tener tres partes.');
  }

  final claims = _decodeBase64(parts[1]);
  final claimMap = json.decode(claims);

  if (claimMap is! Map<String, dynamic>) {
    throw ArgumentError('Los claims en el token no son validos.');
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