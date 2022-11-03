import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydrate_app/src/api/auth_api.dart';
import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/db/where_clause.dart';
import 'package:hydrate_app/src/exceptions/api_exception.dart';
import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/services/cache_state.dart';
import 'package:hydrate_app/src/utils/jwt_parser.dart';

typedef OnProfileChanged = void Function(UserProfile? profile, String? authToken);

class ProfileService extends ChangeNotifier {

  /// El ID del perfil local del usuario.
  int _profileId;

  /// El JWT para autorizar todas las peticiones del usuario actual.
  String _authToken;

  final OnProfileChanged? _onProfileChanged;

  /// El número máximo de veces que el usuario puede modificar su perfil, en un 
  /// año.
  static const int maxYearlyProfileModifications = 3;

  static const String authTokenKey = "token_auth";
  
  /// Crea una instancia de [ProfileService] que es inicializada con el 
  /// [UserProfile] por defecto.
  ProfileService() 
    : _profileId = UserProfile.defaultProfileId,
      _authToken = "",
      _onProfileChanged = null;

  static late final SharedPreferences? _sharedPreferences;

  /// Inicializa y asigna la instancia de Shared Preferences.
  static Future<void> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  /// Crea un nuevo [ProfileService] que es inicializado con un [profileId] y 
  /// [linkedAccountId] obtenidos desde SharedPreferences.
  /// 
  /// Si no existen keys para el [profileId] o el [linkedAccountId] en Shared 
  /// Preferences, usa sus valores por defecto ([UserProfile.defaultProfileId] 
  /// y un [String] vacío, respectivamente).
  factory ProfileService.fromSharedPrefs({ 
    bool createDefaultProfile = false,
    OnProfileChanged? onProfileChanged,
  }) 
  {
    String prefsAuthToken = _sharedPreferences?.getString(authTokenKey) ?? "";

    if (isTokenExpired(prefsAuthToken)) {
      _sharedPreferences?.setString(authTokenKey, "");
      prefsAuthToken = "";
    } 
    
    final int currentProfileId;

    if (prefsAuthToken.isNotEmpty) {
      currentProfileId = getProfileIdFromJwt(prefsAuthToken);

    } else {
      currentProfileId = UserProfile.defaultProfileId;
    }

    return ProfileService.withProfile(
      profileId: currentProfileId,
      authToken: prefsAuthToken,
      onProfileChanged: onProfileChanged,
    );
  }

  /// Crea una instancia de [ProfileService] que es inicializada con un 
  /// [UserProfile]. 
  /// 
  /// Si [profileId] se omite, el [UserProfile] inicial será aquel identificado
  /// con [UserProfile.defaultProfileId].
  /// 
  /// Si se incluye un [authToken] que no esté vacío y sea válido, el [UserProfile]
  /// inicial deberá tener un [UserProfile.userAccountId] igual al ID de cuenta 
  /// incluido en el token. 
  ProfileService.withProfile({ 
    int profileId = UserProfile.defaultProfileId, 
    String authToken = "", 
    OnProfileChanged? onProfileChanged,
  }): _profileId = profileId,
      _authToken = authToken,
      _onProfileChanged = onProfileChanged;

  /// Contiene todas las modificaciones sin "confirmar" en el perfil de usuario
  /// actual. Esta instancia de [UserProfile] es modificable.
  UserProfile _profileChanges = UserProfile.modifiableCopyOf(UserProfile.defaultProfile);

  /// Un contenedor para el [UserProfile] del usuario actual.
  late final CacheState<UserProfile?> _profileCache = CacheState(
    fetchData: _fetchUserProfile,
    onDataRefreshed: (UserProfile? profile) {
      // Actualizar el modelo de cambios a perfil. Si el perfil activo no es nulo,
      // los cambios de perfil son una copia del perfil original. Si no, los 
      // cambios de perfil son inicializados para un perfil por default.
      _profileChanges = UserProfile.modifiableCopyOf(profile ?? UserProfile.defaultProfile);

      if (_onProfileChanged != null) _onProfileChanged!(profile, _authToken);

      notifyListeners();
    },
  );

