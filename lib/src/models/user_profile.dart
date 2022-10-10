import 'dart:math';

import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/country.dart';
import 'package:hydrate_app/src/models/enums/occupation_type.dart';
import 'package:hydrate_app/src/models/enums/user_sex.dart';
import 'package:hydrate_app/src/models/environment.dart';
import 'package:hydrate_app/src/models/map_options.dart';
import 'package:hydrate_app/src/models/medical_data.dart';
import 'package:hydrate_app/src/utils/numbers_common.dart';

class UserProfile extends SQLiteModel {

  int _id;
  String _firstName;
  String _lastName;
  DateTime? _dateOfBirth;
  UserSex _sex;
  double _height;
  double _weight;
  MedicalCondition _medicalCondition;
  Occupation _occupation;
  Country _country;
  String _userAccountID;
  int _linkedProfileId;
  final DateTime _createdAt;
  DateTime? _modifiedAt;
  DateTime? _latestSyncWithGoogleFit;
  int _coins;
  int _modificationCount;
  Environment _selectedEnvironment;
  final List<Environment> _unlockedEnvironments;

  final bool isReadonly;

  static const defaultProfileId = 1;
  static const maxCoins = 9999;

  static const maxFirstNameLength = 64;
  static const maxLastNameLength = 64;

  static const maxFirstNameDisplayLength = 64;
  static const maxLastNameDisplayLength = 64;

  static final defaultProfile = UserProfile.unmodifiable(
    id: defaultProfileId,
    userAccountID: "",
  ); 

  UserProfile.unmodifiable({
    int id = -1,
    String firstName = "",
    String lastName = "",
    DateTime? dateOfBirth,
    UserSex sex = UserSex.notSpecified,
    double height = 0.0,
    double weight = 0.0,
    MedicalCondition medicalCondition = MedicalCondition.notSpecified,
    Occupation occupation = Occupation.notSpecified,
    String userAccountID = "",
    int? linkedProfileId,
    int coins = 0,
    int modificationCount = 0,
    DateTime? createdAt,
    DateTime? modifiedAt,
    DateTime? latestSyncWithGoogleFit,
    Environment? selectedEnvironment,
    Country? country,
    List<Environment> unlockedEnvironments = const <Environment>[]
  }): isReadonly = true,
      _id = id,
      _firstName = firstName,
      _lastName = lastName,
      _dateOfBirth = dateOfBirth,
      _sex = sex,
      _height = height,
      _weight = weight,
      _medicalCondition = medicalCondition,
      _occupation = occupation,
      _userAccountID = userAccountID,
      _linkedProfileId = linkedProfileId ?? id,
      _coins = coins,
      _modificationCount = modificationCount,
      _createdAt = createdAt ?? DateTime.now(),
      _modifiedAt = modifiedAt,
      _latestSyncWithGoogleFit = latestSyncWithGoogleFit,
      _country = country ?? Country.countryNotSpecified,
      _selectedEnvironment = selectedEnvironment ?? Environment.firstUnlocked(),
      _unlockedEnvironments = <Environment>[] {

        if (unlockedEnvironments.isEmpty) {
          _unlockedEnvironments.add(Environment.firstUnlocked());
        } else {
           _unlockedEnvironments.addAll(unlockedEnvironments);
        }
      }

  UserProfile.uncommitted() 
  : this.unmodifiable(id: -1,);

  UserProfile.modifiableCopyOf(UserProfile other)
    : isReadonly = false,
      _id = other._id,
      _firstName = other._firstName,
      _lastName = other._lastName,
      _dateOfBirth = other._dateOfBirth,
      _sex = other._sex,
      _height = other._height,
      _weight = other._weight,
      _medicalCondition = other._medicalCondition,
      _occupation = other._occupation,
      _userAccountID = other._userAccountID,
      _linkedProfileId = other._linkedProfileId,
      _coins = other._coins,
      _modificationCount = other._modificationCount,
      _createdAt = other._createdAt,
      _modifiedAt = other._modifiedAt,
      _latestSyncWithGoogleFit = other._latestSyncWithGoogleFit,
      _selectedEnvironment = other._selectedEnvironment,
      _country = other._country ,
      _unlockedEnvironments = List.from(other._unlockedEnvironments);

