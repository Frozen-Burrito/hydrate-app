import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

import 'package:hydrate_app/src/api/api_client.dart';
import 'package:hydrate_app/src/api/paged_result.dart';
import 'package:hydrate_app/src/api/pagination_parameters.dart';
import 'package:hydrate_app/src/exceptions/api_exception.dart';
import 'package:hydrate_app/src/models/activity_record.dart';
import 'package:hydrate_app/src/models/goal.dart';
import 'package:hydrate_app/src/models/hydration_record.dart';
import 'package:hydrate_app/src/models/map_options.dart';
import 'package:hydrate_app/src/models/routine.dart';
import 'package:hydrate_app/src/utils/jwt_parser.dart';

enum DataSyncAction {
  fetch,
  updated,
  deleted,
}

class DataApi {

  static final DataApi instance = DataApi._internal();

  static const String hydrationRecordsResourceName = "hidratacion";
  static const String goalsResourceName = "metas";
  static const String singleGoalResourceName = "metas/id";
  static const String activityRecordsResourceName = "actividadFisica";
  static const String routinesResourceName = "rutinas";

  static const String openDataHydrationResourceName = "aportarDatos/hidratacion";
  static const String openDataActivityResourceName = "aportarDatos/actividad";

  static const _defaultPaginationParams = PaginationParameters(
    pageIndex: ApiClient.defaultPageIndex,
    resultsPerPage: ApiClient.defaultResultsPerPage,
    query: "",
  );

  final _apiClient = ApiClient();

  static String _authToken = "";
  static ApiAuthType _authenticationType = ApiAuthType.anonymous;

  DataApi._internal();

  bool get isAuthenticated => _authenticationType != ApiAuthType.anonymous &&
    _authToken.isNotEmpty;

  void authenticateClient({required String authToken, required ApiAuthType authType}) {
    if (authToken.isNotEmpty && !isTokenExpired(authToken)) {
      _authToken = authToken;
      _authenticationType = authType;
    }
  }

  void clearClientAuthentication() {
    _authToken = "";
    _authenticationType = ApiAuthType.anonymous;
  }

  String? _resourceNameForData({ Object? data, bool isForOpenData = false }) {
    String? endpointForResource;

    if (data is Iterable<HydrationRecord>) {
      endpointForResource = isForOpenData 
        ? openDataHydrationResourceName
        : hydrationRecordsResourceName;

    } else if (data is Iterable<Goal>) {
      endpointForResource = goalsResourceName;

    } else if (data is Goal) {
      endpointForResource = singleGoalResourceName;

    } else if (data is Iterable<ActivityRecord>) {
      endpointForResource = isForOpenData
        ? openDataActivityResourceName
        : activityRecordsResourceName;

    } else if (data is Iterable<Routine>) {
      endpointForResource = routinesResourceName;
    }

    return endpointForResource;
  }

  Future<Iterable<T>> fetchData<T>({ 
    String? authToken, 
    required T Function(Map<String, Object?>) mapper, 
    PaginationParameters? paginationParameters, 
    DateTime? from,
    DateTime? to,
  }) async 
  {
    final Iterable<T> data = <T>[];

    paginationParameters ??= _defaultPaginationParams;

    final resourceName = _resourceNameForData( data: data, isForOpenData: false );

    if (resourceName == null) {
      throw ApiException(
        ApiErrorType.resourceNotFound,
        httpStatusCode: HttpStatus.notFound,
        message: "El recurso para los datos solicitados no es soportado",
        problemDetails: "El tipo de datos solicitados es $T",
      );
    }

    final queryParams = <String, String>{};

    queryParams.addAll(paginationParameters.toMap());

    if (from != null && from.isAfter(DateTime(2022, 1, 1))) {
      queryParams["desde"] = from.toIso8601String();
    }

    if (to != null && !(to.isAfter(DateTime.now()))) {
      queryParams["hasta"] = to.toIso8601String();
    }

    final response = await _apiClient.get(
      resourceName,
      queryParameters: queryParams,
      authType: _authenticationType,
      authorization: _authToken,
    );

    final responseHasBody = response.body.isNotEmpty;

    if (response.isOk && responseHasBody) {

      final PagedResult<T> pagedResult = PagedResult.fromJson(
        response.body, 
        mapper: mapper,
        mapOptions: ApiClient.defaultJsonMapOptions
      );

      return pagedResult.results;

    } else {
      throw ApiException(
        ApiErrorType.unknown,
        httpStatusCode: response.statusCode,
        message: "Error al intentar obtener datos del usuario",
        problemDetails: response.body,
      );
    }
  }

