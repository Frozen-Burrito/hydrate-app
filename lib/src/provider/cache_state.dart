
/// Un contenedor genérico de datos que los actualiza solo cuando es necesario. 
/// Además, incluye información que permite conocer el estado de los datos.
/// 
/// Los datos son actualizados o "refrescados" cuando los datos actuales caducan, 
/// o se pide de forma explícita una actualización usando [shouldRefresh()]).
class CacheState<T> {

  /// Crea una nueva instancia de [CacheState], para un tipo [T] específico.
  /// 
  /// [fetchData()] es una función que se invoca de forma asíncrona para obtener 
  /// los datos actualizados y resulta en una instancia de [T].
  /// 
  /// Este constructor también acepta [isLoading], que es [true] cuando el cache 
  /// debe invocar [fetchData()] lo más pronto posible; [initialData], que son 
  /// datos iniciales (en este caso, el cache no se refresca al iniciar); 
  /// [onDataRefreshed()], una función callback que es invocada cuando se obtienen
  /// los datos de [fetchData()] sin un error; [maxDataAge], la duración máxima 
  /// de validez de los datos; y [error], un error inicial.
  CacheState({
    required Future<T> Function() fetchData,
    bool isLoading = false,
    T? initialData,
    void Function(T?)? onDataRefreshed,
    Duration? maxDataAge,
    Error? error,
  }) 
    : _data = initialData,
      _fetchData = fetchData,
      _alreadyLoading = isLoading,
      _shouldRefresh = initialData == null,
      _onDataRefreshed = onDataRefreshed,
      _lastFetchTimestamp = DateTime.now(),
      _maxAge = maxDataAge;

  /// Inicializa un nuevo [CacheState<T>] con un valor inicial específico.
  CacheState.value(T value, Future<T> Function() onFetchData) : this(
    fetchData: onFetchData,
    isLoading: false,
    initialData: value,
  );

  /// Inicializa un nuevo [CacheState<T>] con un error inicial, [data] es nulo.
  CacheState.error(Error error, Future<T> Function() onFetchData) : this(
    fetchData: onFetchData,
    isLoading: false,
    initialData: null,
    error: error,
  );

  // Los datos mantenidos.
  T? _data;
  // La duración máxima de los datos. Cuando se excede este valor, el CacheState
  // actualiza los datos de forma automática.
  Duration? _maxAge;
  // El timestamp de la última actualización de los datos.
  DateTime _lastFetchTimestamp;
  // Una función asíncrona que actualiza los datos.
  Future<T> Function() _fetchData;
  // Callback invocado cuando _fetchData() produce un valor, sin error.
  void Function(T?)? _onDataRefreshed;

  // Es true si se le indicó a este CacheState que debe actualizar sus datos.
  bool _shouldRefresh;
  // Es true cuando una llamada a _fetchData() todavía no se completa.
  bool _alreadyLoading;
  // Contiene el error de la actualización de datos más reciente.
  Error? _error;

  /// Es __true__ si ya está en proceso de actualizar sus datos.
  bool get isLoading => _alreadyLoading;

  /// Es __true__ si hay datos que no sean nulos.
  bool get hasData => _data != null;

  /// Es __true__ si la última actualización produjo un error.
  bool get hasError => _error != null;

  /// Retorna el [Error] de la actualización más reciente, o [null] si no han 
  /// sucedido errores.
  Error? get error => _error;

  /// Obtiene los datos almacenados en este [CacheState<T>]. 
  /// 
  /// Primero actualiza los datos, si los datos contenidos ya caducaron o si se
  /// invocó [shouldRefresh()]. Si no es necesario, simplemente retorna los
  /// datos obtenidos en ocasiones anteriores. 
  Future<T?> get data async {

    try {
      // Revisar si los datos son viejos (ya han durando más que _dataDuration).
      bool isDataOutdated = _lastFetchTimestamp
        .add(_maxAge ?? const Duration(days: -1))
        .isAfter(DateTime.now());

      // Obtener datos actualizados, si los datos son viejos o si le indicaron 
      // al CacheState que debe refrescar sus datos.
      if (isDataOutdated || _shouldRefresh) {
        refresh();
      }

      return Future.value(_data);
      
    } on Error catch (e) {
      // _fetchData() resultó en un error.
      _alreadyLoading = false;
      _error = e;

      return Future.error(e);
    } 
  }

  Future<void> refresh() async {
    // Solo se puede hacer que el cache se refresque si no se está refrescando ya.
    if (!_alreadyLoading) {
      // Indicar que ya hay un proceso de carga de la información.
      _alreadyLoading = true;

      // Obtener los datos.
      _data = await _fetchData();

      // Actualizar la información de estado de los datos.
      _lastFetchTimestamp = DateTime.now();
      _alreadyLoading = false;
      _shouldRefresh = false;

      // Enviar callback con _onDataRefreshed, si se específico para este cache.
      if (_onDataRefreshed != null) {
        _onDataRefreshed!(_data);
      }
    }
  }

  /// Le indica a este [CacheState<T>] que debería actualizar sus datos internos.
  void shouldRefresh() {
    _shouldRefresh = true;
  }
}