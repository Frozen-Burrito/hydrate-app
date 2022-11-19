import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/fitness/v1.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/models/activity_record.dart';
import 'package:hydrate_app/src/models/activity_type.dart';
import 'package:hydrate_app/src/models/hydration_record.dart';
import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/services/settings_service.dart';
import 'package:hydrate_app/src/utils/datetime_extensions.dart';
import 'package:hydrate_app/src/utils/google_fit_activity_type.dart';

class GoogleFitService {

  GoogleFitService._() {
    _userChangedSubscription = _googleSignIn.onCurrentUserChanged
        .listen(_handleCurrentUserChanged);
  }

  static final GoogleFitService instance = GoogleFitService._();

  int _hydrateProfileId = -1;

  GoogleSignInAccount? _currentUser;

  StreamSubscription<GoogleSignInAccount?>? _userChangedSubscription;

  FitnessApi? _fitnessApi;

  AuthClient? _underlyingAuthClient;

  String? _hydrationDataStreamId;

  bool _isSigningIn = false;

  final List<HydrationRecord> _hydrationRecordsPendingSync = <HydrationRecord>[];

  static final List<int> _supportedFitnessApiActTypes = [
    GoogleFitActivityType.unknown,
    GoogleFitActivityType.walking,
    GoogleFitActivityType.running,
    GoogleFitActivityType.biking,
    GoogleFitActivityType.swimming,
    GoogleFitActivityType.soccer,
    GoogleFitActivityType.basketball,
    GoogleFitActivityType.volleyball,
    GoogleFitActivityType.dancing,
    GoogleFitActivityType.yoga,
  ];

  static const List<String> scopes = <String>[
    FitnessApi.fitnessActivityReadScope,
    FitnessApi.fitnessBodyReadScope,
    FitnessApi.fitnessNutritionReadScope,
    FitnessApi.fitnessNutritionWriteScope,
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: scopes,
  );

  static const String _bearerTokenType = "Bearer";

  static const String _currentUserId = "me";

  static const String _hydrationDataTypeName = "com.google.hydration";
  
  static final DataType _hydrationDataType = DataType(
    name: _hydrationDataTypeName,
    field: <DataTypeField>[
      DataTypeField(
        name: "volume",
        format: "floatPoint",
        optional: false,
      )
    ]
  );

  static const String _hydrateHydrationDataSourceName = "HydrateAppHydration";

  static const String _mergeCaloriesExpDataStreamId = "derived:com.google.calories.expended:com.google.android.gms:merge_calories_expended";

  static const String _rawDataSourceType = "raw";

  static const String _dataStreamIdField = "dataStreamId";
  static const String _sessionListFields = "session.id,session.name,session.startTimeMillis,session.endTimeMillis,session.activityType,session.activeTimeMillis,session.modifiedTimeMillis";

  static const int _caloriesDataPointsLimitPerResponse = 50;
  static const int _hydrationRecordsPerWrite = 5;

  static const String onSyncHydrationRecordListenerName = "sync_hydration_to_fit";

  static final Application hydrateAppDetails = Application(
    name: "Hydrate",
    packageName: "com.ceti.fernando.hydrate",
    version: SettingsService.versionName,
    detailsUrl: "https://servicio-web-hydrate.azurewebsites.net/",
  );

  set hydrateProfileId(int profileId) => _hydrateProfileId = profileId;

  bool get isSignedInWithGoogle => _isGoogleUserSignedIn();

  bool get isSigningIn => _isSigningIn;

  String? get googleAccountDisplayName => _currentUser?.displayName;

  String get googleAccountInitials {

    final partsOfDisplayName = _currentUser?.displayName?.split(" ") ?? <String>[];

    if (partsOfDisplayName.isNotEmpty) {

      final String firstInitial = partsOfDisplayName.first.toUpperCase();
      final String lastInitial = partsOfDisplayName.length > 1 ? partsOfDisplayName[1].toUpperCase() : "";
      
      return firstInitial + lastInitial;
    }

    // El usuario no tiene un display name, retornar "A" (Anónimo).
    return "A";
  }

  String get googleAccountEmail => _currentUser?.email ?? "Cuenta de Google";

  String? get googleAccountPhotoUrl => _currentUser?.photoUrl;

  Future<bool> signInWithGoogle() async {

    if (!_isSigningIn) {
      _isSigningIn = true;

      try {
        _currentUser = await _googleSignIn.signInSilently();

        // Si no fue posible iniciar sesión "silenciosamente", comenzar el proceso
        // interactivo de Google Sign In.
        _currentUser ??= await _googleSignIn.signIn();

      } on PlatformException catch (error) {
        debugPrint("Error al iniciar sesion con Google ($error)");
      }

      _isSigningIn = false;
    }

    return (_currentUser != null);
  }

