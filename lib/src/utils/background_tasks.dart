import 'package:hydrate_app/src/models/map_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:workmanager/workmanager.dart";

import 'package:hydrate_app/src/models/activity_record.dart';
import 'package:hydrate_app/src/models/api.dart';
import "package:hydrate_app/src/db/sqlite_db.dart";
import "package:hydrate_app/src/db/where_clause.dart";
import "package:hydrate_app/src/models/hydration_record.dart";

/// Contiene los datos de las tareas ejecutadas en segundo plano por la app, 
/// además del callback que las invoca por su nombre.
/// 
/// La ejecución de tareas en segundo plano está basada en [Workmanager] y 
/// esta clase debería ser usada con el mismo.
class BackgroundTasks {

  /// El nombre único para la task de aportación a datos abiertos.
  static const String sendStatsDataTaskName = "com.hydrate.hydrateApp.taskAportarDatos";

  static const String taskInputProfileId = "profileId";
  static const String taskInputAccountId = "userAccountId";

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
          //TODO: Mantener esto solo para probar, quitar en produccion.
          await API.get("https://servicio-web-hydrate.azurewebsites.net/api/v1/datos-abiertos/test");

          // Esta tarea necesita inputData para poder completarse con éxito.
          if (inputData == null) return false;

          // Obtener las credenciales del usuario desde los inputs para 
          // esta task.
          final profileId = inputData[taskInputProfileId];

          final prefs = await SharedPreferences.getInstance();
          final jwt = prefs.getString("jwt") ?? "";

          // Obtener los registros con los datos estadísticos.
          final hydrationData = await _fetchHydrationFromPastWeek(profileId);
          final activityData = await _fetchActivitiesFromPastWeek(profileId);

          // Enviar datos aportados por el usuario.
          bool result = await _sendStatisticalData(
            profileId, 
            jwt, 
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
  static Future<Iterable<HydrationRecord>> _fetchHydrationFromPastWeek<T>(int profileId) async {
    // Obtener los registros de hidratación locales.
    final queryResults = await SQLiteDB.instance.select<HydrationRecord>(
      HydrationRecord.fromMap, 
      HydrationRecord.tableName, 
      where: [ WhereClause("id_perfil", profileId.toString()), ],
      orderByColumn: "fecha",
      orderByAsc: false,
      limit: 50,
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
  static Future<Iterable<ActivityRecord>> _fetchActivitiesFromPastWeek<T>(int profileId) async {
    // Obtener los registros de hidratación locales.
    final queryResults = await SQLiteDB.instance.select<ActivityRecord>(
      ActivityRecord.fromMap, 
      ActivityRecord.tableName, 
      where: [ WhereClause("id_perfil", profileId.toString()), ],
      orderByColumn: "fecha",
      orderByAsc: false,
      limit: 50,
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
    int profileId,
    String jwt, 
    Iterable<HydrationRecord> hydrationData,
    Iterable<ActivityRecord> activityData
  ) async {

    const jsonMapOptions = MapOptions(
      useCamelCasePropNames: true,
      includeCompleteSubEntities: false,
      useIntBooleanValues: true,
    );

    final hydrRecordsAsMaps = hydrationData
      .map((hr) => hr.toMap(options: jsonMapOptions));

    final actRecordsAsMaps = activityData
      .map((ar) => ar.toMap(options: jsonMapOptions));

    // Enviar peticiones POST a API con los datos contribuidos.
    final sendHydrationRequest = API.post(
      "aportarDatos/hidr", 
      hydrRecordsAsMaps, 
      authorization: jwt,
      authType: ApiAuthType.bearerToken,
    );

    final sendActivitiesRequest = API.post(
      "aportarDatos/act", 
      actRecordsAsMaps, 
      authorization: jwt,
      authType: ApiAuthType.bearerToken,
    );

    // Esperar a completar todas las peticiones para aportar datos.
    final contributionResults = await Future.wait(
      [ sendHydrationRequest, sendActivitiesRequest], 
      eagerError: true
    );

    // Si cada respuesta tiene un código de status 200, la aportación fue exitosa.
    final wasDataSendSuccessful = contributionResults.every((response) => response.isOk);
    
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