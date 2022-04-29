import 'package:flutter/material.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/db/where_clause.dart';
import 'package:hydrate_app/src/models/country.dart';
import 'package:hydrate_app/src/models/medical_data.dart';
import 'package:hydrate_app/src/models/user_profile.dart';

class ProfileProvider extends ChangeNotifier
{
  UserProfile _profile = UserProfile(
    id: 1,
    firstName: 'Juan',
    lastName: 'Perez',
    birthDate: DateTime(2000, 1, 1),
    sex: UserSex.man,
    country: Country(id: 0, code: 'MX'),
    height: 1.75,
    weight: 60.0,
    medicalCondition: MedicalCondition.none,
    occupation: Occupation.student,
    userAccountID: '',
    coins: 1327,
    unlockedEnvironments: [],
  );

  UserProfile _profileChanges = UserProfile(country: Country(), unlockedEnvironments: []);

  final List<Country> countries = [];

  bool _profileLoading = true;
  bool _profileError = false;

  bool _isProfileModified = false;

  bool get isProfileLoading => _profileLoading;
  bool get hasError => _profileError;
  bool get isProfileModified => _isProfileModified;

  UserProfile get profile => _profile;
  UserProfile get profileChanges => _profileChanges;

  Future retrieveUserProfile({ int profileId = -1, String? accountId }) async {
    _profileLoading = true;
    _profileError = false;

    try {
      final whereQuery = [ WhereClause('id', profileId.toString()), ];
      final unions = <String>[];

      if (accountId != null) {
        // Si hay un usuario autenticado, obtener el perfil que tenga el id
        // de perfil Y el id de la cuenta de usuario.
        whereQuery.add(WhereClause('id_usuario', accountId));
        unions.add('AND');
      }

      final queryResults = await SQLiteDB.instance.select<UserProfile>(
        UserProfile.fromMap,
        UserProfile.tableName,
        where: whereQuery,
        whereUnions: unions,
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
      print('Imposible obtener perfil desde BD.');
    }
    finally {
      _profileLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProfileChanges() async {
    _profileLoading = true;
    _profileError = false;

    try {
      if (profileChanges.modificationCount >= 3) {
        throw UnsupportedError('El perfil ya llego al limite de modificaciones anuales.');
      }

      profileChanges.modificationCount++;

      int result = await SQLiteDB.instance.update(profileChanges);

      if (result < 1) throw Exception('El perfil de usuario no fue modificado.');
    
    } on Exception catch (e) {
      _profileError = true;
      print('Error actualizando el perfil de usuario: $e');

    } finally {
      _profileLoading = false;
      notifyListeners();
    }
  }

  int indexOfCountry(Country country) {
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