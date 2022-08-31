import 'package:flutter/material.dart';
import 'package:hydrate_app/src/api/auth_api.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/db/where_clause.dart';
import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/provider/cache_state.dart';
import 'package:hydrate_app/src/utils/jwt_parser.dart';

class ProfileProvider extends ChangeNotifier {

  /// El ID del perfil local del usuario.
  int _profileId;

  /// El UUID de la cuenta de usuario del servicio web asociada con el 
  /// perfil. 
  String? _accountId;

  /// El número máximo de veces que el usuario puede modificar su perfil, en un 
  /// año.
  static const int maxYearlyProfileModifications = 3;
  
  /// Crea una instancia de [ProfileProvider] que es inicializada con el 
  /// [UserProfile] por defecto.
  ProfileProvider()
    : _profileId = UserProfile.defaultProfileId;

  /// Crea una instancia de [ProfileProvider] que es inicializada con un 
  /// [UserProfile]. 
  /// 
  /// Si [profileId] se omite, el [UserProfile] inicial será aquel identificado
  /// con [UserProfile.defaultProfileId].
  /// 
  /// Si se incluye un [authToken] que no esté vacío y sea válido, el [UserProfile]
  /// inicial deberá tener un [UserProfile.userAccountId] igual al ID de cuenta 
  /// incluido en el token. 
  ProfileProvider.withProfile({ 
    int profileId = UserProfile.defaultProfileId, 
    String authToken = '', 
  }): _profileId = profileId,
      _accountId = authToken.isNotEmpty ? parseJWT(authToken)['id'] : null;

  /// Contiene todas las modificaciones sin "confirmar" en el perfil de usuario
  /// actual. Esta instancia de [UserProfile] es modificable.
  UserProfile _profileChanges = UserProfile.modifiableCopyOf(UserProfile.defaultProfile);