  Future<bool> signOut() async {
    try {
      _currentUser = await _googleSignIn.disconnect();
    } on PlatformException catch (error) {
      debugPrint("Error al iniciar sesion con Google ($error)");
    }

    debugPrint("Signed out of Google account: $_currentUser");

    return !(_isGoogleUserSignedIn());
  }

  void addHydrationRecordToSyncQueue(HydrationRecord hydrationRecord) {

    _hydrationRecordsPendingSync.add(hydrationRecord);

    if (_hydrationRecordsPendingSync.length >= _hydrationRecordsPerWrite) {
      addHydrationData(_hydrationRecordsPendingSync).then((numRecordsSync) {
        debugPrint("Added $numRecordsSync hydration record(s) to Google Fit");
        if (numRecordsSync == _hydrationRecordsPendingSync.length) {
          _hydrationRecordsPendingSync.clear();
        }
      });
    }
  }

  Future<int> addHydrationData(List<HydrationRecord> hydrationRecords) async {

    if (hydrationRecords.isEmpty) {
      debugPrint("List of hydration records to sync is empty");
      return 0;
    }

    if (!_hasAuthForGoogleFitApi()) {
      debugPrint("No user or API instance from which to sync Sessions data");
      return 0;
    }

    final dataSourcesResponse = await _fitnessApi?.users.dataSources.list(
      _currentUserId, 
      dataTypeName: <String>[ _hydrationDataType.name ?? _hydrationDataTypeName ],
      // $fields: _dataSourceStreamIdFieldAndName,
    );

    final hydrationDataSources = dataSourcesResponse?.dataSource
        ?.where((dataSource) => dataSource.dataStreamName == _hydrateHydrationDataSourceName && dataSource.type == _rawDataSourceType).toList() 
        ?? const <DataSource>[];

    // Revisar si es necesario crear un DataSource para la hidratacion, antes
    // de intentar agregar los datos de hidratacion.
    if (hydrationDataSources.isEmpty) {
      final newHydrationDataSource = DataSource(
        dataStreamName: _hydrateHydrationDataSourceName,
        application: hydrateAppDetails,
        type: _rawDataSourceType,
        dataType: _hydrationDataType,
      );

      try {
        final createdDataSource = await _fitnessApi?.users.dataSources.create(
          newHydrationDataSource, 
          _currentUserId,
          $fields: _dataStreamIdField,
        );

        _hydrationDataStreamId = createdDataSource?.dataStreamId;

      } on AccessDeniedException catch (ex) {
        debugPrint("La app no cuenta con permisos suficientes para crear el DataSource");
        debugPrint(ex.toString());
        return 0;
      }
      on ApiRequestError catch (error) {
        debugPrint("Error creating new DataSource for hydration data: $error");
        return 0;
      }
    } else {
      _hydrationDataStreamId = hydrationDataSources.last.dataStreamId;
    }

    if (_hydrationDataStreamId != null && _hydrationDataStreamId!.isNotEmpty) {

      final List<DataPoint> hydrationDataPoints = [];

      hydrationRecords.sort((a, b) => a.date.compareTo(b.date));

      final DateTime minStartTime = hydrationRecords.first.date;
      final DateTime maxEndTime = hydrationRecords.last.date; 

      for (final hydrationRecord in hydrationRecords) {

        final dataPoint = DataPoint(
          startTimeNanos: hydrationRecord.date.nanosecondsSinceEpoch.toString(),
          endTimeNanos: hydrationRecord.date.nanosecondsSinceEpoch.toString(),
          dataTypeName: _hydrationDataType.name,
          value: <Value>[
            Value(
              fpVal: hydrationRecord.volumeInLiters,
            ),
          ]
        );

        hydrationDataPoints.add(dataPoint);
      }

      final Dataset hydrationRecordsDataSet = Dataset(
        dataSourceId: _hydrationDataStreamId,
        minStartTimeNs: minStartTime.nanosecondsSinceEpoch.toString(),
        maxEndTimeNs: maxEndTime.nanosecondsSinceEpoch.toString(),
        point: hydrationDataPoints
      );

      //Invalid StartTimeNanos: com.google.hydration [1970-01-01T00:00:13Z - 1970-01-01T00:00:13Z] [0.074] raw:com.google.hydration:845399101862:HydrateAppHydration

      try {
        final newDataset = await _fitnessApi?.users.dataSources.datasets.patch(
          hydrationRecordsDataSet,
          _currentUserId,
          _hydrationDataStreamId!,
          _buildDataSetId(minStartTime, maxEndTime),
        );

        if (newDataset != null) {
          return newDataset.point?.length ?? 0;
        }

      } on ApiRequestError catch (error) {
        debugPrint("Error adding hydration data to Google Fit: $error");
      }
    }

    return 0;
  }