  Future<void> updateData<T>({ 
    required Iterable<T> data, 
    required Map<String, Object?> Function(T, MapOptions) mapper, 
    String? authToken 
  }) async 
  {
    final requestBody = data.map((record) => mapper(record, ApiClient.defaultJsonMapOptions))
      .toList();

    final resourceName = _resourceNameForData(data: data, isForOpenData: false);

    if (resourceName == null) {
      throw ApiException(
        ApiErrorType.resourceNotFound,
        httpStatusCode: HttpStatus.notFound,
        message: "El recurso para los datos solicitados no es soportado",
        problemDetails: "El tipo de datos solicitados es $T",
      );
    }
    
    final Response response = await _apiClient.put(
      resourceName, 
      requestBody,
      authorization: authToken ?? _authToken, 
      authType: _authenticationType,
    );

    if (response.statusCode != HttpStatus.noContent) {
      throw ApiException(
        ApiErrorType.requestError,
        httpStatusCode: response.statusCode,
        message: "Error al intentar sincronizar datos del usuario",
        problemDetails: response.body,
      );
    }
  }

  Future<void> deleteData<T>({ required T data, required String dataId, String? authToken, }) async {

    final resourceName = _resourceNameForData( data: data, isForOpenData: false);

    if (resourceName == null) {
      throw ApiException(
        ApiErrorType.resourceNotFound,
        httpStatusCode: HttpStatus.notFound,
        message: "El recurso para los datos solicitados no es soportado",
        problemDetails: "El tipo de datos solicitados es $T",
      );
    }

    final Response response = await _apiClient.delete(
      resourceName, 
      authorization: authToken ?? _authToken, 
      authType: _authenticationType,
      pathParameters: <String>[ dataId ],
    );

    if (response.statusCode != HttpStatus.noContent) {
      throw ApiException(
        ApiErrorType.requestError,
        httpStatusCode: response.statusCode,
        message: "Error al intentar eliminar un registro de datos",
        problemDetails: response.body,
      );
    }
  }

  Future<Set<String>> deleteCollection<T extends Iterable>({ required T data, required Set<String> ids, String? authToken }) async {

    final recordIdsSuccessfullyDeleted = <String>{};

    for (final id in ids) {
      try {
        await deleteData(data: data.first, dataId: id, authToken: authToken);
        recordIdsSuccessfullyDeleted.add(id);
      } on ApiException catch (ex) {
        debugPrint("Error al intentar eliminar un registro de datos ($ex)");
      }
    }

    return recordIdsSuccessfullyDeleted;
  }

  Future<void> contributeOpenData<T>({ 
    required Iterable<T> data,
    required Map<String, Object?> Function(T, MapOptions) mapper, 
    String? authToken,
  }) async 
  {
    final resourceName = _resourceNameForData( data: data, isForOpenData: true, );

    if (resourceName == null) {
      throw ApiException(
        ApiErrorType.resourceNotFound,
        httpStatusCode: HttpStatus.notFound,
        message: "El recurso para los datos solicitados no es soportado",
        problemDetails: "El tipo de datos solicitados es $T",
      );
    }

    final requestBody = data.map((record) => mapper(record, ApiClient.defaultJsonMapOptions))
      .toList();
    
    final Response response = await _apiClient.post(
      resourceName, 
      requestBody,
      authorization: authToken ?? _authToken, 
      authType: _authenticationType,
    );

    if (response.statusCode != HttpStatus.noContent) {
      throw ApiException(
        ApiErrorType.requestError,
        httpStatusCode: response.statusCode,
        message: "Error al intentar aportar datos estadísticos abiertos",
        problemDetails: response.body,
      );
    }
  }
}