  /// Un contenedor para el [UserProfile] del usuario actual.
  late final CacheState<UserProfile?> _profileCache = CacheState(
    fetchData: _fetchUserProfile,
    onDataRefreshed: (UserProfile? profile) async  {
      // Actualizar el modelo de cambios a perfil. Si el perfil activo no es nulo,
      // los cambios de perfil son una copia del perfil original. Si no, crear 
      // un perfil vacío.
      _profileChanges = profile != null 
        ? UserProfile.modifiableCopyOf(profile)
        : UserProfile.uncommitted();

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
  String get linkedAccountId => _accountId ?? '';

  /// Retorna una instancia de solo lectura del [UserProfile] del usuario actual.
  Future<UserProfile?> get profile => _profileCache.data;

  UserProfile get profileChanges => _profileChanges;

  bool get hasCountriesData => _countriesCache.hasData;

  /// Retorna una lista con todos los [Country] disponibles.
  Future<List<Country>> get countries async => 
      (await _countriesCache.data) ?? const <Country>[];

  bool get hasEnvironmentsData => _environmentsCache.hasData;
  Future<List<Environment>?> get environments => _environmentsCache.data;

  /// Cambia el perfil actual al perfil identificado por [newProfileId] o 
  /// asociado con [userAccountId]. Luego, refresca el caché de 
  /// perfiles de usuario.
  void _changeProfile(int newProfileId, { String? userAccountId }) {

    _profileId = newProfileId;
    _accountId = userAccountId;

    _profileCache.refresh();
  }

  /// Obtiene un [UserProfile] local con un ID igual a [_profileId] o, si hay 
  /// un ID de cuenta de usuario válido en [_accountId], un [UserProfile] local
  /// que tenga ese mismo ID de cuenta de usuario.
  /// 
  /// Retorna el [UserProfile] que cumpla las condiciones anteriores, o [null]
  /// si no hay un registro en la base de datos local para esos IDs.
  Future<UserProfile?> _fetchUserProfile() async {
    // Siempre se usa el valor de _profileId como parte del WHERE para la query.
    final whereQuery = [ WhereClause(UserProfile.idFieldName, _profileId.toString()), ];
    final unions = <String>[];

    final isAccountIdSet = _accountId?.isNotEmpty ?? false;

    // Determinar si hay un ID de cuenta de usuario en _accountId.
    if (isAccountIdSet) {
      // Si el usuario inició sesión con una cuenta, obtener el perfil que, además
      // de tener el ID de perfil especificado, tenga el id de la cuenta del usuario.
      whereQuery.add(WhereClause(UserProfile.userAccountIdFieldName, _accountId!));
      //TODO: revisar uso de OR en vez de AND.
      unions.add("OR");
    }

    final queryResults = await SQLiteDB.instance.select<UserProfile>(
      UserProfile.fromMap,
      UserProfile.tableName,
      where: whereQuery,
      whereUnions: unions,
      includeOneToMany: true,
      queryManyToMany: true,
      limit: 1
    );

    UserProfile? profile;

    if (queryResults.isNotEmpty)
    {
      profile = queryResults.first;
      assert(profile.id == _profileId);
    }

    return Future.value(profile);
  }

  Future<List<Environment>> _fetchAllEnvironments() async {
    // Query a BD.
    final queryResults = await SQLiteDB.instance.select<Environment>(
      Environment.fromMap, 
      Environment.tableName,
    );

    return Future.value(queryResults.toList());
  }

  Future<List<Country>> _fetchCountries() async {
    // Query a BD.
    final queryResults = await SQLiteDB.instance.select<Country>(
      Country.fromMap, 
      Country.tableName,
    );

    return Future.value(queryResults.toList());
  }

  /// Crea o actualiza un registro local de [UserProfile] con el perfil de 
  /// usuario obtenido desde la API web para la cuenta con [userAccountId].
  /// 
  /// Si el perfil asociado con la cuenta apenas ha sido creado, este método
  /// retorna [AccountLinkResult.requiresInitialData].
  /// 
  /// Si el perfil ya tiene datos y el perfil local pudo ser completado con su 
  /// información, retorna [AccountLinkResult.localProfileInSync].
  /// 
  /// Si ocurre un error al obtener el perfil de usuario desde la API, lanza 
  /// una [ApiException] con la causa del problema.
  /// 
  /// Si hay un error de persistencia local, retorna [AccountLinkResult.error].
  Future<AccountLinkResult> handleAccountLink(String userAccountId, { bool wasAccountJustCreated = false}) async {

    final existingLinkedProfileId = await findProfileLinkedToAccount(userAccountId); 
    final localProfileExists = existingLinkedProfileId >= 0;

    // Obtener el perfil para userAccountId desde el servicio web.
    final _authApi = AuthApi();

    final profile = await _authApi.fetchProfileForAccount(userAccountId);

    AccountLinkResult linkResult = AccountLinkResult.error;

    // Determinar si la app debería completar el perfil de usuario obtenido.
    if (wasAccountJustCreated || profile.isDefaultProfile) {
      // Si el perfil de usuario obtenido desde la API web es un perfil 
      // default, retornar AccountLinkResult.newProfileCreated para indicar que 
      // el perfil debería ser completado con el formulario inicial.
      linkResult = AccountLinkResult.requiresInitialData;

    } else {
      // El perfil ya tiene datos; sincronizar el perfil local.
      _profileChanges = profile;

      SaveProfileResult syncResult = SaveProfileResult.noChanges;

      if (localProfileExists) {
        // Si el perfil local ya existe, actualizarlo con los datos de profile:
        syncResult = await saveProfileChanges( restrictModifications: false );
      } else {
        // Cuando no hay un perfil local para la cuenta, crear uno nuevo con sus 
        // datos:
        final newLocalProfileId = await saveNewProfile( saveEmpty: false );

        syncResult = newLocalProfileId >= 0 
          ? SaveProfileResult.changesSaved
          : SaveProfileResult.persistenceError;
      }

      if (syncResult == SaveProfileResult.noChanges || 
          syncResult == SaveProfileResult.changesSaved) {
        linkResult = AccountLinkResult.localProfileInSync;     
      }
    }

    if (linkResult != AccountLinkResult.error) {
      // En ambos casos, cambiar al perfil de la cuenta.
      _changeProfile(existingLinkedProfileId, userAccountId: userAccountId);
    }

    return linkResult;
  }

  /// Cambia el [Environment] seleccionado para el [UserProfile] actual por
  /// [environment], si el perfil actual ha desbloqueado a [environment].
  /// 
  /// Luego, notifica a los listeners de este provider.
  void changeSelectedEnv(Environment environment) {

    final isEnvUnlocked = profileChanges.hasUnlockedEnv(environment.id);

    if (isEnvUnlocked) {
      profileChanges.selectedEnvId = environment.id;
      notifyListeners();
    }
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
      final wasEnvPurchased = profileChanges.spendCoins(environment.price);

      if (wasEnvPurchased) {
        profileChanges.unlockedEnvironments.add(environment);
      }

      return wasEnvPurchased;
    } else {
      return false;
    }
  }

  /// Persiste un nuevo [UserProfile] en la base de datos y cambia la sesión
  /// al nuevo perfil. Retorna el ID del perfil creado, o un entero negativo
  /// si el perfil no pudo ser creado.
  /// 
  /// Si [saveEmpty] es **true**, el nuevo perfil será creado como un perfil 
  /// vacío (por defecto, sin datos). Si es **false**, el perfil tendrá los 
  /// valores encontrados en [_profileChanges]. 
  Future<int> saveNewProfile({ bool saveEmpty = false, }) async {

    // Obtener los datos del nuevo perfil, según el valor de saveEmpty.
    final newProfile = saveEmpty 
      ? UserProfile.uncommitted()
      : _profileChanges;

    // Persistir el nuevo perfil en la base de datos
    final resultId = await SQLiteDB.instance.insert(newProfile);

    final wasProfileCreated = resultId >= UserProfile.defaultProfileId;

    if (wasProfileCreated) {
      // Update the active profile to the newly created one.
      _changeProfile(resultId, userAccountId: newProfile.userAccountID);
    }

    return resultId;
  }

  /// Persiste los cambios realizados en [profileChanges] a la base de datos y
  /// le indica al caché de perfiles que debería refrescarse.
  /// 
  /// Si  [restrictModifications] es **true**, los cambios serán guardados solo 
  /// cuando profileChanges.modificationCount < maxYearlyProfileModifications.
  /// 
  /// Retorna uno de los siguientes valores de [SaveProfileResult], según el caso:
  ///  - [changesSaved]: si el perfil fue actualizado correctamente.
  ///  - [noChanges]: si no hay diferencias en el perfil, retorna inmediatamente.
  ///  - [profileNotFound]: si no se puede encontrar el perfil actual.
  ///  - [reachedChangeLimit]: si [restrictModifications] es **true** y el perfil 
  ///      ya no puede ser modificado.
  ///  - [persistenceError]: si hubo un error de persistencia al intentar guardar
  ///     los cambios.
  Future<SaveProfileResult> saveProfileChanges({bool restrictModifications = true}) async {

    final currentProfile = await _profileCache.data;
    
    // Por alguna razón, el perfil actual no coincide.
    final isProfileMissing = currentProfile == null;
    if (isProfileMissing) return SaveProfileResult.profileNotFound;

    // Solo es necesario guardar modificaciones cuando hay diferencias entre 
    // currentProfile y _profileChanges. 
    if (currentProfile != _profileChanges) {

      // Determinar si es necesario restringir el número de modificaciones.
      if (restrictModifications) {
        // Los cambios deben ser restringidos por el numero de modificaciones en el
        // perfil.
        if (_profileChanges.modificationCount >= maxYearlyProfileModifications) {
          // El perfil ya alcanzó el límite de modificaciones restringidas.
          // El perfil no debe ser modificado.
          return SaveProfileResult.reachedChangeLimit;
        }

        _profileChanges.recordModification();
      }

      // Intentar guardar los cambios al perfil existente
      int alteredRows = await SQLiteDB.instance.update(_profileChanges);

      // Si ninguna fila fue modificada, el perfil no pudo ser actualizado a 
      // causa de un error con la base de datos.
      if (alteredRows > 0) {
        _profileCache.shouldRefresh();
        return SaveProfileResult.changesSaved;
      } else {
        return SaveProfileResult.persistenceError;
      }

    } else {
      return SaveProfileResult.noChanges;
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
      limit: 1
    );

    final localProfile = queryResults.length == 1 ? queryResults.single : null;

    return (localProfile != null) ? localProfile.id : -1; 
  }
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