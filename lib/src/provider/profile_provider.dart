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
  UserProfile _profileChanges = UserProfile.modifiableCopyOf(
    UserProfile.uncommited(
      Country(), 
      Environment.firstUnlocked(), 
      ''
    )
  );

  /// Un contenedor para el [UserProfile] del usuario actual.
  late final CacheState<UserProfile?> _profileCache = CacheState(
    fetchData: _fetchUserProfile,
    onDataRefreshed: (UserProfile? profile) async  {
      // Actualizar el modelo de cambios a perfil. Si el perfil activo no es nulo,
      // los cambios de perfil son una copia del perfil original. Si no, crear 
      // un perfil vacío.
      _profileChanges = profile != null 
        ? UserProfile.modifiableCopyOf(profile)
        : await _buildEmptyProfile(linkedAccountId: '');

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
  Future<List<Country>?> get countries => _countriesCache.data;

  bool get hasEnvironmentsData => _environmentsCache.hasData;
  Future<List<Environment>?> get environments => _environmentsCache.data;

  Future<UserProfile?> _fetchUserProfile() async {
    // Query a la BD.
    final whereQuery = [ WhereClause('id', _profileId.toString()), ];
    final unions = <String>[];

    final isAccountIdSet = _accountId?.isNotEmpty ?? false;

    if (isAccountIdSet) {
      // Si el usuario inició sesión con una cuenta, obtener el perfil que, además
      // de tener el ID de perfil especificado, tenga el id de la cuenta del usuario.
      whereQuery.add(WhereClause('id_usuario', _accountId!));
      unions.add('OR');
    }

    final queryResults = await SQLiteDB.instance.select<UserProfile>(
      UserProfile.fromMap,
      UserProfile.tableName,
      // where: whereQuery,
      // whereUnions: unions,
      includeOneToMany: true,
      queryManyToMany: true,
      // limit: 1
    );

    UserProfile? profile;

    if (queryResults.isNotEmpty)
    {
      profile = queryResults.first;
      // assert(profile.id == _profileId);
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

  Future<AccountLinkResult> handleAccountLink(String authToken, { bool isNewAccount = false }) async {
    // Obtener el ID de la cuenta de usuario desde los claims del token.
    final tokenClaims = parseJWT(authToken);

    if (tokenClaims.containsKey('id') && tokenClaims['id'] is String) {
      // authToken contiene un ID de cuenta, intentar asociar la cuenta con un perfil.
      String accountId = tokenClaims['id'] as String;

      final existingLinkedProfileId = await findProfileLinkedToAccount(accountId); 
      final noLocalProfileForAccount = existingLinkedProfileId.isNegative;

      //TODO: Obtener el perfil de usuario asociado a la cuenta desde la API web.

      if (isNewAccount || noLocalProfileForAccount) {
        //TODO: Si es una nueva cuenta o no hay un perfil local para la cuenta, 
        // guardarlo el perfil de usuario en BD local.
        
        const newLocalProfileId = -1;

        changeProfile(newLocalProfileId, userAccountId: accountId);

        return AccountLinkResult.newProfileCreated;
      } else {
        changeProfile(existingLinkedProfileId, userAccountId: accountId);
        return AccountLinkResult.alreadyLinked;
      }
    } else {
      return AccountLinkResult.noAccountId;
    } 
  }

  /// Guarda un nuevo [UserProfile] en la BD, a partir de los cambios en 
  /// profileChanges. 
  //TODO: Por ahora, este método ya no es usado. Determinar si es necesario mantenerlo.
  Future<int> saveNewProfile() async {
    
    try {
      final profileChanges = _profileChanges;

      int result = await SQLiteDB.instance.insert(profileChanges);

      if (result >= 0) {
        _profileCache.shouldRefresh();
        return result;
      } else {
        //TODO: Eviar lanzar una excepción genérica para cacharla inmediatamente después.
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
      profileChanges.giveOrTakeCoins(-environment.price);

      profileChanges.unlockedEnvironments.add(environment);

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

  Future<UserProfile> _buildEmptyProfile({ String? linkedAccountId }) async {
    // Obtener el país y el entorno principal por defecto. 
    final whereDefault = [ WhereClause("id", "0"), ];

    final countryResults = await SQLiteDB.instance.select<Country>(
      Country.fromMap,
      Country.tableName,
      where: whereDefault,
      limit: 1
    );

    assert(countryResults.isNotEmpty, 'No hay un país por defecto configurado');
    
    // Obtener el pais y el entorno por defecto (deberian ser accesibles para
    // todos los usuarios, desde el inicio de la app).
    final defaultCountry = countryResults.single;

    final emptyProfile = UserProfile.uncommited(
      defaultCountry, 
      Environment.firstUnlocked(),
      linkedAccountId ?? '',
    );

    return emptyProfile;
  }

  /// Crea un nuevo perfil de usuario, con datos por defecto.
  Future<int> newDefaultProfile({ String? existingAccountId }) async {

    // Obtener un nuevo perfil vacío.
    final defaultProfile = await _buildEmptyProfile();

    // Persistir el perfil vacío en la base de datos
    final result = await SQLiteDB.instance.insert(defaultProfile);

    if (result > 0) {
      // El perfil fue creado con éxito. Actualizar el estado interno de este 
      // provider.
      _profileId = result;
      _accountId = defaultProfile.userAccountID;
    }

    return Future.value(result);
  }

  /// Persiste los cambios realizados en [profileChanges] a la base de datos y
  /// le indica al caché de perfiles que debería refrescarse.
  /// 
  /// Retorna el ID del perfil que fue modificado. Si no hay un perfil activo, o 
  /// el perfil no pudo ser modificado por un error de la base de datos, retorna
  /// **-1**.
  /// 
  /// Si  [restrictModifications] es **true**, los cambios serán guardados solo 
  /// si profileChanges.modificationCount < maxYearlyProfileModifications.
  /// 
  /// Si no hay cambios, es decir, si `(await _profileCache.data) == _profileChanges`,
  /// este método retorna inmediatamente.
  Future<int> saveProfileChanges({bool restrictModifications = true}) async {

    final activeProfile = await _profileCache.data;

    // Por alguna razón, no hay un perfil activo.
    if (activeProfile == null) return -1;

    // No hay cambios que guardar. 
    if (activeProfile != _profileChanges) {
      // Determinar si es necesario restringir el número de modificaciones.
      if (restrictModifications) {
        // Los cambios deben ser restringidos por el numero de modificaciones en el
        // perfil.
        if (_profileChanges.modificationCount >= maxYearlyProfileModifications) {
          throw UnsupportedError('El perfil ya llego el limite de modificaciones anuales.');
        }

        _profileChanges.recordModification();
      }

      // Bajo condiciones comunes, esta operación siempre debería ser exitosa.
      int result = await SQLiteDB.instance.update(_profileChanges);

      assert(result > 0, 'Por algun motivo, el perfil no pudo ser actualizado en SQLite');

      if (result < 1) return -1;

      _profileCache.shouldRefresh();
    }
    
    return activeProfile.id;
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

enum AccountLinkResult {
  noAccountId,
  alreadyLinked,
  newProfileCreated,
}