  late final CacheState<List<Country>> _countriesCache = CacheState(
    fetchData: _fetchCountries,
    onDataRefreshed: (_) => notifyListeners(),
  );

  late final CacheState<List<Environment>> _environmentsCache = CacheState(
    fetchData: _fetchAllEnvironments,
    onDataRefreshed: (_) => notifyListeners(),
  );

  bool get hasProfileData => _profileCache.hasData;

  int get profileId => _profileId;
  String get authToken => _authToken;

  bool get isAuthenticated => _isAuthenticated();

  bool get doesDefaultProfileRequireSignIn {

    final currentProfile = _profileCache.cachedData;

    final bool isDefaultProfile = currentProfile?.id == UserProfile.defaultProfileId;
    final bool isNotAuthenticated = !_isAuthenticated();
    final bool isProfileLinkedToAccount = currentProfile?.isLinkedToAccount ?? false;

    return isDefaultProfile && isNotAuthenticated && isProfileLinkedToAccount;
  }

  /// Retorna una instancia de solo lectura del [UserProfile] del usuario actual.
  Future<UserProfile?> get profile => _profileCache.data;

  UserProfile get profileChanges => _profileChanges;

  bool get hasCountriesData => _countriesCache.hasData;

  /// Retorna una lista con todos los [Country] disponibles.
  Future<List<Country>> get countries async => 
      (await _countriesCache.data) ?? const <Country>[];

  bool get hasEnvironmentsData => _environmentsCache.hasData;
  Future<List<Environment>?> get environments => _environmentsCache.data;

  Future<void> signOut() => _changeProfile(UserProfile.defaultProfileId, authToken: "");

  bool _isAuthenticated() => _authToken.isNotEmpty && !isTokenExpired(_authToken);

  /// Cambia el perfil actual de esta instancia por el perfil identificado por 
  /// [newProfileId]. 
  /// 
  /// Si [authToken] no es un String vacío y es un JWT sin expirar, el perfil al 
  /// que se cambie además será el asociado a la cuenta de usuario con el ID obtenido 
  /// desde [authToken].
  /// 
  /// Retorna [true] si [newProfileId] es un ID de perfil válido, [authToken]
  /// es un JWT sin expirar (solo se revisa esto si authToken no es un String
  /// vacío) y finalmente, si el perfil fue cambiado con éxito. 
  /// Retorna [false] en caso contrario. 
  Future<bool> _changeProfile(int newProfileId, { String authToken = "" }) async {

    final bool isNewProfileIdValid = newProfileId >= UserProfile.defaultProfileId;
    final bool isNewAuthTokenValid = authToken.isEmpty || !isTokenExpired(authToken);
    final bool didCredentialsChange = (newProfileId != _profileId || authToken != _authToken);

    final shouldChangeProfile = didCredentialsChange && isNewProfileIdValid && isNewAuthTokenValid;

    if (shouldChangeProfile) {

      _profileId = newProfileId;
      _authToken = authToken;

      _sharedPreferences?.setString(authTokenKey, authToken);

      await _profileCache.refresh();
    }

    return shouldChangeProfile;
  }

