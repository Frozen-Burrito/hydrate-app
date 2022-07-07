import 'dart:math';

import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/environment.dart';

import 'country.dart';
import 'medical_data.dart';

class UserProfile extends SQLiteModel {

  final int _id;
  String _firstName;
  String _lastName;
  DateTime? _birthDate;
  UserSex _sex;
  double _height;
  double _weight;
  MedicalCondition _medicalCondition;
  Occupation _occupation;
  Country _country;
  String _userAccountID;
  int _coins;
  int _modificationCount;
  int _selectedEnvId;
  final List<Environment> _unlockedEnvironments;

  final bool isReadonly;

  static const defaultProfileId = 0;
  static const maxCoins = 9999;

  UserProfile.unmodifiable(
    this._id,
    this._firstName,
    this._lastName,
    this. _birthDate,
    this._sex,
    this._height,
    this._weight,
    this._medicalCondition,
    this._occupation,
    this._userAccountID,
    this._coins,
    this._modificationCount,
    this._selectedEnvId,
    this._country,
    this._unlockedEnvironments,
  ): isReadonly = true;

  UserProfile.uncommited(Country defaultCountry, Environment defaultEnv, String userAccountId) 
  : this.unmodifiable(
    -1, '', '', null, UserSex.notSpecified, 0.0, 0.0, 
    MedicalCondition.notSpecified, Occupation.notSpecified, userAccountId, 0, 0, 0, 
    defaultCountry, <Environment>[ defaultEnv ],
  );

  UserProfile.modifiableCopyOf(UserProfile other)
    : isReadonly = false,
      _id = other._id ,
      _firstName = other._firstName ,
      _lastName = other._lastName ,
      _birthDate = other._birthDate ,
      _sex = other._sex ,
      _height = other._height ,
      _weight = other._weight ,
      _medicalCondition = other._medicalCondition ,
      _occupation = other._occupation ,
      _userAccountID = other._userAccountID ,
      _coins = other._coins ,
      _modificationCount = other._modificationCount ,
      _selectedEnvId = other._selectedEnvId ,
      _country = other._country ,
      _unlockedEnvironments = List.from(other._unlockedEnvironments);

