import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:workmanager/workmanager.dart";

import 'package:hydrate_app/src/api/data_api.dart';
import 'package:hydrate_app/src/api/api_client.dart';
import "package:hydrate_app/src/db/sqlite_db.dart";
import "package:hydrate_app/src/db/where_clause.dart";
import 'package:hydrate_app/src/exceptions/api_exception.dart';
import 'package:hydrate_app/src/models/activity_record.dart';
import "package:hydrate_app/src/models/hydration_record.dart";
import 'package:hydrate_app/src/utils/jwt_parser.dart';

/// Maneja los callbacks invocados por [Workmanager], para 
/// realizar tareas en segundo plano.
@pragma('vm:entry-point')
void callbackDispatcher() {
  // Ejecutar una tarea con Workmanager.
  Workmanager().executeTask((taskName, inputData) async {
    try {
      switch(taskName) {
        // Intentar enviar datos de hidratacion y actividad fisica a 
        // API de datos abiertos.
        case BackgroundTasks.contributeHydrationTaskName:
          return BackgroundTasks.contributeHydrationTaskInfo.task(inputData);
        case BackgroundTasks.contributeActivityTaskName:
          return BackgroundTasks.contributeActivityTaskInfo.task(inputData);
        default: 
          // Esta función recibió un nombre de task que no reconoce, avisar que
          // no puede completar esta task.
          final String msg = "Advertencia, nombre de tarea no identificado: $taskName";
          debugPrint(msg);
          return Future.error(msg);
      }
    } catch (ex) {
      debugPrint("Exception while executing background task ($ex)");
      rethrow;
    }
  });
}

/// Contiene los datos de las tareas ejecutadas en segundo plano por la app, 
/// además del callback que las invoca por su nombre.
/// 
/// La ejecución de tareas en segundo plano está basada en [Workmanager] y 
/// esta clase debería ser usada con el mismo.
class BackgroundTasks {

  const BackgroundTasks._();

  /// El nombre único para la task de aportación a datos abiertos.
  static const String contributeHydrationUniqueTaskName = "com.hydrate.hydrateApp.taskAportarHidratacion";
  static const String contributeHydrationTaskName = "taskAportarHidratacion";
  static const String contributeActivityUniqueTaskName = "com.hydrate.hydrateApp.taskAportarActividad";
  static const String contributeActivityTaskName = "taskAportarActividad";

  static const String taskInputAuthToken = "authToken";

  static const String lastHydrationContributionDateKey = "lastHydrContrib";
  static const String lastActivityContributionDateKey = "lastActContrib";

  static const int maxRecordsToSend = 50;

  static const BackgroundTasks instance = BackgroundTasks._();

  Future<void> enableDataContribution(String authToken) async {

    await cancelOpenDataContributions();

    final workmanager = Workmanager();

    await workmanager.registerPeriodicTask(
      contributeHydrationTaskInfo.uniqueName,
      contributeHydrationTaskInfo.taskName,
      frequency: contributeHydrationTaskInfo.frequency,
      initialDelay: contributeHydrationTaskInfo.initialDelay,
      constraints: contributeHydrationTaskInfo.constraints,
      inputData: <String, dynamic>{
        BackgroundTasks.taskInputAuthToken: authToken,
      },
    );

    await workmanager.registerPeriodicTask(
      contributeActivityTaskInfo.uniqueName,
      contributeActivityTaskInfo.taskName,
      frequency: contributeActivityTaskInfo.frequency,
      initialDelay: contributeActivityTaskInfo.initialDelay,
      constraints: contributeActivityTaskInfo.constraints,
      inputData: <String, dynamic>{
        BackgroundTasks.taskInputAuthToken: authToken,
      },
    );

    debugPrint("Enabled 2 periodic contributions to open data.");
  }