  /// Obtiene un [UserProfile] local con un ID igual a [_profileId] o, si hay 
  /// un ID de cuenta de usuario válido en [_authToken], un [UserProfile] local
  /// que tenga ese mismo ID de cuenta de usuario.
  /// 
  /// Retorna el [UserProfile] que cumpla las condiciones anteriores, o [null]
  /// si no hay un registro en la base de datos local para esos IDs.
  Future<UserProfile?> _fetchUserProfile() async {
    // Siempre se usa el valor de _profileId como parte del WHERE para la query.
    final whereQuery = [ WhereClause(UserProfile.idFieldName, _profileId.toString()), ];
    final unions = <String>[];

    final accountId = getAccountIdFromJwt(_authToken);
    final isAccountIdSet = accountId.isNotEmpty;

    // Determinar si hay un ID de cuenta de usuario en accountId.
    if (isAccountIdSet) {
      // Si el usuario inició sesión con una cuenta, obtener el perfil que, además
      // de tener el ID de perfil especificado, tenga el id de la cuenta del usuario.
      whereQuery.add(WhereClause(UserProfile.userAccountIdFieldName, accountId));
      unions.add("AND");
    }

    final isDefaultProfile = _profileId == UserProfile.defaultProfileId;

    UserProfile? profile;

    if (isDefaultProfile) {
      profile = await getDefaultLocalProfile();

    } else {
      final queryResults = await SQLiteDB.instance.select<UserProfile>(
        UserProfile.fromMap,
        UserProfile.tableName,
        where: whereQuery,
        whereUnions: unions,
        includeOneToMany: true,
        queryManyToMany: true,
        limit: 1
      );

      if (queryResults.isNotEmpty)
      {
        profile = queryResults.first;
      }
    }

    if (profile != null) {
      assert(profile.id == _profileId);
    }

    return Future.value(profile);
  }

  Future<List<Environment>> _fetchAllEnvironments() async {

    final queryResults = await SQLiteDB.instance.select<Environment>(
      Environment.fromMap, 
      Environment.tableName,
    );

    return queryResults.toList();
  }

  Future<List<Country>> _fetchCountries() async {
    // Query a BD.
    final queryResults = await SQLiteDB.instance.select<Country>(
      Country.fromMap, 
      Country.tableName,
    );

    return Future.value(queryResults.toList());
  }

  /// Configura un perfil local asociado a una cuenta de usuario identificada
  /// por [authToken].
  /// 
  /// Si ya existe un perfil local asociado con la cuenta, actualiza sus datos
  /// con los obtenidos desde la API de perfiles.
  /// 
  /// En caso de que no existe un perfil local asociado y el perfil por defecto
  /// ya está asociado a una cuenta, este método persiste un nuevo registro con
  /// los datos del perfil.
  /// 
  /// Si no existe un perfil local asociado y el perfil por defecto todavía no
  /// ha sido asociado con una cuenta, el usuario puede especificar si desea 
  /// asociarlo.
  /// 
  /// Retorna __true__ si el perfil local por defecto puede ser asociado con 
  /// la cuenta.
  Future<bool> setLocalProfileForAccount(String authToken) async {
    // Obtener el ID de la cuenta de usuario desde los claims del token.
    final String userAccountId = getAccountIdFromJwt(authToken);

    final int existingLinkedProfileId = await findProfileLinkedToAccount(userAccountId); 
    final localProfileExists = existingLinkedProfileId >= UserProfile.defaultProfileId;

    final allLocalCountries = await _fetchCountries();
    final allLocalEnvironments = await _fetchAllEnvironments();

    // Obtener el perfil para userAccountId desde el servicio web.
    final _authApi = AuthApi();

    final profileFromAuthService = await _authApi.fetchProfileForAccount(
      authToken,
      allCountries: allLocalCountries,
      allEnvironments: allLocalEnvironments,
    );

    _authApi.dispose();

    _profileChanges = UserProfile.modifiableCopyOf(profileFromAuthService);
    _profileChanges.userAccountID = userAccountId;

    final bool canLinkDefaultProfileToAccount;

    if (localProfileExists) {
      final syncResult = await syncLocalProfile( fetchedProfile: profileFromAuthService );

      final isLocalProfileInSync = syncResult == SaveProfileResult.noChanges || 
        syncResult == SaveProfileResult.changesSaved;

      if (isLocalProfileInSync) {
        await _changeProfile(existingLinkedProfileId, authToken: authToken);
      }

      canLinkDefaultProfileToAccount = false;
      
    } else {
      final defaultLocalProfile = await getDefaultLocalProfile();

      assert(defaultLocalProfile != null, "Se esperaba que el perfil local por defecto fuera no-nulo, pero no lo es.");

      final bool isDefaultProfileAlreadyLinked = defaultLocalProfile!.isLinkedToAccount;

      if (isDefaultProfileAlreadyLinked) {
        // Crear un nuevo perfil local, asociado con la cuenta de usuario.
        _profileChanges.id = -1;
        final newLocalProfile = _profileChanges;

        final newLocalProfileId = await SQLiteDB.instance.insert(newLocalProfile);

        final wasProfileCreated = newLocalProfileId > UserProfile.defaultProfileId;

        if (wasProfileCreated) {
          await _changeProfile(newLocalProfileId, authToken: authToken);
        }

        canLinkDefaultProfileToAccount = false;
      } else {
        // Si el perfil actual no está asociado a una cuenta de usuario, debería 
        // preguntársele al usuario si desea asociar el perfil actual con la 
        // cuenta autenticada. Esto debe ser realizado por el invocador de este
        // método (véase [canLinkAccountToCurrentProfile]).
        _authToken = authToken;
        canLinkDefaultProfileToAccount = true;
      }
    }

    return canLinkDefaultProfileToAccount;
  }

