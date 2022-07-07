import 'package:flutter/material.dart';

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
  UserProfile? _profileChanges;

  /// Un contenedor para el [UserProfile] del usuario actual.
  late final CacheState<UserProfile?> _profileCache = CacheState(
    fetchData: _fetchUserProfile,
    onDataRefreshed: (UserProfile? profile) {
      // Actualizar el modelo de cambios a perfil, con el perfil actual.
      _profileChanges = profile != null 
        ? UserProfile.modifiableCopyOf(profile)
        : null;

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

  UserProfile? get profileChanges => _profileChanges;

  bool get hasCountriesData => _countriesCache.hasData;
  Future<List<Country>?> get countries => _countriesCache.data;

  bool get hasEnvironmentsData => _environmentsCache.hasData;
  Future<List<Environment>?> get environments => _environmentsCache.data;

  Future<UserProfile?> _fetchUserProfile() async {
    // Query a la BD.
    final whereQuery = [ WhereClause('id', _profileId.toString()), ];
    final unions = <String>[];

    if (_accountId != null) {
      // Si hay un usuario autenticado, obtener el perfil que tenga el id
      // de perfil Y el id de la cuenta de usuario.
      whereQuery.add(WhereClause('id_usuario', _accountId!));
      unions.add('OR');
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

  /// Guarda un nuevo [UserProfile] en la BD, a partir de los cambios en 
  /// profileChanges. 
  Future<int> saveNewProfile() async {
    
    try {
      final profileChanges = _profileChanges;

      if (profileChanges == null) {
        throw StateError('profileChanges es nulo. Esto no debería ser posible.');
      }

      int result = await SQLiteDB.instance.insert(profileChanges);

      if (result >= 0) {
        _profileCache.shouldRefresh();
        return result;
      } else {
        throw Exception('No se pudo crear el nuevo perfil.');
      }
    }
    on Exception catch (e) {
      return Future.error(e);

    } finally {
      notifyListeners();
    }
  }

  void changeSelectedEnv(Environment environment) {

    final isEnvUnlocked = profileChanges?.hasUnlockedEnv(environment.id) ?? false;

    if (isEnvUnlocked) {
      profileChanges?.selectedEnvId = environment.id;
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
      profileChanges?.giveOrTakeCoins(-environment.price);

      profileChanges?.unlockedEnvironments.add(environment);

      return true;
    } else {
      return false;
    }
  }

  void changeProfile(int newProfileId, { String? userAccountId }) {

    _profileId = newProfileId;
    _accountId = userAccountId;

    _profileCache.shouldRefresh();
  }

  /// Crea un nuevo perfil de usuario, con datos por defecto.
  Future<int> newDefaultProfile({ String? existingAccountId }) async {

    final countries = (await _countriesCache.data);
    final environments = (await _environmentsCache.data);

    if (countries != null && environments != null) {

      // Obtener el pais y el entorno por defecto (deberian ser accesibles para
      // todos los usuarios, desde el inicio de la app).
      final defaultCountry = countries.where((country) => country.id == 0).single;
      final defaultEnv = environments.where((env) => env.id == 0).single;

      final defaultProfile = UserProfile.uncommited(
        defaultCountry, 
        defaultEnv,
        existingAccountId ?? '',
      );

      final result = await SQLiteDB.instance.insert(defaultProfile);

      if (result > 0) {
        _profileId = result;
        _accountId = defaultProfile.userAccountID;

        return Future.value(result);
      }
    }

    return Future.value(-1);
  }

  Future<void> saveProfileChanges({bool restrictModifications = true}) async {

    final activeProfile = await _profileCache.data;
    final profileChanges = _profileChanges;

    // No hay cambios que guardar. 
    if (activeProfile == profileChanges) return;

    if (profileChanges == null) {
      throw StateError('profileChanges es nulo. Esto no debería ser posible.');
    }

    if (restrictModifications) {
      // Los cambios deben ser restringidos por el numero de modificaciones en el
      // perfil.
      if (profileChanges.modificationCount >= 3) {
        throw UnsupportedError('El perfil ya llego el limite de modificaciones anuales.');
      }

      profileChanges.recordModification();
    }

    int result = await SQLiteDB.instance.update(profileChanges);

    if (result < 1) throw Exception('El perfil de usuario no fue modificado.');

    _profileCache.shouldRefresh();
  }

  /// Busca un perfil local con id_usuario == accountId.
  /// Si lo encuentra, retorna el id del perfil de usuario.
  /// Si no, retorna -1.
  Future<int> findProfileLinkedToAccount(String accountId) async {

    final whereQuery = [ WhereClause('id_usuario', accountId), ];

    final queryResults = await SQLiteDB.instance.select<UserProfile>(
      UserProfile.fromMap,
      UserProfile.tableName,
      where: whereQuery,
      limit: 1
    );

    //TODO: Buscar si el servicio web tiene un perfil de usuario para la cuenta.

    final profileFound = queryResults.length == 1 ? queryResults.single : null;

    if (profileFound != null) {

      _profileId = profileFound.id;
      _accountId = profileFound.userAccountID;

      _profileCache.shouldRefresh();

      return profileFound.id;
    } else {
      return -1;
    }
  }
}