  /// Obtiene información de actividad física (sessions) del usuario en Google
  /// Fit, y las convierte en una colección de [ActivityRecord].
  Future<Iterable<ActivityRecord>> syncActivitySessions({ 
    DateTime? startTime, 
    DateTime? endTime,
    Map<int, ActivityType> supportedGoogleFitActTypes = const {},
  }) async {

    if (!_hasAuthForGoogleFitApi()) {
      debugPrint("No user or API instance from which to sync Sessions data");
      return const <ActivityRecord>[];
    }

    final sessionData = await _fetchSessionData(startTime, endTime);

    final List<ActivityRecord> activityRecords = sessionData.map((session) { 

      final activityType = supportedGoogleFitActTypes[session.activityType] 
        ?? ActivityType.uncommited(); 

      return GoogleFitActivityExtension.fromSession(session, activityType, _hydrateProfileId);
    }).toList();

    activityRecords.sort((a, b) => a.date.compareTo(b.date));

    // Si se obtuvieron registros de actividad, obtener más datos específicos 
    // para cada registro de actividad (kCal).
    if (activityRecords.isNotEmpty) {
      final startTime = activityRecords.first.date;
      final endTime = activityRecords.last.date;

      final caloriesExpDataPoints = await _fetchCaloriesBurnedInSessions(startTime, endTime);

      if (caloriesExpDataPoints.isNotEmpty) {
        for (final activityRecord in activityRecords) {
          _accumulateKcalForActivity(activityRecord, caloriesExpDataPoints);
        }
      }
    }

    return List.unmodifiable(activityRecords);
  }

  Future<List<DataPoint>> _fetchCaloriesBurnedInSessions(DateTime startTime, DateTime endTime) async {
    final caloriesExpendedDataset = await _fitnessApi?.users.dataSources.datasets.get(
      _currentUserId, 
      _mergeCaloriesExpDataStreamId, 
      _buildDataSetId(startTime, endTime),
      limit: _caloriesDataPointsLimitPerResponse,
    );

    return caloriesExpendedDataset?.point ?? const <DataPoint>[];
  }

  void _accumulateKcalForActivity(final ActivityRecord activityRecord, List<DataPoint> kcalData) {
    // Obtener las kcal quemadas durante cada una de las actividades.
    final int nsStartTime = activityRecord.date.nanosecondsSinceEpoch;
    final int nsEndTime = nsStartTime + activityRecord.durationInNanoseconds;

    final caloriesDataPointsDuringActivity = kcalData.where(
      (dataPoint) => _isDataPointInTimeRange(dataPoint, nsStartTime, nsEndTime)
    );

    debugPrint("Found ${caloriesDataPointsDuringActivity.length} calories expended data points that match the Activity Record");

    for (final dataPoint in caloriesDataPointsDuringActivity) {

      final dataPointValue = dataPoint.value ?? const <Value>[];
      if (dataPointValue.isNotEmpty) {
        // Agregar el valor del dataPoint al total de calorias quemadas
        // durante la actividad.
        activityRecord.kiloCaloriesBurned += dataPointValue.first.fpVal?.round() ?? 0;
      }
    }

    debugPrint("Total kCal for activity: ${activityRecord.kiloCaloriesBurned}");
  }

  Future<List<Session>> _fetchSessionData(DateTime? startTime, DateTime? endTime) async {

    startTime ??= DateTime.now().subtract( const Duration(days: 180) );
    endTime ??= DateTime.now();
    
    final listSessionResponse = await _fitnessApi?.users.sessions.list(
      _currentUserId,
      startTime: startTime.toRfc3999String(),
      endTime: endTime.toRfc3999String(),
      activityType: _supportedFitnessApiActTypes,
      includeDeleted: false,
      $fields: _sessionListFields,
    );

    final sessionData = listSessionResponse?.session ?? const <Session>[];

    return sessionData;
  }

  void dispose() {
    _userChangedSubscription?.cancel();
    _fitnessApi = null;
  }

  Future<void> _handleCurrentUserChanged(GoogleSignInAccount? newUser) async {

    debugPrint("Current Google user changed, newUser: $newUser");

    // Si no hay un usuario autenticado, "desactivar" la API de fitness.
    if (newUser == null) {
      _underlyingAuthClient = null;
      _fitnessApi = null;
      _hydrateProfileId = UserProfile.defaultProfile.id;
      return;
    }

    // Obtener un nuevo cliente HTTP autenticado con las credenciales 
    // del nuevo usuario actual.
    _underlyingAuthClient = await _getAuthenticatedClient();

    if (_underlyingAuthClient != null) {
      _fitnessApi = FitnessApi(_underlyingAuthClient!);
    }
  }