  /// Asocia un perfil de usuario local (offline) con la cuenta de usuario 
  /// identificada por [authToken].
  /// 
  /// Si [authToken] es null, usa el token de autenticación de la cuenta de
  /// usuario actual de esta instancia.
  /// 
  /// Lanza una excepción si ocurre un error al intentar asociar el perfil con 
  /// la cuenta de usuario 
  Future<void> handleAccountLink({ String? authToken, }) async {

    authToken ??= _authToken;

    final defaultLocalProfile = await getDefaultLocalProfile(); 

    assert(defaultLocalProfile != null, "Se esperaba que el perfil local por defecto fuera no-nulo, pero no lo es.");

    final String userAccountId = getAccountIdFromJwt(authToken);
    defaultLocalProfile!.userAccountID = userAccountId;

    const int expectedAlteredRows = 1;
    final int alteredRows = await SQLiteDB.instance.update(defaultLocalProfile);

    if (alteredRows <= 0 || alteredRows > 1) {
      throw Exception("Esperaba modificar $expectedAlteredRows fila(s), pero $alteredRows fueron alteradas.");
    }
  }

  /// Cambia el [Environment] seleccionado para el [UserProfile] actual por
  /// [environment], si el perfil actual ha desbloqueado a [environment].
  /// 
  /// Luego, notifica a los listeners de este provider.
  void changeSelectedEnv(Environment environment) {

    _profileChanges.selectedEnvironment = environment;
    notifyListeners();
  }

  /// Desbloquea un nuevo [Environment] para el [profile] activo. 
  /// 
  /// Retorna [true] si el usuario tenía monedas suficientes y el [environment]
  /// fue agregado a [profileChanges.unlockedEnvironments].
  /// 
  /// Este cambio solo es reflejado cuando el usuario confirma los cambios
  /// a su [UserProfile], cuando se llama [ProfileProvider.saveProfileChanges()].
  Future<bool> purchaseEnvironment(Environment environment) async {

    final profile = await _profileCache.data;

    if (profile != null && !profile.hasUnlockedEnv(environment.id)) {
      /// Desbloquear el entorno de forma no confirmada, usando profileChanges.
      final wasEnvPurchased = _profileChanges.spendCoins(environment.price);

      if (wasEnvPurchased) {
        _profileChanges.unlockedEnvironments.add(environment);
      }

      return wasEnvPurchased;
    } else {
      return false;
    }
  }

