import 'package:flutter/foundation.dart';
import 'package:hydrate_app/src/api/data_api.dart';
import 'package:hydrate_app/src/exceptions/api_exception.dart';
import "package:workmanager/workmanager.dart";

import 'package:hydrate_app/src/api/api_client.dart';
import "package:hydrate_app/src/db/sqlite_db.dart";
import "package:hydrate_app/src/db/where_clause.dart";
import 'package:hydrate_app/src/models/activity_record.dart';
import "package:hydrate_app/src/models/hydration_record.dart";
import 'package:hydrate_app/src/models/map_options.dart';
import 'package:hydrate_app/src/utils/jwt_parser.dart';

/// Contiene los datos de las tareas ejecutadas en segundo plano por la app, 
/// además del callback que las invoca por su nombre.
/// 
/// La ejecución de tareas en segundo plano está basada en [Workmanager] y 
/// esta clase debería ser usada con el mismo.
class BackgroundTasks {

  /// El nombre único para la task de aportación a datos abiertos.
  static const String sendStatsDataTaskName = "com.hydrate.hydrateApp.taskAportarDatos";

  static const String taskInputAuthToken = "authToken";

  static const int maxRecordsToSend = 50;

  /// Define los parámetros para la tarea de envío de aportaciones 
  /// a datos abiertos.
  /// 
  /// Necesita [NetworkType.unmetered] y que [Constraints.requiresBatteryNotLow]
  /// sea igual a [true]. 
  static final TaskInfo sendStatsData = TaskInfo(
    sendStatsDataTaskName.split(".").last, 
    sendStatsDataTaskName,
    // frequency: const Duration(days: 7),
    // initialDelay: const Duration(days: 7),
    frequency: const Duration(hours: 1),
    initialDelay: const Duration(hours: 1),
    constraints: Constraints(
      networkType: NetworkType.unmetered,
      requiresBatteryNotLow: true
    ),
  );

  /// Maneja los callbacks invocados por [Workmanager], para 
  /// realizar tareas en segundo plano.
  static void callbackDispatcher() {
    // Ejecutar una tarea con Workmanager.
    Workmanager().executeTask((taskName, inputData) async {
      
      switch(taskName) {
        // Intentar enviar datos de hidratacion y actividad fisica a 
        // API de datos abiertos.
        case sendStatsDataTaskName:
          // Esta tarea necesita inputData para poder completarse con éxito.
          if (inputData == null) return false;

          // Obtener las credenciales del usuario desde los inputs para 
          // esta task.
          final authToken = inputData[taskInputAuthToken];
          final profileId = getProfileIdFromJwt(authToken);

          // Obtener los registros con los datos estadísticos.
          final hydrationData = await _retrieveHydrationFromPastWeek(profileId);
          final activityData = await _retrieveActivitiesFromPastWeek(profileId);

          // Enviar datos aportados por el usuario.
          bool result = await _sendStatisticalData(
            authToken, 
            hydrationData, 
            activityData
          );

          return result;
        default: 
          // Esta función recibió un nombre de task que no reconoce, avisar que
          // no puede completar esta task.
          print("Advertencia, nombre de tarea no identificado: $taskName");
          return Future.value(false);
      }
    });
  }

  /// Obtiene los [HydrationRecord] de la semana anterior, ordenados con los más
  /// recientes primero.
  static Future<Iterable<HydrationRecord>> _retrieveHydrationFromPastWeek<T>(int profileId) async {
    // Obtener los registros de hidratación locales.
    final queryResults = await SQLiteDB.instance.select<HydrationRecord>(
      HydrationRecord.fromMap, 
      HydrationRecord.tableName, 
      where: [ WhereClause(HydrationRecord.profileIdFieldName, profileId.toString()), ],
      orderByColumn: HydrationRecord.dateFieldName,
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
  static Future<Iterable<ActivityRecord>> _retrieveActivitiesFromPastWeek<T>(int profileId) async {
    // Obtener los registros de hidratación locales.
    final queryResults = await SQLiteDB.instance.select<ActivityRecord>(
      ActivityRecord.fromMap, 
      ActivityRecord.tableName, 
      where: [ WhereClause(ActivityRecord.profileIdPropName, profileId.toString()), ],
      orderByColumn: ActivityRecord.datePropName,
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

  /// Envía datos de hidratación y actividad física a la API de datos abiertos.
  /// 
  /// Para aportar datos, es necesario incluir el ID del perfil y de la cuenta 
  /// de usuario, además de [Iterable]s con los registros específicos. 
  /// 
  /// Retorna [true] si los datos fueron enviados con éxito.
  static Future<bool> _sendStatisticalData (
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
      final sendHydrationRequest = DataApi.instance.contributeOpenData<HydrationRecord>(
        data: hydrationData,
        mapper: (hydrationRecord, mapOptions) => hydrationRecord.toMap(options: mapOptions),
      );

      final sendActivitiesRequest = DataApi.instance.contributeOpenData<ActivityRecord>(
        data: activityData,
        mapper: (activityRecord, mapOptions) => activityRecord.toMap(options: mapOptions),
      );

      // Esperar a completar todas las peticiones para aportar datos.
      await Future.wait(
        [ sendHydrationRequest, sendActivitiesRequest], 
        eagerError: true
      );

      wasDataSendSuccessful = true;

    } on ApiException catch(ex) {
      wasDataSendSuccessful = false;
      debugPrint("Exception while contributing open data ($ex)");
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