
enum ApiErrorType {
  /// La causa del error es desconocida (este valor debe ser usado lo menos posible).
  unknown,
  /// No fue posible establecer una conexión con el host.
  unreachableHost,
  /// El servicio web no está funcionando correctamente.
  serviceUnavailable,
  /// La petición no fue formada correctamente (esto es probablemente un error 
  /// de implementación y no una condición externa).
  requestError,
  /// La URL es incorrecta.
  unknownResource,
}

/// Es usada por el cliente HTTP de la API web para identificar posibles
/// errores. La mayoría de elementos que usen la API deberían manejar los 
/// posibles [ApiErrorType] de esta excepción.
class ApiException implements Exception {

  /// Una descripción del error.
  final String message;

  /// La clasificación de esta excepción.
  final ApiErrorType type;

  const ApiException(this.type, [this.message = ""]);

  @override
  String toString() => "ApiException: (${type.name}) $message";
}