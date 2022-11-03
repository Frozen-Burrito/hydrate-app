
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';

import 'package:hydrate_app/src/api/api_client.dart';
import 'package:hydrate_app/src/exceptions/api_exception.dart';
import 'package:hydrate_app/src/models/map_options.dart';
import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/models/user_credentials.dart';
import 'package:hydrate_app/src/utils/jwt_parser.dart';

class AuthApi {

  // La instancia de cliente HTTP usada para realizar todas las 
  // peticiones a la API de autenticación.
  final _apiClient = ApiClient();

  bool _isClientClosed = false;

  static const String _signInWithEmailEndpoint = "login";
  static const String _createAccountWithEmailEndpoint = "signUp";
  static const String _profileEndpoint = "perfil";

  bool get isClosed => _isClientClosed;
  
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
          throw ApiException(
            ApiErrorType.serviceUnavailable,
            httpStatusCode: response.statusCode,
            message: "No auth token in response"
          );
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
        ApiException.connectionError(ApiErrorType.unreachableHost, ex.message)
      );

    } on SocketException catch (ex) {
      // El dispositivo no tiene conexión a internet y no puede descubrir
      // el host de la API web, o la API web no está disponible.
      throw ApiException.connectionError(ApiErrorType.unreachableHost, ex.message);
    } on FormatException catch (ex) {
      // FormatException solo es producida cuando el JWT no puede ser 
      // interpretado o sus claims no tienen la forma correcta.
      throw ApiException.connectionError(ApiErrorType.responseFormatError, ex.message);
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
          throw ApiException(
            ApiErrorType.serviceUnavailable,
            httpStatusCode: response.statusCode,
            message: "No auth token in response"
          );
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
        ApiException.connectionError(ApiErrorType.unreachableHost, ex.message)
      );

    } on SocketException catch (ex) {
      // El dispositivo no tiene conexión a internet y no puede descubrir
      // el host de la API web, o la API web no está disponible.
      throw ApiException.connectionError(ApiErrorType.unreachableHost, ex.message);
    } on FormatException catch (ex) {
      // FormatException solo es producida cuando el JWT no puede ser 
      // interpretado o sus claims no tienen la forma correcta.
      throw ApiException.connectionError(ApiErrorType.responseFormatError, ex.message);
    }
  }

  /// Obtiene el perfil del usuario autenticado desde la API.
  /// 
  /// Si [authToken] no tiene un formato válido, ocurre un error al enviar
  /// la petición o la respuesta no es la esperada, este método lanza un 
  /// [ApiException].
  Future<UserProfile> fetchProfileForAccount(
    String authToken, {
      List<Country> allCountries = const <Country>[],
      List<Environment> allEnvironments = const <Environment>[],
    }
  ) async {
    try {
      
      final int currentProfileId = getProfileIdFromJwt(authToken);

      // Obtener el perfil del usuario autenticado por authToken. 
      final response = await _apiClient.get(
        _profileEndpoint,
        pathParameters: <String> [ currentProfileId.toString() ], 
        authorization: authToken,
        authType: ApiAuthType.bearerToken,
      );

      final isResponseOk = response.statusCode == HttpStatus.ok;
      final responseHasBody = response.body.isNotEmpty;

      if (isResponseOk && responseHasBody) {
        // De-serializar el perfil de usuario desde el cuerpo de la respuesta.
        final Map<String, Object?> profileJsonData = json.decode(response.body);
        
        final profile = UserProfile.fromMap(
          profileJsonData, 
          options: ApiClient.defaultJsonMapOptions,
          existingCountries: allCountries,
          allEnvironments: allEnvironments,
        );

        return profile;

      } else {
        // Usar el manejador por defecto de errores en respuesta.
        return Future.error(_apiClient.defaultErrorResponseHandler(response));
      }
    } on ClientException catch (ex) {
      // Probablmente, la conexión a internet fue interrumpida, haciendo 
      // que la petición no pudiera ser completada.
      return Future.error(
        ApiException(
          ApiErrorType.unreachableHost, 
          httpStatusCode: 0,
          message: ex.message,
        ),
      );

    } on SocketException catch (ex) {
      // El dispositivo no tiene conexión a internet y no puede descubrir
      // el host de la API web, o la API web no está disponible.
      throw ApiException(
        ApiErrorType.unreachableHost, 
          httpStatusCode: 0,
          message: ex.message,
      );
    } on FormatException catch (ex) {
      // FormatException solo es producida cuando el JWT no puede ser 
      // interpretado o sus claims no tienen la forma correcta.
      throw ApiException(
        ApiErrorType.responseFormatError, 
        httpStatusCode: 0,
        message: ex.message,
      );
    } 
  }

  Future<void> updateProfileWithChanges(String authToken, UserProfile profileChanges) async {

    final int profileId = getProfileIdFromJwt(authToken);

    final Map<String, Object?> requestBody = profileChanges.toMap(options: const MapOptions(
      useCamelCasePropNames: true,
      subEntityMappingType: EntityMappingType.idOnly,
      useIntBooleanValues: false,
    ));
    
    final response = await _apiClient.patch(
      _profileEndpoint, 
      requestBody,
      authorization: authToken,
      authType: ApiAuthType.bearerToken,
      pathParameters: <String> [ profileId.toString(), ],
    );

    if (response.statusCode != HttpStatus.noContent) {

      if (response.statusCode == HttpStatus.internalServerError) 
      {
        throw ApiException(
          ApiErrorType.serviceUnavailable,
          httpStatusCode: response.statusCode
        );
      }

      return Future.error(_apiClient.defaultErrorResponseHandler(response));
    }
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
    _isClientClosed = true;
  }
}