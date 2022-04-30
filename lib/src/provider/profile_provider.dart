import 'package:flutter/material.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/db/where_clause.dart';
import 'package:hydrate_app/src/models/country.dart';
import 'package:hydrate_app/src/models/medical_data.dart';
import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/utils/jwt_parser.dart';

class ProfileProvider extends ChangeNotifier
{
  UserProfile _profile = UserProfile(
    country: Country(id: 0),
    unlockedEnvironments: []
  );

  late UserProfile _profileChanges;

  final List<Country> countries = [];

  bool _profileLoading = true;
  bool _profileError = false;

  bool _countriesLoading = true;

  bool _isProfileModified = false;

  bool get isProfileLoading => _profileLoading;
  bool get hasError => _profileError;

  bool get areCountriesLoading => _countriesLoading;

  UserProfile get profile => _profile;
  UserProfile get profileChanges => _profileChanges;

  ProfileProvider({ int profileId = 0, String authToken = '' }) {

    String? accountId;

    if (authToken.isNotEmpty) {
      final tokenClaims = parseJWT(authToken);

      print('Claims: $tokenClaims');

      accountId = tokenClaims['id'];
    }

    loadCountries();
    loadUserProfile(
      profileId: profileId,
      accountId: accountId
    );
  }

  Future<void> loadUserProfile({ int profileId = 0, String? accountId }) async {
    _profileLoading = true;
    _profileError = false;

    try {
      final whereQuery = [ WhereClause('id', profileId.toString()), ];
      final unions = <String>[];

      if (accountId != null) {
        // Si hay un usuario autenticado, obtener el perfil que tenga el id
        // de perfil Y el id de la cuenta de usuario.
        whereQuery.add(WhereClause('id_usuario', accountId));
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

      if (queryResults.isNotEmpty)
      {
        _profile = queryResults.first;
        _profileChanges = UserProfile.copyOf(_profile);

        assert(_profile.id == profileId);

      } else {
        _profileError = true;
      }
    
    } on Exception catch (_) {
      _profileError = true;
      print('No fue posible obtener perfil desde la BD.');
    }
    finally {
      _profileLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCountries() async {

    _countriesLoading = true;
    countries.clear();
    notifyListeners();

    try {
      final results = await SQLiteDB.instance.select<Country>(
        Country.fromMap, 
        Country.tableName
      );

      countries.addAll(results);

    } on Exception catch (_) {
      _profileError = true;
      print('No fue posible obtener los paises desde la BD.');
    } finally {
      _countriesLoading = false;
      notifyListeners();
    }
  }

  /// Crea un nuevo perfil de usuario, con datos por defecto.
  Future<int> newDefaultProfile({ String? accountID }) async {
    _profileLoading = true;
    _profileError = false;
    notifyListeners();

    int result = -1;

    try {
      final defaultProfile = UserProfile(country: Country(), unlockedEnvironments: []);
      defaultProfile.userAccountID = accountID ?? '';

      result = await SQLiteDB.instance.insert(defaultProfile);

      if (result < 0) throw Exception('El perfil de usuario por default no fue creado.');
    
    } on Exception catch (e) {
      _profileError = true;
      print(e);

    } finally {
      _profileLoading = false;
      notifyListeners();
    }

    return result;
  }

  Future<void> saveProfileChanges({bool restrictModifications = true}) async {
    _profileLoading = true;
    _profileError = false;

    try {
      if (restrictModifications) {
        if (profileChanges.modificationCount >= 3) {
          throw UnsupportedError('El perfil ya llego el limite de modificaciones anuales.');
        }

        profileChanges.modificationCount++;
      }

      int result = await SQLiteDB.instance.update(profileChanges);

      if (result < 1) throw Exception('El perfil de usuario no fue modificado.');

      _profile = _profileChanges;
    
    } on Exception catch (e) {
      _profileError = true;
      print('Error actualizando el perfil de usuario: $e');

    } finally {
      _profileLoading = false;
      notifyListeners();
    }
  }

  /// Busca un perfil local con id_usuario == accountId.
  /// Si lo encuentra, retorna el id del perfil de usuario.
  /// Si no, retorna -1.
  Future<int> findAndSetProfileLinkedToAccount(String accountId) async {
    try {
      final whereQuery = [ WhereClause('id_usuario', accountId), ];

      final queryResults = await SQLiteDB.instance.select<UserProfile>(
        UserProfile.fromMap,
        UserProfile.tableName,
        where: whereQuery,
        limit: 1
      );

      //TODO: Buscar si el servicio web tiene un perfil de usuario para la cuenta.

      if (queryResults.isNotEmpty) {
        final UserProfile profileFound = queryResults.first;

        _profile = profileFound;
        _profileChanges = UserProfile.copyOf(profileFound);

        return profileFound.id;
      } else {
        return -1;
      }
    } on Exception catch (_) {
      return -1;
    }
  }

  int indexOfCountry(Country country) {

    if (countries.isEmpty) return 0;

    return countries.indexWhere((c) => c.id == country.id && c.code == country.code);
  }

  set firstName(String newFirstName) {
    if (newFirstName != _profile.firstName) {
      _isProfileModified = true;
      _profileChanges.firstName = newFirstName;
    }
  }

  set lastName(String newLastName) {
    if (newLastName != _profile.lastName) {
      _isProfileModified = true;
      _profileChanges.lastName = newLastName;
    }
  }

  set dateOfBirth(DateTime? newDateOfBirth) {
    if (newDateOfBirth != _profile.birthDate) {
      _isProfileModified = true;
      _profileChanges.birthDate = newDateOfBirth;
    }
  }

  set userSex(UserSex newUserSex) {
    if (newUserSex != _profile.sex) {
      _isProfileModified = true;
      _profileChanges.sex = newUserSex;
    }
  }

  set height(double newHeight) {
    if (newHeight != _profile.height) {
      _isProfileModified = true;
      _profileChanges.height = newHeight;
    }
  }

  set weight(double newWeight) {
    if (newWeight != _profile.weight) {
      _isProfileModified = true;
      _profileChanges.weight = newWeight;
    }
  }

  set occupation(Occupation newOccupation) {
    if (newOccupation != _profile.occupation) {
      _isProfileModified = true;
      _profileChanges.occupation = newOccupation;
    }
  }

  set medicalCondition(MedicalCondition newMedicalCondition) {
    if (newMedicalCondition != _profile.medicalCondition) {
      _isProfileModified = true;
      _profileChanges.medicalCondition = newMedicalCondition;
    }
  }
}