  static const String tableName = "perfil";

  static const String idFieldName = "id";
  static const String firstNameFieldName = "nombre";
  static const String lastNameFieldName = "apellido";
  static const String dateOfBirthFieldName = "fecha_nacimiento";
  static const String sexFieldName = "sexo";
  static const String heightFieldName = "estatura";
  static const String weightFieldName = "peso";
  static const String medicalConditionFieldName = "padecimientos";
  static const String occupationFieldName = "ocupacion";
  static const String userAccountIdFieldName = "id_usuario";
  static const String linkedProfileIdFieldName = "id_perfil_asociado";
  static const String coinsFieldName = "monedas";
  static const String modificationCountFieldName = "num_modificaciones";
  static const String selectedEnvFieldName = "entorno_sel";
  static const String countryFieldName = "id_pais";
  static const String unlockedEnvsFieldName = "entornos";
  static const String createdAtFieldName = "fecha_creacion";
  static const String modifiedAtFieldName = "fecha_modificacion";
  static const String latestSyncWithGoogleFitFieldName = "fecha_sync_con_google_fit";

  /// Una lista con todos los nombres base de los atributos de la entidad.
  static const baseAttributeNames = <String>[
    idFieldName,
    firstNameFieldName,
    lastNameFieldName,
    dateOfBirthFieldName,
    sexFieldName,
    heightFieldName,
    weightFieldName,
    medicalConditionFieldName,
    occupationFieldName,
    userAccountIdFieldName,
    linkedProfileIdFieldName,
    coinsFieldName,
    modificationCountFieldName,
    createdAtFieldName,
    modifiedAtFieldName,
    latestSyncWithGoogleFitFieldName,
    selectedEnvFieldName,
    countryFieldName,
    unlockedEnvsFieldName,
  ];

