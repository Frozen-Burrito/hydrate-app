import 'package:hydrate_app/src/api/api.dart';
import 'package:hydrate_app/src/models/settings.dart';
import 'package:hydrate_app/src/utils/jwt_parser.dart';

class ConfigApi {

  static final ConfigApi instance = ConfigApi._internal();

  static const String fetchConfigResource = "fetch-config";
  static const String syncConfigResource = "sync-config";
  static const String syncFcmTokenResource = "sync-fcm-token";

  static final _apiClient = ApiClient();

  ConfigApi._internal();

  Future<Settings> fetchSettings(String authToken) async {

    final int profileId = getProfileIdFromJwt(authToken);

    final response = await _apiClient.get(
      fetchConfigResource,
      authorization: authToken,
      authType: ApiAuthType.bearerToken,
      pathParameters: <String> [ profileId.toString(), ],
    );

    final responseHasBody = response.body.isNotEmpty;

    if (response.isOk && responseHasBody) {

      final settings = Settings.fromJson(response.body);

      return settings;

    } else {
      return Future.error(_apiClient.defaultErrorResponseHandler(response));
    }
  }

  Future<void> updateSettings(String authToken, Settings modifiedSettings) async {

    final int profileId = getProfileIdFromJwt(authToken);

    final requestBody = modifiedSettings.toJson();
    
    final response = await _apiClient.patch(
      syncConfigResource, 
      requestBody,
      authorization: authToken,
      authType: ApiAuthType.bearerToken,
      pathParameters: <String> [ profileId.toString(), ],
    );

    if (!response.isOk) {
      return Future.error(_apiClient.defaultErrorResponseHandler(response));
    }
  }

  Future<void> refreshFcmToken(String authToken, String fcmRegistrationToken) async {

    final int profileId = getProfileIdFromJwt(authToken);

    final Map<String, Object?> requestBody = <String, Object?>{
      "token": fcmRegistrationToken,
      "timestamp": DateTime.now().toIso8601String(),
    };
    
    final response = await _apiClient.put(
      syncFcmTokenResource, 
      requestBody,
      authorization: authToken,
      authType: ApiAuthType.bearerToken,
      pathParameters: <String> [ profileId.toString(), ],
    );

    if (!response.isOk) {
      return Future.error(_apiClient.defaultErrorResponseHandler(response));
    }
  }
}