  Future<void> cancelOpenDataContributions() async {
    final workmanager = Workmanager();
    
    await workmanager.cancelByUniqueName(contributeHydrationUniqueTaskName);
    await workmanager.cancelByUniqueName(contributeActivityUniqueTaskName);

    debugPrint("Cancelled 2 periodic contributions to open data.");
  }

  /// Define los parámetros para la tarea de envío de aportaciones 
  /// a datos abiertos.
  /// 
  /// Necesita [NetworkType.unmetered] y que [Constraints.requiresBatteryNotLow]
  /// sea igual a [true]. 
  static final TaskInfo contributeHydrationTaskInfo = TaskInfo(
    contributeHydrationTaskName, 
    contributeHydrationUniqueTaskName,
    BackgroundTasks.instance._contributeHydrationData,
    // frequency: const Duration(days: 7),
    // initialDelay: const Duration(days: 7),
    frequency: const Duration(minutes: 15),
    initialDelay: Duration.zero,
    constraints: Constraints(
      networkType: NetworkType.unmetered,
      requiresBatteryNotLow: true
    ),
  );

  static final TaskInfo contributeActivityTaskInfo = TaskInfo(
    contributeActivityTaskName, 
    contributeActivityUniqueTaskName,
    BackgroundTasks.instance._contributeActivityData,
    // frequency: const Duration(days: 7),
    // initialDelay: const Duration(days: 7),
    frequency: const Duration(minutes: 15),
    initialDelay: Duration.zero,
    constraints: Constraints(
      networkType: NetworkType.unmetered,
      requiresBatteryNotLow: true
    ),
  );

  Future<bool> _contributeHydrationData(Map<String, dynamic>? inputData) async {
    // Esta tarea necesita inputData para poder completarse con éxito.
    final bool noTokenInInputData = inputData == null || 
        !inputData.containsKey(BackgroundTasks.taskInputAuthToken);

    if (noTokenInInputData) return false;

    // Obtener las credenciales del usuario desde los inputs para 
    // esta task.
    final authToken = inputData[BackgroundTasks.taskInputAuthToken];
    final profileId = getProfileIdFromJwt(authToken);

    debugPrint("Token: $authToken, id del perfil: $profileId");

    final sharedPreferences = await SharedPreferences.getInstance();
    final lastContributionDateStr = sharedPreferences.getString(lastHydrationContributionDateKey) ?? "";
    final lastContributionDate = DateTime.tryParse(lastContributionDateStr);

    // Obtener los registros con los datos estadísticos.
    final hydrationData = await _getHydrationForDateRange(profileId, from: lastContributionDate);

    if (hydrationData.isEmpty) return true;

    debugPrint("About to contribute ${hydrationData.length} hydration records to open data.");

    bool wasContributionSuccessful = false;

    // Enviar datos aportados por el usuario.
    try {
      DataApi.instance.authenticateClient(authToken: authToken, authType: ApiAuthType.bearerToken);

      await DataApi.instance.contributeOpenData<HydrationRecord>(
        data: hydrationData,
        mapper: (hydrationRecord, _) => hydrationRecord.toJson(),
      );

      sharedPreferences.setString(lastHydrationContributionDateKey, DateTime.now().toIso8601String());

      wasContributionSuccessful = true;

    } on ApiException catch(ex) {
      debugPrint("Exception while contributing open data ($ex)");
      wasContributionSuccessful = false;
    } on SocketException catch(ex) {
      debugPrint("Socket exception, check internet connection (${ex.message})");
      wasContributionSuccessful = false;
    }

    return wasContributionSuccessful;
  }