  Future<bool> confirmEnvironment() async {

    final activeProfile = await _profileCache.data;

    // Este método solo debería ser invocado cuando existe un perfil activo
    // no nulo. Si es invocado sin un perfil, se trata de un error.
    if (activeProfile == null) {
      throw UnsupportedError("Tried to change the environment without an active profile.");
    }

    final selectedEnvironment = _profileChanges.selectedEnvironment;

    final hasUnlockedEnv = activeProfile.hasUnlockedEnv(selectedEnvironment.id);

    bool wasEnvConfirmed = true;

    if (!hasUnlockedEnv) {
      wasEnvConfirmed = await purchaseEnvironment(selectedEnvironment);
    }

    if (wasEnvConfirmed) {
      changeSelectedEnv(selectedEnvironment);
    }

    return wasEnvConfirmed;
  }

  /// Persiste un nuevo [UserProfile] en la base de datos y cambia la sesión
  /// al nuevo perfil. Retorna el ID del perfil creado, o un entero negativo
  /// si el perfil no pudo ser creado.
  /// 
  /// Si [saveEmpty] es **true**, el nuevo perfil será creado como un perfil 
  /// vacío (por defecto, sin datos). Si es **false**, el perfil tendrá los 
  /// valores encontrados en [_profileChanges]. 
  Future<int> saveEmptyProfile({ String authToken = "", }) async {

    final newProfile = UserProfile.uncommitted();

    // Persistir el nuevo perfil en la base de datos
    final resultId = await SQLiteDB.instance.insert(newProfile);

    final wasProfileCreated = resultId >= UserProfile.defaultProfileId;

    if (wasProfileCreated) {
      // Update the active profile to the newly created one.
      _changeProfile(resultId, authToken: authToken);
    }

    return resultId;
  }

  /// Persiste los cambios realizados en [profileChanges] a la base de datos y
  /// le indica al caché de perfiles que debería refrescarse.
  /// 
  /// Si  [isSyncOperation] es **true**, los al perfil descritos en _profileChanges
  /// serán aplicados como una sincronización del perfil, no como  profileChanges.modificationCount < maxYearlyProfileModifications.
  /// 
  /// Retorna uno de los siguientes valores de [SaveProfileResult], según el caso:
  ///  - [changesSaved]: si el perfil fue actualizado correctamente.
  ///  - [noChanges]: si no hay diferencias en el perfil, retorna inmediatamente.
  ///  - [profileNotFound]: si no se puede encontrar el perfil actual.
  ///  - [reachedChangeLimit]: si [restrictModifications] es **true** y el perfil 
  ///      ya no puede ser modificado.
  ///  - [persistenceError]: si hubo un error de persistencia al intentar guardar
  ///     los cambios.
  Future<SaveProfileResult> saveProfileChanges({ bool isSyncOperation = false }) async {

    final currentProfile = await _profileCache.data;
    
    // Por alguna razón, el perfil actual no coincide.
    final isProfileMissing = currentProfile == null;
    if (isProfileMissing) return SaveProfileResult.profileNotFound;

    // Solo es necesario guardar modificaciones cuando hay diferencias entre 
    // currentProfile y _profileChanges. 
    if (currentProfile != _profileChanges) {

      // Determinar si es necesario restringir el número de modificaciones.
      if (currentProfile!.hasCriticalChanges(_profileChanges)) {
        // Los cambios deben ser restringidos por el numero de modificaciones en el
        // perfil.
        // if (_profileChanges.modificationCount >= maxYearlyProfileModifications) {
        //   // El perfil ya alcanzó el límite de modificaciones restringidas.
        //   // Reestablecer los cambios al perfil.
        //   _profileChanges = UserProfile.modifiableCopyOf(_profileCache.cachedData!);
        //   // El perfil no debe ser modificado.
        //   return SaveProfileResult.reachedChangeLimit;
        // }

        // _profileChanges.recordModification();
      }

      // Intentar guardar los cambios al perfil existente
      final int alteredRows = await SQLiteDB.instance.update(_profileChanges);

      // Si ninguna fila fue modificada, el perfil no pudo ser actualizado a 
      // causa de un error con la base de datos.
      if (alteredRows > 0) {
        _updateProfileWithLocalChanges(_profileChanges);
        _profileCache.shouldRefresh();
        return SaveProfileResult.changesSaved;
      } else {
        return SaveProfileResult.persistenceError;
      }

    } else {
      return SaveProfileResult.noChanges;
    }
  }

