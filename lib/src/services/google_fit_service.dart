import 'dart:async';
import 'dart:math';

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

  //TODO: obtener la fecha de la sincronizacion mas reciente de FitnessData, para
  // solo obtener los datos a partir de esa fecha.
  DateTime? _tempStartTime;

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
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // serverClientId: "845399101862-05j142vf3o72u5pbfod1er178dgcde9e.apps.googleusercontent.com",
    scopes: scopes,
  );

  static const String _bearerTokenType = "Bearer";

  static const String _currentUserId = "me";

  static const String _caloriesBurnedDataTypeName = "com.google.calories.expended";

  static const String _mergeCaloriesExpDataStreamId = "derived:com.google.calories.expended:com.google.android.gms:merge_calories_expended";
  static const String _userInputCaloriesExpDataStreamId = "raw:com.google.calories.expended:com.google.android.apps.fitness:user_input";

  static const String _sessionListFields = "session.id,session.name,session.startTimeMillis,session.endTimeMillis,session.activityType,session.activeTimeMillis,session.modifiedTimeMillis";

  static const int _caloriesDataPointsLimitPerResponse = 50;

  set hydrateProfileId(int profileId) => _hydrateProfileId = profileId;

  Future<bool> signInWithGoogle() async {

    _currentUser = await _googleSignIn.signInSilently();

    // Si no fue posible iniciar sesión "silenciosamente", comenzar el proceso
    // interactivo de Google Sign In.
    if (_currentUser == null) {
      try {
        _currentUser = await _googleSignIn.signIn();
      } on PlatformException catch (error) {
        debugPrint("Error al iniciar sesion con Google ($error)");
      }
    }

    debugPrint("Attempted to sign into Google account: $_currentUser");

    return (_currentUser != null);
  }

  Future<bool> disableDataCollection() async {
    // _currentUser = await _googleSignIn.disconnect();

    debugPrint("Signed out of Google account: $_currentUser");

    return (_currentUser == null);
  }

  Future<int> addHydrationData(List<HydrationRecord> hydrationRecords) async {
    return 0;
  }

  Future<int> syncActivitySessions() async {

    _currentUser = await _googleSignIn.signInSilently();

    // Si no fue posible iniciar sesión "silenciosamente", comenzar el proceso
    // interactivo de Google Sign In.
    if (_currentUser == null) {
      try {
        _currentUser = await _googleSignIn.signIn();
      } on PlatformException catch (error) {
        debugPrint("Error al iniciar sesion con Google ($error)");
      }
    }

    if (_currentUser == null || _fitnessApi == null) {
      debugPrint("No user or API instance from which to sync Sessions data");
      return 0;
    }

    final startTime = _tempStartTime;
    final endTime = DateTime.now();

    final listSessionResponse = await _fitnessApi?.users.sessions.list(
      _currentUserId,
      startTime: startTime?.toRfc3999String(),
      endTime: endTime.toRfc3999String(),
      activityType: _supportedFitnessApiActTypes,
      includeDeleted: false,
      $fields: _sessionListFields,
    );

    final sessionData = listSessionResponse?.session ?? const <Session>[];

    debugPrint("Total sessions recovered: ${sessionData.length}");

    final activityTypes = await _queryActivityTypes();

    final activityRecords = <ActivityRecord>[];

    for (final session in sessionData) {
      debugPrint("Session data: $session");

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
        activityType: activityTypes.singleWhere(
          (actType) => actType.googleFitActivityType == session.activityType,
          orElse: () => ActivityType.uncommited()
        ),
        //TODO: usar profileID real.
        profileId: _hydrateProfileId,
      );

      activityRecords.add(sessionActivityRecord);
    }

    activityRecords.sort((a, b) => a.date.compareTo(b.date));

    debugPrint("Total activity records created: ${activityRecords.length}");

    // Si se obtuvieron registros de actividad, obtener más datos específicos 
    // para cada registro de actividad (kCal).
    if (activityRecords.isNotEmpty) {
      final startTime = activityRecords.first.date;
      final endTime = activityRecords.last.date;

      final caloriesExpendedDataset = await _fitnessApi?.users.dataSources.datasets.get(
        _currentUserId, 
        _mergeCaloriesExpDataStreamId, 
        _buildDataSetId(startTime, endTime),
        limit: _caloriesDataPointsLimitPerResponse,
      );

      final caloriesExpDataPoints = caloriesExpendedDataset?.point ?? const <DataPoint>[];

      if (caloriesExpDataPoints.isNotEmpty) {
        for (int i = 0; i < activityRecords.length; ++i) {
          // Obtener las kcal quemadas durante cada una de las actividades.
          final int nsStartTime = activityRecords[i].date.nanosecondsSinceEpoch;
          final int nsEndTime = nsStartTime + activityRecords[i].durationInNanoseconds;

          final caloriesDataPointsDuringActivity = caloriesExpDataPoints.where(
            (dataPoint) => _isDataPointInTimeRange(dataPoint, nsStartTime, nsEndTime)
          );

          debugPrint("Found ${caloriesDataPointsDuringActivity.length} calories expended data points that match the Activity Record");

          for (final dataPoint in caloriesDataPointsDuringActivity) {

            final dataPointValue = dataPoint.value ?? const <Value>[];
            if (dataPointValue.isNotEmpty) {
              // Agregar el valor del dataPoint al total de calorias quemadas
              // durante la actividad.
              activityRecords[i].kiloCaloriesBurned += dataPointValue.first.fpVal?.round() ?? 0;
            }
          }

          debugPrint("Total kCal for activity: ${activityRecords[i].kiloCaloriesBurned}");
        }
      }
    }

    //TODO: persistir los activity record obtenidos.
    activityRecords.sublist(0, min(5, activityRecords.length)).forEach(print);

    // Actualizar la fecha de la sincronizacion mas reciente. 
    //TODO: persistir este valor de alguna forma.
    _tempStartTime = endTime;

    return activityRecords.length;
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
      _hydrateProfileId = UserProfile.defaultProfileId;
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

  bool _isGoogleFitActivityDoneOutdoors(int googleFitActivityType) {

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

  String _buildDataSetId(DateTime startTime, DateTime endTime) {
    final dataSetIdStrBuf = StringBuffer();

    dataSetIdStrBuf.write(startTime.microsecondsSinceEpoch * 1000);
    dataSetIdStrBuf.write("-");
    dataSetIdStrBuf.write(endTime.microsecondsSinceEpoch * 1000);

    return dataSetIdStrBuf.toString();
  }

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