  Future<bool> _contributeActivityData(Map<String, dynamic>? inputData) async {

    final bool noTokenInInputData = inputData == null || 
        !inputData.containsKey(BackgroundTasks.taskInputAuthToken);

    if (noTokenInInputData) {
      return false;
    }

    // Obtener las credenciales del usuario desde los inputs para 
    // esta task.
    final authToken = inputData[BackgroundTasks.taskInputAuthToken];
    final profileId = getProfileIdFromJwt(authToken);

    debugPrint("Token: $authToken, id del perfil: $profileId");

    final sharedPreferences = await SharedPreferences.getInstance();
    final lastContributionDateStr = sharedPreferences.getString(lastActivityContributionDateKey) ?? "";
    final lastContributionDate = DateTime.tryParse(lastContributionDateStr);

    final activityData = await _getActivitiesForDateRange(profileId, from: lastContributionDate);

    if (activityData.isEmpty) return true;

    debugPrint("About to contribute ${activityData.length} activity records to open data.");

    try {
      DataApi.instance.authenticateClient(authToken: authToken, authType: ApiAuthType.bearerToken);

      await DataApi.instance.contributeOpenData<ActivityRecord>(
        data: activityData,
        mapper: (activityRecord, _) => activityRecord.toJson(),
      );

      sharedPreferences.setString(lastActivityContributionDateKey, DateTime.now().toIso8601String());

      return true;

    } on ApiException catch(ex) {
      debugPrint("Exception while contributing open data ($ex)");
    } on SocketException catch(ex) {
      debugPrint("Socket exception, check internet connection (${ex.message})");
    }

    return false;
  }

  /// Obtiene los [HydrationRecord] de la semana anterior, ordenados con los más
  /// recientes primero.
  Future<Iterable<HydrationRecord>> _getHydrationForDateRange<T>(
    int profileId, {
      DateTime? from,
      DateTime? to
  }) async 
  {
    // Obtener los registros de hidratación locales.
    final queryResults = await SQLiteDB.instance.select<HydrationRecord>(
      HydrationRecord.fromMap, 
      HydrationRecord.tableName, 
      where: [ WhereClause(HydrationRecord.profileIdAttribute, profileId.toString()), ],
      orderByColumn: HydrationRecord.dateAttribute,
      orderByAsc: false,
      limit: maxRecordsToSend,
    );

    // Asignar valores por default a rango de fechas, en caso que sea necesario.
    to ??= DateTime.now();
    from ??= DateTime.now().subtract(const Duration( days: 7 ));

    // Filtrar registros por rango de fechas.
    final recordsInDateRange = queryResults
      .where((hr) => hr.date.isAfter(from!) && hr.date.isBefore(to!));

    return recordsInDateRange;
  }

    /// Obtiene los [ActivityRecord] de la semana anterior, ordenados con los más
  /// recientes primero.
  Future<Iterable<ActivityRecord>> _getActivitiesForDateRange<T>(
    int profileId,{
      DateTime? from,
      DateTime? to
  }) async 
  {
    // Obtener los registros de hidratación locales.
    final queryResults = await SQLiteDB.instance.select<ActivityRecord>(
      ActivityRecord.fromMap, 
      ActivityRecord.tableName, 
      where: [WhereClause(ActivityRecord.profileIdPropName, profileId.toString()),],
      orderByColumn: ActivityRecord.datePropName,
      orderByAsc: false,
      limit: maxRecordsToSend,
      includeOneToMany: true
    );

    // Asignar valores por default a rango de fechas, en caso que sea necesario.
    to ??= DateTime.now();
    from ??= DateTime.now().subtract(const Duration( days: 7 ));

    // Filtrar registros por rango de fechas.
    final recordsInDateRange = queryResults
      .where((hr) => hr.date.isAfter(from!) && hr.date.isBefore(to!));

    return recordsInDateRange;
  }
}

/// Almacena la información de una tarea que puede ser ejecutada 
/// por [Workmanager], ya sea de una sola vez o periódica.
class TaskInfo {

  const TaskInfo(
    this.taskName, 
    this.uniqueName,
    this.task, {
      this.frequency,
      this.initialDelay = Duration.zero,
      this.constraints,
    }
  );

  final String taskName;
  final String uniqueName;

  final Duration? frequency;
  final Duration initialDelay;

  final Constraints? constraints;

  final Future<bool> Function(Map<String, dynamic>? inputData) task;
}