import 'dart:math';

import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/country.dart';
import 'package:hydrate_app/src/models/enums/occupation_type.dart';
import 'package:hydrate_app/src/models/enums/user_sex.dart';
import 'package:hydrate_app/src/models/environment.dart';
import 'package:hydrate_app/src/models/map_options.dart';
import 'package:hydrate_app/src/models/medical_data.dart';

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

  static const maxFirstNameLength = 64;
  static const maxLastNameLength = 64;

  static final defaultProfile = UserProfile.uncommitted(); 

  UserProfile.unmodifiable({
    int id = -1,
    String firstName = "",
    String lastName = "",
    DateTime? birthDate,
    UserSex sex = UserSex.notSpecified,
    double height = 0.0,
    double weight = 0.0,
    MedicalCondition medicalCondition = MedicalCondition.notSpecified,
    Occupation occupation = Occupation.notSpecified,
    String userAccountID = "",
    int coins = 0,
    int modificationCount = 0,
    int selectedEnvId = 0,
    Country? country,
    List<Environment> unlockedEnvironments = const <Environment>[]
  }): isReadonly = true,
      _id = id,
      _firstName = firstName,
      _lastName = lastName,
      _birthDate = birthDate ?? DateTime.now(),
      _sex = sex,
      _height = height,
      _weight = weight,
      _medicalCondition = medicalCondition,
      _occupation = occupation,
      _userAccountID = userAccountID,
      _coins = coins,
      _modificationCount = modificationCount,
      _selectedEnvId = selectedEnvId,
      _country = country ?? Country.countryNotSpecified,
      _unlockedEnvironments = <Environment>[] {

        if (unlockedEnvironments.isEmpty) {
          _unlockedEnvironments.add(Environment.firstUnlocked());
        } else {
           _unlockedEnvironments.addAll(unlockedEnvironments);
        }

        _selectedEnvId = !hasUnlockedEnv(selectedEnvId)
          ? Environment.firstUnlockedId
          : selectedEnvId;
      }

  UserProfile.uncommitted() 
  : this.unmodifiable(id: -1,);

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

  static const String tableName = "perfil";

  static const String idFieldName = "id";
  static const String firstNameFieldName = "nombre";
  static const String lastNameFieldName = "apellido";
  static const String birthDateFieldName = "fecha_nacimiento";
  static const String sexFieldName = "sexo";
  static const String heightFieldName = "estatura";
  static const String weightFieldName = "peso";
  static const String medicalConditionFieldName = "padecimientos";
  static const String occupationFieldName = "ocupacion";
  static const String userAccountIdFieldName = "id_usuario";
  static const String coinsFieldName = "monedas";
  static const String modificationCountFieldName = "num_modificaciones";
  static const String selectedEnvFieldName = "entorno_sel";
  static const String countryFieldName = "id_pais";
  static const String unlockedEnvsFieldName = "entornos";

  /// Una lista con todos los nombres base de los atributos de la entidad.
  static const baseAttributeNames = <String>[
    idFieldName,
    firstNameFieldName,
    lastNameFieldName,
    birthDateFieldName,
    sexFieldName,
    heightFieldName,
    weightFieldName,
    medicalConditionFieldName,
    occupationFieldName,
    userAccountIdFieldName,
    coinsFieldName,
    modificationCountFieldName,
    selectedEnvFieldName,
    countryFieldName,
    unlockedEnvsFieldName,
  ];

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

    //TODO: considerar validar ciertos campos (especialmente que 'entornos' y 
    // 'entorno_sel' coincidan, además de revisar el valor de 'pais').
    
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
      id: int.tryParse(map['id'].toString()) ?? -1,
      firstName: map['nombre'].toString(),
      lastName: map['apellido'].toString(),
      birthDate: DateTime.tryParse(map['fecha_nacimiento'].toString()),
      sex: UserSex.values[idxUserSex],
      height: double.tryParse(map['estatura'].toString()) ?? 0.0,
      weight: double.tryParse(map['peso'].toString()) ?? 0.0,
      medicalCondition: MedicalCondition.values[int.tryParse(idxMedicalCondition.toString()) ?? 0],
      occupation: Occupation.values[idxOccupation],
      userAccountID: map['id_usuario'].toString(),
      selectedEnvId: int.tryParse(map['entorno_sel'].toString()) ?? 0,
      coins: int.tryParse(map['monedas'].toString()) ?? 0,
      modificationCount: int.tryParse(map['num_modificaciones'].toString()) ?? 0,
      country: country,
      unlockedEnvironments: envList
    );
  } 

  @override
  Map<String, Object?> toMap({ MapOptions options = const MapOptions(), }) {

    assert(
      unlockedEnvironments.where((env) => env.id == selectedEnvId).length == 1,
      "No hay un entorno de unlockedEnvironments con el selectedEnvId"
    );

    // Modificar los nombres de los atributos para el Map resultante, segun 
    // [options].
    final attributeNames = MapOptions.mapAttributeNames(baseAttributeNames, options);

    // Comprobar que hay una entrada por cada atributo de ActivityRecord.
    assert(attributeNames.length == baseAttributeNames.length);

    final Map<String, Object?> map = {};

    if (id >= 0) map[attributeNames[idFieldName]!] = id;

    map.addAll({
      attributeNames[firstNameFieldName]!: firstName,
      attributeNames[lastNameFieldName]!: lastName,
      attributeNames[birthDateFieldName]!: birthDate?.toIso8601String() ?? '',
      attributeNames[sexFieldName]!: sex.index,
      attributeNames[heightFieldName]!: height,
      attributeNames[weightFieldName]!: weight,
      attributeNames[medicalConditionFieldName]!: medicalCondition.index,
      attributeNames[occupationFieldName]!: occupation.index,
      userAccountIdFieldName: userAccountID,
      attributeNames[selectedEnvFieldName]!: selectedEnvId,
      attributeNames[coinsFieldName]!: coins,
      attributeNames[modificationCountFieldName]!: modificationCount,
    });

    if (options.includeCompleteSubEntities) {
      // Incluir mapas (no objetos en sí) de entidades anidadas.
      map[attributeNames[countryFieldName]!] = country;
      map[attributeNames[unlockedEnvsFieldName]!] = unlockedEnvironments;
    } else {
      // Incluir mapas (no objetos en sí) de entidades anidadas.
      map[attributeNames[countryFieldName]!] = country.id;
      map[attributeNames[unlockedEnvsFieldName]!] = unlockedEnvironments
          .map((env) => env.id)
          .toList();
    }

    return Map.unmodifiable(map);
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

  /// Revisa si este perfil tiene un [Environment] con un [id] equivalente a 
  /// [selectedEnvId] en su colección de [unlockedEnvironments]. Luego, retorna 
  /// el entorno seleccionado o retorna un [Environment.firstUnlocked] si el 
  /// perfil no ha desbloqueado el entorno.
  Environment get selectedEnvironment {

    final hasSelectedEnv = hasUnlockedEnv(selectedEnvId);

    return (hasSelectedEnv)
      ? unlockedEnvironments.singleWhere(
        (env) => env.id == selectedEnvId, 
        orElse: () => Environment.firstUnlocked()
      )
      : Environment.firstUnlocked();
  }

  // Retorna **true** si este perfil tiene datos por default y no ha sido 
  // modificado.
  bool get isDefaultProfile {
    final hasUncommittedId = id < defaultProfileId;
    final isNotLinkedToAccount = userAccountID.isEmpty;
    final hasNoModifications = modificationCount == 0;

    return hasUncommittedId && isNotLinkedToAccount && hasNoModifications;
  }

  /// Determina si este perfil de usuario ha desbloqueado el entorno con [envId].
  /// 
  /// Retorna **false** si este perfil no ha desbloqueado ningún entorno con 
  /// [envId], o si ha desbloqueado más de 1.  
  bool hasUnlockedEnv(int envId) => unlockedEnvironments
      .where((e) => e.id == envId).length == 1;

  bool get hasRenalInsufficiency => medicalCondition == MedicalCondition.renalInsufficiency;

  bool get hasNephroticSyndrome => medicalCondition == MedicalCondition.nephroticSyndrome;

  String get fullName => '$_firstName $_lastName';

  /// Obtiene las iniciales del usuario, en mayúsculas.
  String get initials {
    String firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '-';
    String lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '-';
    
    return firstInitial + lastInitial;
  }

  /// Modifica el número de monedas del perfil, incrementándolo por [amount] 
  /// monedas.
  /// 
  /// Después de invocar este método, la cantidad total de monedas del perfil 
  /// será igual a _cantidad previa de monedas_ + _[amount.abs()]_, o a 
  /// [maxCoins] si la suma anterior sobrepasa el rango: 
  /// 
  /// monedas <= [maxCoins]
  void addCoins(int amount) {
    _coins = min(maxCoins, _coins + amount.abs());
  }

  /// Modifica el número de monedas del perfil, decrementándolo por [amount]
  /// monedas. 
  /// 
  /// Si [amount] es mayor que el número, la cantidad de monedas del 
  /// perfil no es modificada y este método retorna **false**.
  bool spendCoins(int amount) {

    final hasEnoughCoins = _coins >= amount;

    if (hasEnoughCoins) _coins -= amount.abs();

    return hasEnoughCoins;
  }

  /// Registra una modificación a los datos sensibles de [UserProfile].
  /// Debería ser invocado cada vez que se guardan cambios para el perfil.
  void recordModification() {
    _modificationCount++;
  }

  @override
  String toString() => "$_firstName $_lastName's profile, ID = $_id";

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
