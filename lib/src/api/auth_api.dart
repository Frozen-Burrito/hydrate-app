
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';

import 'package:hydrate_app/src/api/api.dart';
import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/db/where_clause.dart';
import 'package:hydrate_app/src/exceptions/api_exception.dart';
import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/models/user_credentials.dart';
import 'package:hydrate_app/src/utils/jwt_parser.dart';

class AuthApi {

  // La instancia de cliente HTTP usada para realizar todas las 
  // peticiones a la API de autenticación.
  static final _apiClient = ApiClient();

  static const String _signInWithEmailEndpoint = "login";
  static const String _createAccountWithEmailEndpoint = "signUp";
  
  /// Envía una petición de inicio de sesión con email y password. Si obtiene
  /// una respuesta exitosa, retorna el JWT de autenticación.
  /// 
  /// El usuario de este método es responsable de manejar adecuadamente las 
  /// siguientes situaciones que lanzan un [ApiException]:
  /// - La petición no puede ser completada, ya sea por mala conectividad o 
  /// porque el servicio no está disponible.
  /// - Ocurrió un error en el servicio web.
  /// - La respuesta es exitosa, pero no contiene un JWT válido.
  Future<String> signInWithEmail(UserCredentials authCredentials) async {
    // Enviar petición POST para iniciar sesión. 
    try {
      final response = await _apiClient.post(
        _signInWithEmailEndpoint, 
        authCredentials.toMap()
      );

      final isResponseOk = response.statusCode == HttpStatus.ok;
      final responseHasBody = response.body.isNotEmpty;

      if (isResponseOk && responseHasBody) {
        // Try to obtain the JWT from the response body.
        final String authToken = _decodeAuthToken(response);

        if (authToken.isEmpty) {
          throw const ApiException(ApiErrorType.serviceUnavailable);
        }

        // Asegurar que authToken puede ser descompuesto en claims. Si esta
        // función falla, lanza un FormatException.
        parseJWT(authToken);

        return authToken;
        
      } else {
        // Usar el manejador por defecto de errores en respuesta.
        return Future.error(_apiClient.defaultErrorResponseHandler(response));
      }

    } on ClientException catch (ex) {
      // Probablmente, la conexión a internet fue interrumpida, haciendo 
      // que la petición no pudiera ser completada.
      return Future.error(
        ApiException(ApiErrorType.unreachableHost, ex.message)
      );

    } on SocketException catch (ex) {
      // El dispositivo no tiene conexión a internet y no puede descubrir
      // el host de la API web, o la API web no está disponible.
      throw ApiException(ApiErrorType.unreachableHost, ex.message);
    } on FormatException catch (ex) {
      // FormatException solo es producida cuando el JWT no puede ser 
      // interpretado o sus claims no tienen la forma correcta.
      throw ApiException(ApiErrorType.responseFormatError, ex.message);
    }
  }

  /// Envía una petición para crear una nueva cuenta con email y password. 
  /// Si obtiene una respuesta exitosa, retorna el JWT de autenticación.
  /// 
  /// Si el token no puede ser obtenido por un problema de API, este 
  /// método lanza un [ApiException]. 
  Future<String> createAccountWithEmail(UserCredentials authCredentials) async {

    try {
      // Enviar petición POST para iniciar sesión. 
      final response = await _apiClient.post(
        _createAccountWithEmailEndpoint, 
        authCredentials.toMap()
      );

      final isResponseOk = response.statusCode == HttpStatus.ok;
      final responseHasBody = response.body.isNotEmpty;

      if (isResponseOk && responseHasBody) {
        // Intentar obtener el JWT desde el cuerpo JSON de response.
        final String authToken = _decodeAuthToken(response);

        if (authToken.isEmpty) {
          throw const ApiException(ApiErrorType.serviceUnavailable);
        }

        // Asegurar que authToken puede ser descompuesto en claims. Si esta
        // función falla, lanza un FormatException.
        parseJWT(authToken);

        return authToken;

      } else {
        // Usar el manejador por defecto de errores en respuesta.
        return Future.error(_apiClient.defaultErrorResponseHandler(response));
      }
    } on ClientException catch (ex) {
      // Probablmente, la conexión a internet fue interrumpida, haciendo 
      // que la petición no pudiera ser completada.
      return Future.error(
        ApiException(ApiErrorType.unreachableHost, ex.message)
      );

    } on SocketException catch (ex) {
      // El dispositivo no tiene conexión a internet y no puede descubrir
      // el host de la API web, o la API web no está disponible.
      throw ApiException(ApiErrorType.unreachableHost, ex.message);
    } on FormatException catch (ex) {
      // FormatException solo es producida cuando el JWT no puede ser 
      // interpretado o sus claims no tienen la forma correcta.
      throw ApiException(ApiErrorType.responseFormatError, ex.message);
    }
  }

  Future<UserProfile> fetchProfileForAccount(String userAccountId) async {
    //TODO: obtener el perfil de la cuenta desde la API, no desde la BD local.
    final whereQuery = [ WhereClause(UserProfile.userAccountIdFieldName, userAccountId), ];

    final queryResults = await SQLiteDB.instance.select<UserProfile>(
      UserProfile.fromMap,
      UserProfile.tableName,
      where: whereQuery,
      limit: 1
    );

    final profileForAccount = (queryResults.length == 1) 
        ? queryResults.single 
        : UserProfile.defaultProfile;

    return profileForAccount; 
  }

  /// Decodifica un JWT de autenticación desde el cuerpo JSON de [response].
  /// 
  /// Si [response] no contiene un JWT váliado, este método retorna un 
  /// String vacío.
  String _decodeAuthToken(Response response) {
    final decodedBody = json.decode(response.body);
    final tokenFromResponse = decodedBody[UserCredentials.jwtPropIdentifier];

    return (tokenFromResponse is String) ? tokenFromResponse : "";
  }

  /// Cierra el cliente HTTP usado por esta instancia.
  void dispose() {
    _apiClient.close();
  }
}