  Future<AuthClient?> _getAuthenticatedClient({
    // ignore: unused_element
    GoogleSignInAuthentication? debugAuthentication,
    List<String>? debugScopes
  }) async 
  {
    final GoogleSignInAuthentication? auth = await _currentUser?.authentication;

    final String? oAuthToken = auth?.accessToken;

    if (oAuthToken == null) {
      return null;
    }

    final AccessCredentials credentials = AccessCredentials(
      AccessToken(
        _bearerTokenType, 
        oAuthToken, 
        DateTime.now().toUtc().add(const Duration( days: 365 ))
      ),
      null,
      debugScopes ?? scopes,
    );

    return authenticatedClient(http.Client(), credentials);
  }

  //TODO: encontrar una forma de no repetir este metodo (ya existe en ActivityService).
  Future<List<ActivityType>> _queryActivityTypes() async {
    try {
      final queryResults = await SQLiteDB.instance.select<ActivityType>(
        ActivityType.fromMap, 
        ActivityType.tableName, 
      );
      
      return queryResults.toList();

    } on Exception catch (e) {
      return Future.error(e);
    }
  }

  String _buildDataSetId(DateTime startTime, DateTime endTime) {
    final dataSetIdStrBuf = StringBuffer();

    dataSetIdStrBuf.write(startTime.nanosecondsSinceEpoch * 1000);
    dataSetIdStrBuf.write("-");
    dataSetIdStrBuf.write(endTime.nanosecondsSinceEpoch * 1000);

    return dataSetIdStrBuf.toString();
  }

  bool _hasAuthForGoogleFitApi() => _isGoogleUserSignedIn() && _fitnessApi != null;

  bool _isGoogleUserSignedIn() => _currentUser != null;

  bool _isDataPointInTimeRange(DataPoint dataPoint, int startTimeNanos, int endTimeNanos) {

    final int? dataPointStartTimeNanos = int.tryParse(dataPoint.startTimeNanos ?? "");  
    final int? dataPointEndTimeNanos = int.tryParse(dataPoint.endTimeNanos ?? "");  

    if (dataPointStartTimeNanos == null || dataPointEndTimeNanos == null) {
      // El DataPoint no especifica un rango de fechas correcto. No es posible 
      // que se encuentre en el rango de fechas deseado.
      return false;
    }

    final isAfterStartTime = dataPointStartTimeNanos >= startTimeNanos;
    final isBeforeEndTime = dataPointEndTimeNanos <= endTimeNanos;

    return isAfterStartTime && isBeforeEndTime;
  }
}

extension GoogleFitActivityExtension on ActivityRecord {

  static ActivityRecord fromSession(Session session, ActivityType activityType, int profileId) {

    final int startMsSinceEpoch = int.tryParse(session.startTimeMillis ?? "0") ?? 0;
    final int endMsSinceEpoch = int.tryParse(session.endTimeMillis ?? "0") ?? 0;

    final DateTime activityDate = DateTime.fromMillisecondsSinceEpoch(startMsSinceEpoch); 
    final DateTime endDate = DateTime.fromMillisecondsSinceEpoch(endMsSinceEpoch); 
    final Duration activityDuration = endDate.difference(activityDate);

    final sessionActivityRecord = ActivityRecord(
      title: session.name ?? "Untitled Session Activity",
      date: activityDate,
      duration: activityDuration.inMinutes,
      doneOutdoors: _isGoogleFitActivityDoneOutdoors(session.activityType ?? GoogleFitActivityType.unknown),
      activityType: activityType,
      profileId: profileId,
    );

    return sessionActivityRecord;
  }

  static bool _isGoogleFitActivityDoneOutdoors(int googleFitActivityType) {

    final Map<int, bool> _googleFitActivitiesOutdoors = {
      GoogleFitActivityType.unknown: false,
      GoogleFitActivityType.walking: false,
      GoogleFitActivityType.running: true,
      GoogleFitActivityType.biking: true,
      GoogleFitActivityType.swimming: false,
      GoogleFitActivityType.soccer: true,
      GoogleFitActivityType.basketball: true,
      GoogleFitActivityType.volleyball: true,
      GoogleFitActivityType.dancing: false,
      GoogleFitActivityType.yoga: false,
    };

    return _googleFitActivitiesOutdoors[googleFitActivityType] ?? false;
  }
}
