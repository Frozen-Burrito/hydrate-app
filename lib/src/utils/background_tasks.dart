import 'dart:io';

import 'package:flutter/foundation.dart';
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
        case BackgroundTasks.sendOpenStatsTaskName:
          // Esta tarea necesita inputData para poder completarse con éxito.
          if (inputData == null) return false;

          // Obtener las credenciales del usuario desde los inputs para 
          // esta task.
          final authToken = inputData[BackgroundTasks.taskInputAuthToken];
          final profileId = getProfileIdFromJwt(authToken);

          debugPrint("Token: $authToken, id del perfil: $profileId");

          // Obtener los registros con los datos estadísticos.
          final hydrationData = await BackgroundTasks.retrieveHydrationFromPastWeek(profileId);
          final activityData = await BackgroundTasks.retrieveActivitiesFromPastWeek(profileId);

          debugPrint("About to contribute ${hydrationData.length} hydration records and ${activityData.length} activity records to open data.");

          // Enviar datos aportados por el usuario.
          final bool result = await BackgroundTasks.sendStatisticalData(
            authToken, 
            hydrationData, 
            activityData
          );

          return result;
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

  /// El nombre único para la task de aportación a datos abiertos.
  static const String sendOpenStatsUniqueTaskName = "com.hydrate.hydrateApp.taskAportarDatos";
  static const String sendOpenStatsTaskName = "taskAportarDatos";

  static const String taskInputAuthToken = "authToken";

  static const int maxRecordsToSend = 50;

  /// Define los parámetros para la tarea de envío de aportaciones 
  /// a datos abiertos.
  /// 
  /// Necesita [NetworkType.unmetered] y que [Constraints.requiresBatteryNotLow]
  /// sea igual a [true]. 
  static final TaskInfo sendStatsData = TaskInfo(
    sendOpenStatsTaskName, 
    sendOpenStatsUniqueTaskName,
    // frequency: const Duration(days: 7),
    // initialDelay: const Duration(days: 7),
    frequency: const Duration(hours: 1),
    initialDelay: const Duration(hours: 1),
    constraints: Constraints(
      networkType: NetworkType.unmetered,
      requiresBatteryNotLow: true
    ),
  );

  /// Obtiene los [HydrationRecord] de la semana anterior, ordenados con los más
  /// recientes primero.
  static Future<Iterable<HydrationRecord>> retrieveHydrationFromPastWeek<T>(int profileId) async {
    // Obtener los registros de hidratación locales.
    final queryResults = await SQLiteDB.instance.select<HydrationRecord>(
      HydrationRecord.fromMap, 
      HydrationRecord.tableName, 
      where: [ WhereClause(HydrationRecord.profileIdAttribute, profileId.toString()), ],
      orderByColumn: HydrationRecord.dateAttribute,
      orderByAsc: false,
      limit: maxRecordsToSend,
    );

    // Definir rango de fechas como la última semana.
    final now = DateTime.now();
    final aWeekAgo = now.subtract(const Duration( days: 7 ));

    // Filtrar registros por rango de fechas.
    final recordsInDateRange = queryResults
      .where((hr) => hr.date.isAfter(aWeekAgo) && hr.date.isBefore(now));

    return recordsInDateRange;
  }

    /// Obtiene los [ActivityRecord] de la semana anterior, ordenados con los más
  /// recientes primero.
  static Future<Iterable<ActivityRecord>> retrieveActivitiesFromPastWeek<T>(int profileId) async {
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

    // Definir rango de fechas como la última semana.
    final now = DateTime.now();
    final aWeekAgo = now.subtract(const Duration( days: 7 ));

    // Filtrar registros por rango de fechas.
    final recordsInDateRange = queryResults
      .where((hr) => hr.date.isAfter(aWeekAgo) && hr.date.isBefore(now));

    return recordsInDateRange;
  }

  /// Envía datos de hidratación y actividad física a la API de datos abiertos.
  /// 
  /// Para aportar datos, es necesario incluir el ID del perfil y de la cuenta 
  /// de usuario, además de [Iterable]s con los registros específicos. 
  /// 
  /// Retorna [true] si los datos fueron enviados con éxito.
  static Future<bool> sendStatisticalData (
    String authToken, 
    Iterable<HydrationRecord> hydrationData,
    Iterable<ActivityRecord> activityData
  ) async {
    // Enviar peticiones POST a API con los datos contribuidos.
    DataApi.instance.authenticateClient(authToken: authToken, authType: ApiAuthType.bearerToken);

    // Si ambas peticiones resultan en respuestas 204 y no producen un 
    // ApiException, los datos fueron enviados con éxito.
    bool wasDataSendSuccessful;
    
    try {
      final Future<void> sendHydrationRequest;

      if (hydrationData.isNotEmpty) {
        sendHydrationRequest = DataApi.instance.contributeOpenData<HydrationRecord>(
          data: hydrationData,
          mapper: (hydrationRecord, _) => hydrationRecord.toJson(),
        ); 
      } else {
        sendHydrationRequest = Future.value();
      }

      final Future<void> sendActivitiesRequest;

      if (activityData.isNotEmpty) {
        sendActivitiesRequest = DataApi.instance.contributeOpenData<ActivityRecord>(
          data: activityData,
          mapper: (activityRecord, _) => activityRecord.toJson(),
        );
      } else {
        sendActivitiesRequest = Future.value();
      }

      // Esperar a completar todas las peticiones para aportar datos.
      await Future.wait(
        [ sendHydrationRequest, sendActivitiesRequest ], 
        eagerError: true
      );

      wasDataSendSuccessful = true;

    } on ApiException catch(ex) {
      wasDataSendSuccessful = false;
      debugPrint("Exception while contributing open data ($ex)");
    } on SocketException catch(ex) {
      wasDataSendSuccessful = false;
      debugPrint("Socket exception, check internet connection (${ex.message})");
    }
    
    return wasDataSendSuccessful;
  }
}

/// Almacena la información de una tarea que puede ser ejecutada 
/// por [Workmanager], ya sea de una sola vez o periódica.
class TaskInfo {

  const TaskInfo(
    this.taskName, 
    this.uniqueName, {
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
}