  static const Map<String, String> jsonApiAttributeNames = <String, String>{
    sexFieldName: "sexoUsuario",
    medicalConditionFieldName: "condicionMedica",
    userAccountIdFieldName: "idCuentaUsuario",
    coinsFieldName: "cantidadMonedas",
    selectedEnvFieldName: "idEntornoSeleccionado",
    countryFieldName: "idPaisDeResidencia",
    unlockedEnvsFieldName: "idsEntornosDesbloqueados",
  };

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      $idFieldName ${SQLiteKeywords.idType},
      $firstNameFieldName ${SQLiteKeywords.textType},
      $lastNameFieldName ${SQLiteKeywords.textType},
      $dateOfBirthFieldName ${SQLiteKeywords.textType},
      $sexFieldName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      $heightFieldName ${SQLiteKeywords.realType},
      $weightFieldName ${SQLiteKeywords.realType}, 
      $medicalConditionFieldName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      $occupationFieldName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      $selectedEnvFieldName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      $coinsFieldName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      $modificationCountFieldName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      $createdAtFieldName ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      $modifiedAtFieldName ${SQLiteKeywords.textType},
      $latestSyncWithGoogleFitFieldName ${SQLiteKeywords.textType},
      $userAccountIdFieldName ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      $linkedProfileIdFieldName ${SQLiteKeywords.integerType},
      $countryFieldName ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},

      ${SQLiteKeywords.fk} (id_pais) ${SQLiteKeywords.references} pais (id)
        ${SQLiteKeywords.onDelete} ${SQLiteKeywords.setNullAction}
    )
  ''';

  static UserProfile fromMap(Map<String, Object?> map, { MapOptions options = const MapOptions(),}) {

    final bool obtainedFromJson = options.useCamelCasePropNames;
    // Modificar los nombres de los atributos que serán usados para acceder
    // a los elementos del mapa, según la configuración de [options].
    final attributeNames = options.mapAttributeNames(
      baseAttributeNames, 
      specificAttributeMappings: obtainedFromJson 
        ? jsonApiAttributeNames 
        : {
          userAccountIdFieldName: userAccountIdFieldName,
          linkedProfileIdFieldName: linkedProfileIdFieldName,
        }
    );
    
    final Country country = map.getCountryOrDefault(
      attributeName: attributeNames[countryFieldName]!,
      mappingType: options.subEntityMappingType,
    );

    final userSexIndex = map.getEnumIndex(
      attributeName: attributeNames[sexFieldName]!,
      enumValuesLength: UserSex.values.length,
    );

    final occupationIndex = map.getEnumIndex(
      attributeName: attributeNames[occupationFieldName]!,
      enumValuesLength: Occupation.values.length,
    );

    final medicalConditionIndex = map.getEnumIndex(
      attributeName: attributeNames[medicalConditionFieldName]!,
      enumValuesLength: MedicalCondition.values.length,
    );

    final unlockedEnvironments = map.getUnlockedEnvironmentsOrDefault(
      attributeName: attributeNames[unlockedEnvsFieldName]!,
      existingEnvironments: []
    );

    final selectedEnvIdAttributeValue = map[attributeNames[selectedEnvFieldName]].toString();
    final int selectedEnvironmentId = int.tryParse(selectedEnvIdAttributeValue) ?? Environment.firstUnlockedId;

    final int profileId = int.tryParse(map[attributeNames[idFieldName]].toString()) ?? -1;
    final int? linkedProfileId = int.tryParse(map[attributeNames[linkedProfileIdFieldName]].toString());

    return UserProfile.unmodifiable(
      id: profileId,
      firstName: map[attributeNames[firstNameFieldName]].toString(),
      lastName: map[attributeNames[lastNameFieldName]].toString(),
      dateOfBirth: map.getDateTimeOrDefault(attributeName: attributeNames[dateOfBirthFieldName]!),
      sex: UserSex.values[userSexIndex],
      height: double.tryParse(map[attributeNames[heightFieldName]].toString()) ?? 0.0,
      weight: double.tryParse(map[attributeNames[weightFieldName]].toString()) ?? 0.0,
      medicalCondition: MedicalCondition.values[medicalConditionIndex],
      occupation: Occupation.values[occupationIndex],
      userAccountID: map[attributeNames[userAccountIdFieldName]]?.toString() ?? "",
      linkedProfileId: linkedProfileId,
      selectedEnvironment: unlockedEnvironments.where((env) => env.id == selectedEnvironmentId).first,
      coins: int.tryParse(map[attributeNames[coinsFieldName]].toString()) ?? 0,
      modificationCount: int.tryParse(map[attributeNames[modificationCountFieldName]].toString()) ?? 0,
      country: country,
      unlockedEnvironments: unlockedEnvironments,
      createdAt: map.getDateTimeOrDefault(attributeName: attributeNames[createdAtFieldName]!),
      modifiedAt: map.getDateTimeOrDefault(attributeName: attributeNames[modifiedAtFieldName]!),
      latestSyncWithGoogleFit: map.getDateTimeOrDefault(attributeName: attributeNames[latestSyncWithGoogleFitFieldName]!),
    );
  } 

  @override
  Map<String, Object?> toMap({ MapOptions options = const MapOptions(), }) {

    assert(
      unlockedEnvironments.where((env) => env.id == _selectedEnvironment.id).length == 1,
      "No hay un entorno de unlockedEnvironments con el selectedEnvId"
    );

    // Modificar los nombres de los atributos para el Map resultante, segun 
    // [options].
    final attributeNames = options.mapAttributeNames(
      baseAttributeNames, 
      specificAttributeMappings: options.useCamelCasePropNames ? jsonApiAttributeNames : {
        userAccountIdFieldName: userAccountIdFieldName,
        linkedProfileIdFieldName: linkedProfileIdFieldName,
      }
    );

    // Comprobar que hay una entrada por cada atributo de ActivityRecord.
    assert(attributeNames.length == baseAttributeNames.length);

    final Map<String, Object?> map = {};

    if (id >= 0) {
      map[attributeNames[idFieldName]!] = id;
    }

    if (!options.useCamelCasePropNames && hasSpecificLinkedProfileId) {
      map[attributeNames[linkedProfileIdFieldName]!] = linkedProfileId;
    } 

    map.addAll({
      attributeNames[firstNameFieldName]!: _firstName,
      attributeNames[lastNameFieldName]!: _lastName,
      attributeNames[dateOfBirthFieldName]!: _dateOfBirth?.toIso8601String() ?? '',
      attributeNames[sexFieldName]!: _sex.index,
      attributeNames[heightFieldName]!: _height,
      attributeNames[weightFieldName]!: _weight,
      attributeNames[medicalConditionFieldName]!: _medicalCondition.index,
      attributeNames[occupationFieldName]!: _occupation.index,
      attributeNames[userAccountIdFieldName]!: _userAccountID,
      attributeNames[selectedEnvFieldName]!: _selectedEnvironment.id,
      attributeNames[coinsFieldName]!: _coins,
      attributeNames[modificationCountFieldName]!: _modificationCount,
      attributeNames[createdAtFieldName]!: _createdAt.toIso8601String(),
      attributeNames[modifiedAtFieldName]!: _modifiedAt?.toIso8601String(),
      attributeNames[latestSyncWithGoogleFitFieldName]!: _latestSyncWithGoogleFit?.toIso8601String(),
    });

    switch (options.subEntityMappingType) {
      case EntityMappingType.noMapping:
        map[attributeNames[countryFieldName]!] = _country;
        map[attributeNames[unlockedEnvsFieldName]!] = _unlockedEnvironments;
        break;
      case EntityMappingType.asMap:
        map[attributeNames[countryFieldName]!] = _country.toMap(options: options);
        map[attributeNames[unlockedEnvsFieldName]!] = _unlockedEnvironments
          .map((environment) => environment.toMap(options: options))
          .toList();
        break;
      case EntityMappingType.idOnly:
        map[attributeNames[countryFieldName]!] = _country.id;
        map[attributeNames[unlockedEnvsFieldName]!] = _unlockedEnvironments
            .map((env) => env.id)
            .toList();
        break;
      case EntityMappingType.notIncluded:
        break;
    }

    return Map.unmodifiable(map);
  }

  int get id => _id;
  String get firstName => _firstName;
  String get lastName => _lastName;
  DateTime? get dateOfBirth => _dateOfBirth;
  UserSex get sex => _sex;
  double get height => _height;
  double get weight => _weight;
  MedicalCondition get medicalCondition => _medicalCondition;
  Occupation get occupation => _occupation;
  Country get country => _country;
  String get userAccountID => _userAccountID;
  int get linkedProfileId => _linkedProfileId;
  int get coins => _coins;
  int get modificationCount => _modificationCount;
  DateTime get createdAt => _createdAt;
  DateTime? get modifiedAt => _modifiedAt;
  DateTime? get latestSyncWithGoogleFit => _latestSyncWithGoogleFit;
  List<Environment> get unlockedEnvironments => isReadonly
    ? List.unmodifiable( _unlockedEnvironments)
    : _unlockedEnvironments;

  // Setters, solo si este [UserProfile] no [isReadonly].
  set id(int newId)  => isReadonly ? null : _id = newId;
  set firstName(String newFirstName)  => isReadonly ? null : _firstName = newFirstName;
  set lastName(String newLastName) => isReadonly ? null : _lastName = newLastName;
  set dateOfBirth(DateTime? newBirthDate) => isReadonly ? null : _dateOfBirth = newBirthDate;
  set sex(UserSex newSex) => isReadonly ? null : _sex = newSex;
  set height(double newHeight) => isReadonly ? null : _height = newHeight;
  set weight(double newWeight) => isReadonly ? null : _weight = newWeight;
  set medicalCondition(MedicalCondition newCondition) => isReadonly ? null : _medicalCondition = newCondition;
  set occupation(Occupation newOccupation) => isReadonly ? null : _occupation = newOccupation;
  set country(Country newCountry) => isReadonly ? null : _country = newCountry;
  set userAccountID(String newAccountId) => isReadonly ? null : _userAccountID = newAccountId;
  set linkedProfileId(int newLinkedProfileId) => isReadonly ? null : _linkedProfileId = newLinkedProfileId;
  set modifiedAt(DateTime? newModifiedAt) => isReadonly ? null : _modifiedAt = newModifiedAt;
  set latestSyncWithGoogleFit(DateTime? newLatestSyncWithGoogleFit) => isReadonly ? null : _latestSyncWithGoogleFit = newLatestSyncWithGoogleFit;
  set selectedEnvironment(Environment newSelectedEnv) {
    if (!isReadonly) {
      _selectedEnvironment = newSelectedEnv;
    }
  }

  /// Revisa si este perfil tiene un [Environment] con un [id] equivalente a 
  /// [selectedEnvId] en su colección de [unlockedEnvironments]. Luego, retorna 
  /// el entorno seleccionado o retorna un [Environment.firstUnlocked] si el 
  /// perfil no ha desbloqueado el entorno.
  Environment get selectedEnvironment {

    if (isReadonly) {
      final hasSelectedEnv = hasUnlockedEnv(_selectedEnvironment.id);

      return (hasSelectedEnv)
        ? unlockedEnvironments.singleWhere(
          (env) => env.id == _selectedEnvironment.id, 
          orElse: () => Environment.firstUnlocked()
        )
        : Environment.firstUnlocked();
    } else {
      return _selectedEnvironment;
    }
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

  bool get isLinkedToAccount => _userAccountID.isNotEmpty;

  bool get hasSpecificLinkedProfileId => _id != _linkedProfileId && _linkedProfileId > 0;

  bool get hasRenalInsufficiency => medicalCondition == MedicalCondition.renalInsufficiency;

  bool get hasNephroticSyndrome => medicalCondition == MedicalCondition.nephroticSyndrome;

  int get ageInYears => _dateOfBirth != null 
    ? DateTime.now().difference(_dateOfBirth!).inDays.abs() ~/ 365
    : 0;

  String get fullName {

    final strBuf = StringBuffer();

    if (firstName.isNotEmpty) {

      final names = firstName.split(" ");
      final maxNumberOfNames = min(names.length, 2);

      final firstNames = names.sublist(0, maxNumberOfNames).join(" ");

      strBuf.write(firstNames.substring(0, min(firstNames.length, maxFirstNameDisplayLength)));
    }

    if (lastName.isNotEmpty) {

      if (strBuf.length > 0) strBuf.write(" ");

      final lastNames = lastName.split(" ");
      final numberOfLastNames = min(lastNames.length, 2);

      final adjustedLastNames = lastNames.sublist(0, numberOfLastNames).join(" ");

      strBuf.write(adjustedLastNames.substring(0, min(adjustedLastNames.length, maxLastNameDisplayLength)));
    }

    return strBuf.toString();
  }

  // => '$_firstName $_lastName';

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

  /// Retorna __true__ si [changes] incluye cambios a alguno de los siguientes 
  /// atributos del perfil de usuario:
  /// - Nombre
  /// - Apellido
  /// - Fecha de nacimiento
  /// - Sexo
  /// - Condiciones médicas.
  /// - País
  /// - Cuenta de usuario asociada
  bool hasCriticalChanges(UserProfile changes) {

    final isNameDifferent = _firstName != changes._firstName || _lastName != changes._lastName;
    final isDateOfBirthDifferent = !(_dateOfBirth
        ?.isAtSameMomentAs(changes._dateOfBirth ?? DateTime.now()) 
        ?? changes._dateOfBirth == null);

    final isSexDifferent = _sex != changes._sex;
    final hasDifferentMedicalCondition = _medicalCondition != changes._medicalCondition;

    final isLinkedToDifferentAccount = _userAccountID.isNotEmpty && _userAccountID != changes._userAccountID;
    final isCountryDifferent = _country != changes._country;

    return isNameDifferent || isDateOfBirthDifferent || isSexDifferent || 
        hasDifferentMedicalCondition || isLinkedToDifferentAccount || isCountryDifferent;
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
    final isBirthDateEqual = dateOfBirth?.isAtSameMomentAs(otherProfile.dateOfBirth ?? DateTime.now()) ?? false;
    final areFeaturesEqual = sex == otherProfile.sex &&
      medicalCondition == otherProfile.medicalCondition &&
      occupation == otherProfile.occupation;
    final isWeightEqual = (weight - otherProfile.weight).abs() < 0.001;
    final isHeightEqual = (height - otherProfile.height).abs() < 0.001;
    final isAccountEqual = userAccountID == otherProfile.userAccountID;
    final areCoinsEqual = coins == otherProfile.coins;
    final isSelectedEnvEqual = _selectedEnvironment.id == otherProfile._selectedEnvironment.id;
    final isCountryEqual = country == otherProfile.country;
    final areUnlockedEnvsEqual = unlockedEnvironments.length == otherProfile.unlockedEnvironments.length;

    return isIdEqual && isNameEqual && isBirthDateEqual && areFeaturesEqual
      && isWeightEqual && isHeightEqual && isAccountEqual && areCoinsEqual
      && isSelectedEnvEqual && isCountryEqual && areUnlockedEnvsEqual;
  }

  @override
  int get hashCode => Object.hashAll([ 
    id, firstName, lastName, dateOfBirth, sex, height, weight, 
    medicalCondition, occupation, userAccountID, _selectedEnvironment.id, 
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

extension _UserProfileMapExtension on Map<String, Object?> {

  Country getCountryOrDefault({
    required String attributeName,
    EntityMappingType mappingType = EntityMappingType.noMapping,
    List<Country> existingCountries = const <Country>[],
  }) {
    final Country country;

    switch (mappingType) {
      
      case EntityMappingType.noMapping:
        country = (this[attributeName] as Country?) ?? Country.countryNotSpecified;
        break;
      case EntityMappingType.asMap:
        country = Country.fromMap(this[attributeName] as Map<String, Object?>);
        break;
      case EntityMappingType.idOnly:
        final int countryId = int.tryParse(this[attributeName].toString()) ?? -1;
        final countryWithId = existingCountries.where((country) => country.id == countryId);
        country = countryWithId.isNotEmpty ? countryWithId.first : Country.countryNotSpecified;
        break;
      case EntityMappingType.notIncluded:
        country = Country.countryNotSpecified;
        break;
    }

    return country;
  }

  List<Environment> getUnlockedEnvironmentsOrDefault({
    required String attributeName,
    List<Environment> existingEnvironments = const <Environment>[],
  }) {
    final List<Environment> unlockedEnvironments = <Environment>[];
    final unlockedEnvironmentsFromMap = this[attributeName];

    if (unlockedEnvironmentsFromMap is List<Map<String, Object?>>) {
      unlockedEnvironments.addAll(
        unlockedEnvironmentsFromMap.map((environment) => Environment.fromMap(environment))
        .toList()
      );
    } else if (unlockedEnvironmentsFromMap is List<int>) {
      unlockedEnvironments.addAll(
        existingEnvironments.where((environment) => unlockedEnvironmentsFromMap.contains(environment.id))
      );
    }

    if (unlockedEnvironments.isEmpty) {
      unlockedEnvironments.add(Environment.firstUnlocked());
    }

    return unlockedEnvironments;
  }

  int getEnumIndex({
    required String attributeName,
    required int enumValuesLength,
  }) 
  {

    final int parsedIndex = int.tryParse(this[attributeName].toString()) ?? 0;
    final int constrainedIndex = constrain(
      parsedIndex, 
      min: 0,
      max: enumValuesLength - 1,
    );

    return constrainedIndex;
  }

  DateTime? getDateTimeOrDefault({
    required String attributeName, 
    DateTime? defaultValue,
  }) {
    
    final parsedDateTime = DateTime.tryParse(this[attributeName].toString()) 
        ?? defaultValue;

    return parsedDateTime;
  }
}