  static const String tableName = 'perfil';

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      id ${SQLiteKeywords.idType},
      nombre ${SQLiteKeywords.textType},
      apellido ${SQLiteKeywords.textType},
      fecha_nacimiento ${SQLiteKeywords.textType},
      sexo ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      estatura ${SQLiteKeywords.realType},
      peso ${SQLiteKeywords.realType}, 
      padecimientos ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      ocupacion ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      entorno_sel ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      monedas ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      num_modificaciones ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      id_usuario ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      id_pais ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},

      ${SQLiteKeywords.fk} (id_pais) ${SQLiteKeywords.references} pais (id)
        ${SQLiteKeywords.onDelete} ${SQLiteKeywords.setNullAction}
    )
  ''';

  static UserProfile fromMap(Map<String, Object?> map) {
    
    final country = Country.fromMap(
      (map['pais'] is Map<String, Object?>) 
        ? map['pais'] as Map<String, Object?> 
        : {}
    );

    final idxUserSex = min(map['sexo'] as int, UserSex.values.length -1);
    final idxOccupation = min(map['ocupacion'] as int, Occupation.values.length -1);
    final idxMedicalCondition = min(map['padecimientos'] as int, MedicalCondition.values.length -1);

    var environments = map['entornos'];
    List<Environment> envList = <Environment>[];

    if (environments is List<Map<String, Object?>> && environments.isNotEmpty) {
      envList = environments.map((environment) => Environment.fromMap(environment)).toList();
    }

    return UserProfile.unmodifiable(
      int.tryParse(map['id'].toString()) ?? -1,
      map['nombre'].toString(),
      map['apellido'].toString(),
      DateTime.tryParse(map['fecha_nacimiento'].toString()),
      UserSex.values[idxUserSex],
      double.tryParse(map['estatura'].toString()) ?? 0.0,
      double.tryParse(map['peso'].toString()) ?? 0.0,
      MedicalCondition.values[int.tryParse(idxMedicalCondition.toString()) ?? 0],
      Occupation.values[idxOccupation],
      map['id_usuario'].toString(),
      int.tryParse(map['entorno_sel'].toString()) ?? 0,
      int.tryParse(map['monedas'].toString()) ?? 0,
      int.tryParse(map['num_modificaciones'].toString()) ?? 0,
      country,
      envList
    );
  } 

  @override
  Map<String, Object?> toMap() {
    final Map<String, Object?> map = {
      'nombre': firstName,
      'apellido': lastName,
      'fecha_nacimiento': birthDate?.toIso8601String() ?? '',
      'sexo': sex.index,
      'estatura': height,
      'peso': weight,
      'padecimientos': medicalCondition.index,
      'ocupacion': occupation.index,
      'id_usuario': userAccountID,
      'entorno_sel': selectedEnvId,
      'monedas': coins,
      'num_modificaciones': modificationCount,
      'pais': country,
      'entornos': unlockedEnvironments
    };

    if (id >= 0) map['id'] = id;

    return map;
  }

  int get id => _id;
  String get firstName => _firstName;
  String get lastName => _lastName;
  DateTime? get birthDate => _birthDate;
  UserSex get sex => _sex;
  double get height => _height;
  double get weight => _weight;
  MedicalCondition get medicalCondition => _medicalCondition;
  Occupation get occupation => _occupation;
  Country get country => _country;
  String get userAccountID => _userAccountID;
  int get coins => _coins;
  int get modificationCount => _modificationCount;
  int get selectedEnvId => _selectedEnvId;
  List<Environment> get unlockedEnvironments => isReadonly
    ? List.unmodifiable( _unlockedEnvironments)
    : _unlockedEnvironments;

  // Setters, solo si este [UserProfile] no [isReadonly].
  set firstName(String newFirstName)  => isReadonly ? null : _firstName = newFirstName;
  set lastName(String newLastName) => isReadonly ? null : _lastName = newLastName;
  set birthDate(DateTime? newBirthDate) => isReadonly ? null : _birthDate = newBirthDate;
  set sex(UserSex newSex) => isReadonly ? null : _sex = newSex;
  set height(double newHeight) => isReadonly ? null : _height = newHeight;
  set weight(double newWeight) => isReadonly ? null : _weight = newWeight;
  set medicalCondition(MedicalCondition newCondition) => isReadonly ? null : _medicalCondition = newCondition;
  set occupation(Occupation newOccupation) => isReadonly ? null : _occupation = newOccupation;
  set country(Country newCountry) => isReadonly ? null : _country = newCountry;
  set userAccountID(String newAccountId) => isReadonly ? null : _userAccountID = newAccountId;
  set selectedEnvId(int newSelectedEnvId) => isReadonly ? null : _selectedEnvId = newSelectedEnvId;

  Environment get selectedEnvironment => unlockedEnvironments.isNotEmpty
      ? unlockedEnvironments.firstWhere((env) => env.id == selectedEnvId)
      : Environment.uncommited();

  bool hasUnlockedEnv(int envId) => unlockedEnvironments
      .where((e) => e.id == envId).isNotEmpty;

  String get fullName => '$firstName $lastName';

  /// Obtiene las iniciales del usuario, en mayúsculas.
  String get initials {
    String firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '-';
    String lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '-';
    
    return firstInitial + lastInitial;
  }

  /// Modifica el número de monedas del perfil, incrementándolo si [amount] es 
  /// positivo o reduciéndolo si [amount] es negativo.
  /// 
  /// El valor absoluto de las monedas del perfil después de la operación debe 
  /// ser estar en el rango (0..[maxCoins]). Si no es así, este método produce 
  /// un [RangeError].
  void giveOrTakeCoins(int amount) {

    int newCoinCount = coins + amount;

    if (newCoinCount.abs() > maxCoins) {
      throw RangeError.range(newCoinCount, 0, maxCoins, 'amount');
    }

    _coins = amount;
  }

  /// Registra una modificación a los datos sensibles de [UserProfile].
  /// Debería ser invocado cada vez que se guardan cambios para el perfil.
  void recordModification() {
    _modificationCount++;
  }

  @override
  bool operator ==(Object? other) {

    if (other is! UserProfile) {
      return false;
    } 

    final otherProfile = other;

    final isIdEqual = id == otherProfile.id;
    final isNameEqual = fullName == otherProfile.fullName;
    final isBirthDateEqual = birthDate?.isAtSameMomentAs(otherProfile.birthDate ?? DateTime.now()) ?? false;
    final areFeaturesEqual = sex == otherProfile.sex &&
      medicalCondition == otherProfile.medicalCondition &&
      occupation == otherProfile.occupation;
    final isWeightEqual = (weight - otherProfile.weight).abs() < 0.001;
    final isHeightEqual = (height - otherProfile.height).abs() < 0.001;
    final isAccountEqual = userAccountID == otherProfile.userAccountID;
    final areCoinsEqual = coins == otherProfile.coins;
    final isSelectedEnvEqual = selectedEnvId == otherProfile.selectedEnvId;
    final isCountryEqual = country == otherProfile.country;
    final areUnlockedEnvsEqual = unlockedEnvironments.length == otherProfile.unlockedEnvironments.length;

    return isIdEqual && isNameEqual && isBirthDateEqual && areFeaturesEqual
      && isWeightEqual && isHeightEqual && isAccountEqual && areCoinsEqual
      && isSelectedEnvEqual && isCountryEqual && areUnlockedEnvsEqual;
  }

  @override
  int get hashCode => Object.hashAll([ 
    id, firstName, lastName, birthDate, sex, height, weight, 
    medicalCondition, occupation, userAccountID, selectedEnvId, 
    coins, modificationCount, country, unlockedEnvironments 
  ]);

  /// Verifica que [inputName] sea un string con longitud menor a 50.
  static String? validateFirstName(String? inputName) {

    if (inputName == null) return null;

    return (inputName.length >= 50)
        ? 'El nombre debe tener menos de 50 caracteres.'
        : null;
  }

  /// Verifica que [inputName] sea un string con longitud menor a 50.
  static String? validateLastName(String? inputLastName) {

    if (inputLastName == null) return null;

    return (inputLastName.length >= 50)
        ? 'El apellido debe tener menos de 50 caracteres.'
        : null;
  }

  /// Verifica que [inputHeight] pueda convertirse a número decimal y esté en el
  /// rango requerido.
  static String? validateHeight(String? inputHeight) {

    double heightValue = double.tryParse(inputHeight ?? '0.0') ?? 0.0;

    return (heightValue < 0.5 || heightValue > 3.5)
        ? 'La estatura debe estar entre 0.5m y 3.5m'
        : null;
  }

  /// Verifica que [inputWeight] pueda convertirse a número decimal y esté en el
  /// rango requerido.
  static String? validateWeight(String? inputWeight) {
    
    double weightValue = double.tryParse(inputWeight ?? '0.0') ?? 0.0;

    return (weightValue < 20 || weightValue > 200) 
        ? 'El peso debe estar entre 20 kg y 200 kg'
        : null; 
  }
}

enum UserSex {
  woman,
  man,
  notSpecified,
}

enum Occupation {
  notSpecified,
  student,
  officeWorker,
  manualWorker,
  parent,
  athlete,
  other
}