  /// Actualiza el perfil local, usando los datos obtenidos desde la API REST 
  /// de perfiles de usuario. 
  /// 
  /// Este método **NO** restringe el número de modificaciones. No debería ser usado 
  /// para actualizar el perfil cuando los cambios son producidos por el usuario.
  /// Para hacer esto último, debe usarse en vez [saveProfileChanges].
  /// 
  /// Si [fetchedProfile] es nulo, este método hace una petición a la API REST 
  /// de perfiles para actualizar el perfil local con los datos del perfil 
  /// obtenido. En caso contrario, usa los datos encontrados en [fetchedProfile]. 
  Future<SaveProfileResult> syncLocalProfile({ UserProfile? fetchedProfile }) async {

    final _authApi = AuthApi();
    
    final updatedProfile = fetchedProfile ?? await _authApi.fetchProfileForAccount(authToken);

    _authApi.dispose();

    final currentLocalProfile = await _profileCache.data;

    final bool requiresLocalUpdate = currentLocalProfile != updatedProfile;

    final SaveProfileResult saveStatus;

    if (requiresLocalUpdate) {
      // Intentar actualizar el perfil existente con los cambios.
      final int alteredRows = await SQLiteDB.instance.update(updatedProfile);

      final bool wasLocalProfileUpdated = alteredRows > 0;

      if (wasLocalProfileUpdated) {
        _profileCache.shouldRefresh();
        saveStatus = SaveProfileResult.changesSaved;
      } else {
        saveStatus = SaveProfileResult.persistenceError;
      }
    } else {
      saveStatus = SaveProfileResult.noChanges;
    }

    return saveStatus;
  }

  Future<void> _updateProfileWithLocalChanges(UserProfile localProfileChanges) async {
    final _authApi = AuthApi();

    try {

      await _authApi.updateProfileWithChanges(authToken, localProfileChanges);

    } on ApiException catch (ex) {
      //TODO: notificar al usuario que su perfil no pudo ser sincronizado.
      debugPrint("Error al sincronizar cambios a perfil ($ex)");
    } 
  }

  /// Busca un [UserProfile] local que tenga un userAccountID igual a 
  /// [accountId].
  /// 
  /// Si encuentra un perfil que coincida, retorna el ID del perfil local. En
  /// caso contrario, retorna un número entero negativo.
  Future<int> findProfileLinkedToAccount(String accountId) async {

    final whereQuery = [ WhereClause(UserProfile.userAccountIdFieldName, accountId), ];

    final queryResults = await SQLiteDB.instance.select<UserProfile>(
      UserProfile.fromMap,
      UserProfile.tableName,
      where: whereQuery,
      limit: 1,
      queryManyToMany: true,
      includeOneToMany: true,
    );

    final localProfile = queryResults.length == 1 ? queryResults.single : null;

    return (localProfile != null) ? localProfile.id : -1; 
  }
}

Future<UserProfile?> getDefaultLocalProfile() async {

  final whereQuery = [ WhereClause(UserProfile.idFieldName, UserProfile.defaultProfileId.toString()), ];

  final queryResults = await SQLiteDB.instance.select<UserProfile>(
    UserProfile.fromMap,
    UserProfile.tableName,
    where: whereQuery,
    includeOneToMany: true,
    queryManyToMany: true,
    limit: 1,
  );

  UserProfile? localProfile = queryResults.isNotEmpty ? queryResults.first : null;

  if (localProfile == null) {
    await SQLiteDB.instance.insert(UserProfile.defaultProfile);
    localProfile = UserProfile.defaultProfile;
  }

  return localProfile;
}

enum AccountLinkResult {
  localProfileInSync,
  requiresInitialData,
  error,
}

enum SaveProfileResult {
  changesSaved,
  noChanges,
  profileNotFound,
  reachedChangeLimit,
  persistenceError,
}