import 'dart:math';

import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/country.dart';
import 'package:hydrate_app/src/models/enums/occupation_type.dart';
import 'package:hydrate_app/src/models/enums/user_sex.dart';
import 'package:hydrate_app/src/models/environment.dart';
import 'package:hydrate_app/src/models/map_options.dart';
import 'package:hydrate_app/src/models/medical_data.dart';
import 'package:hydrate_app/src/models/validators/profile_validator.dart';
import 'package:hydrate_app/src/models/validators/range.dart';
import 'package:hydrate_app/src/utils/map_extensions.dart';

class UserProfile extends SQLiteModel {

  @override
  final int id;

  String firstName;
  String lastName;
  DateTime? dateOfBirth;
  UserSex sex;
  double height;
  double weight;
  MedicalCondition medicalCondition;
  Occupation occupation;
  Country country;
  String userAccountID;
  int linkedProfileId;
  final DateTime createdAt;
  DateTime? modifiedAt;
  DateTime? latestSyncWithGoogleFit;
  int coins;
  int modificationCount;
  Environment selectedEnvironment;
  final List<Environment> unlockedEnvironments;

  static const ProfileValidator validator = ProfileValidator();

  static final defaultProfile = UserProfile(
    id: 1,
    userAccountID: "",
    createdAt: DateTime.now(),
  ); 

  UserProfile({
    this.id = -1,
    this.firstName = "",
    this.lastName = "",
    this.dateOfBirth,
    this.sex = UserSex.notSpecified,
    this.height = 0.0,
    this.weight = 0.0,
    this.medicalCondition = MedicalCondition.notSpecified,
    this.occupation = Occupation.notSpecified,
    this.userAccountID = "",
    int? linkedProfileId,
    this.coins = 0,
    this.modificationCount = 0,
    required this.createdAt,
    this.modifiedAt,
    this.latestSyncWithGoogleFit,
    this.selectedEnvironment = const Environment.firstUnlocked(),
    this.country = const Country.unspecified(),
    this.unlockedEnvironments = const <Environment>[ Environment.firstUnlocked() ],
  }) 
    : linkedProfileId = linkedProfileId ?? id {

    const firstUnlocked = Environment.firstUnlocked();

    if (unlockedEnvironments.isEmpty || !unlockedEnvironments.contains(firstUnlocked)){
      unlockedEnvironments.add(firstUnlocked);
    } 
  }

  UserProfile.uncommitted() : this(
    id: -1,
    createdAt: DateTime.now(),
  );

  factory UserProfile.of(UserProfile other) => UserProfile(
    id: other.id,
    firstName: other.firstName,
    lastName: other.lastName,
    dateOfBirth: other.dateOfBirth,
    sex: other.sex,
    height: other.height,
    weight: other.weight,
    medicalCondition: other.medicalCondition,
    occupation: other.occupation,
    userAccountID: other.userAccountID,
    linkedProfileId: other.linkedProfileId,
    coins: other.coins,
    modificationCount: other.modificationCount,
    createdAt: other.createdAt,
    modifiedAt: other.modifiedAt,
    latestSyncWithGoogleFit: other.latestSyncWithGoogleFit,
    selectedEnvironment: other.selectedEnvironment,
    country: other.country,
    unlockedEnvironments: other.unlockedEnvironments,
  );

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
  static const baseAttributes = <String>[
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

  static const Map<String, String> jsonAttributes = <String, String>{
    idFieldName: "id",
    firstNameFieldName: "nombre",
    lastNameFieldName: "apellido",
    dateOfBirthFieldName: "fechaNacimiento",
    heightFieldName: "estatura",
    weightFieldName: "peso",
    occupationFieldName: "ocupacion",
    modificationCountFieldName: "numModificaciones",
    createdAtFieldName: "fechaCreacion",
    modifiedAtFieldName: "fechaModificacion",
    latestSyncWithGoogleFitFieldName: "fechaSyncConGoogleFit",
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

  static UserProfile fromMap(
    Map<String, Object?> map, { 
      MapOptions options = const MapOptions(),
      List<Country> existingCountries = const <Country>[],
      List<Environment> allEnvironments = const <Environment>[],
    }
  ) {

    final bool obtainedFromJson = options.useCamelCasePropNames;
    // Modificar los nombres de los atributos que serán usados para acceder
    // a los elementos del mapa, según la configuración de [options].
    final attributeNames = options.mapAttributeNames(
      baseAttributes, 
      specificAttributeMappings: obtainedFromJson 
        ? jsonAttributes 
        : {
          userAccountIdFieldName: userAccountIdFieldName,
          linkedProfileIdFieldName: linkedProfileIdFieldName,
          // countryFieldName: countryFieldName,
        }
    );

    final countryAttribute = (options.useCamelCasePropNames && options.subEntityMappingType == EntityMappingType.asMap) 
      ? "paisDeResidencia" 
      : attributeNames[countryFieldName]!;
    
    final country = map.getMappedEntityOrDefault<Country>(
      attribute: countryAttribute, 
      mappingType: options.subEntityMappingType,
      defaultValue: const Country.unspecified(),
    )!;

    final userSexIndex = map.getIntegerInRange(
      attribute: attributeNames[sexFieldName]!,
      range: Range( min: 0, max: UserSex.values.length ),
    );

    final occupationIndex = map.getIntegerInRange(
      attribute: attributeNames[occupationFieldName]!,
      range: Range( min: 0, max: Occupation.values.length ),
    );

    final medicalConditionIndex = map.getIntegerInRange(
      attribute: attributeNames[medicalConditionFieldName]!,
      range: Range( min: 0, max: MedicalCondition.values.length ),
    );

    final unlockedEnvironments = map.getEntityCollection(
      attribute: attributeNames[unlockedEnvsFieldName]!,
      mapper: (map, { options }) => Environment.fromMap(map, options: options ?? const MapOptions()),
      existingEntities: allEnvironments,
    );

    final selectedEnvIdAttributeValue = map[attributeNames[selectedEnvFieldName]].toString();
    final int selectedEnvironmentId = int.tryParse(selectedEnvIdAttributeValue) ?? Environment.firstUnlockedId;

    final int profileId = int.tryParse(map[attributeNames[idFieldName]].toString()) ?? -1;
    final int? linkedProfileId = int.tryParse(map[attributeNames[linkedProfileIdFieldName]].toString());

    final createdAtDate = map.getDateTimeOrDefault(
      attribute: attributeNames[createdAtFieldName]!,
      defaultValue: DateTime(2000, 1, 1)
    )!;

    final modifiedAtDate = map.getDateTimeOrDefault(attribute: attributeNames[modifiedAtFieldName]!);
    final dateOfSyncWithGoogleFit = map.getDateTimeOrDefault(attribute: attributeNames[latestSyncWithGoogleFitFieldName]!);

    return UserProfile(
      id: profileId,
      firstName: map[attributeNames[firstNameFieldName]].toString(),
      lastName: map[attributeNames[lastNameFieldName]].toString(),
      dateOfBirth: map.getDateTimeOrDefault(attribute: attributeNames[dateOfBirthFieldName]!),
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
      unlockedEnvironments: unlockedEnvironments.toList(),
      createdAt: createdAtDate,
      modifiedAt: modifiedAtDate,
      latestSyncWithGoogleFit: dateOfSyncWithGoogleFit,
    );
  } 

  @override
  Map<String, Object?> toMap({ MapOptions options = const MapOptions(), }) {

    assert(
      unlockedEnvironments.where((env) => env.id == selectedEnvironment.id).length == 1,
      "No hay un entorno de unlockedEnvironments con el selectedEnvId"
    );

    // Modificar los nombres de los atributos para el Map resultante, segun 
    // [options].
    final attributeNames = options.mapAttributeNames(
      baseAttributes, 
      specificAttributeMappings: options.useCamelCasePropNames ? jsonAttributes : {
        userAccountIdFieldName: userAccountIdFieldName,
        linkedProfileIdFieldName: linkedProfileIdFieldName,
      }
    );

    // Comprobar que hay una entrada por cada atributo de ActivityRecord.
    assert(attributeNames.length == baseAttributes.length);

    final Map<String, Object?> map = {};

    if (id >= 0) {
      map[attributeNames[idFieldName]!] = id;
    }

    if (!options.useCamelCasePropNames && hasSpecificLinkedProfileId) {
      map[attributeNames[linkedProfileIdFieldName]!] = linkedProfileId;
    } 

    map.addAll({
      attributeNames[firstNameFieldName]!: firstName,
      attributeNames[lastNameFieldName]!: lastName,
      attributeNames[dateOfBirthFieldName]!: dateOfBirth?.toIso8601String() ?? '',
      attributeNames[sexFieldName]!: sex.index,
      attributeNames[heightFieldName]!: height,
      attributeNames[weightFieldName]!: weight,
      attributeNames[medicalConditionFieldName]!: medicalCondition.index,
      attributeNames[occupationFieldName]!: occupation.index,
      attributeNames[userAccountIdFieldName]!: userAccountID,
      attributeNames[selectedEnvFieldName]!: selectedEnvironment.id,
      attributeNames[coinsFieldName]!: coins,
      attributeNames[modificationCountFieldName]!: modificationCount,
      attributeNames[createdAtFieldName]!: createdAt.toIso8601String(),
      attributeNames[modifiedAtFieldName]!: modifiedAt?.toIso8601String(),
      attributeNames[latestSyncWithGoogleFitFieldName]!: latestSyncWithGoogleFit?.toIso8601String(),
    });

    switch (options.subEntityMappingType) {
      case EntityMappingType.noMapping:
        map[attributeNames[countryFieldName]!] = country;
        map[attributeNames[unlockedEnvsFieldName]!] = unlockedEnvironments;
        break;
      case EntityMappingType.asMap:
        map[options.useCamelCasePropNames ? "paisDeResidencia" : (attributeNames[countryFieldName]!)] = country.toMap(options: options);
        map[attributeNames[unlockedEnvsFieldName]!] = unlockedEnvironments
          .map((environment) => environment.toMap(options: options))
          .toList();
        break;
      case EntityMappingType.idOnly:
        map[attributeNames[countryFieldName]!] = country.id;
        map[attributeNames[unlockedEnvsFieldName]!] = unlockedEnvironments
            .map((env) => env.id)
            .toList();
        break;
      case EntityMappingType.notIncluded:
        break;
    }

    return Map.unmodifiable(map);
  }

  /// Determina si este perfil de usuario ha desbloqueado el entorno con [envId].
  /// 
  /// Retorna **false** si este perfil no ha desbloqueado ningún entorno con 
  /// [envId], o si ha desbloqueado más de 1.  
  bool hasUnlockedEnv(int envId) => unlockedEnvironments
      .where((e) => e.id == envId).length == 1;

  bool get isLinkedToAccount => userAccountID.isNotEmpty;

  bool get hasSpecificLinkedProfileId => id != linkedProfileId && linkedProfileId > 0;

  bool get hasRenalInsufficiency => medicalCondition == MedicalCondition.renalInsufficiency;

  bool get hasNephroticSyndrome => medicalCondition == MedicalCondition.nephroticSyndrome;

  int get ageInYears => dateOfBirth != null 
    ? DateTime.now().difference(dateOfBirth!).inDays.abs() ~/ 365
    : 0;

  String get fullName {

    final strBuf = StringBuffer();
    const int maxFirstNameDisplayLength = 64;
    const int maxLastNameDisplayLength = 64;

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
  /// [maxCoinAmount] si la suma anterior sobrepasa el rango: 
  /// 
  /// monedas <= [maxCoinAmount]
  void addCoins(int amount) {
    final maxAmountOfCoins = ProfileValidator.coinAmountRange.max.toInt();
    final coinAmountAfterAddition = coins + amount.abs();

    coins = min(maxAmountOfCoins, coinAmountAfterAddition);
  }

  /// Modifica el número de monedas del perfil, decrementándolo por [amount]
  /// monedas. 
  /// 
  /// Si [amount] es mayor que el número, la cantidad de monedas del 
  /// perfil no es modificada y este método retorna **false**.
  bool spendCoins(int amount) {

    final hasEnoughCoins = coins >= amount;

    if (hasEnoughCoins) {
      final minCoinAmount = ProfileValidator.coinAmountRange.min.toInt();
      final newCoinAmount = coins -= amount.abs();

      coins = max(minCoinAmount, newCoinAmount);
    }

    return hasEnoughCoins;
  }

  /// Registra una modificación a los datos sensibles de [UserProfile].
  /// Debería ser invocado cada vez que se guardan cambios para el perfil.
  void recordModification() => ++modificationCount;

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

    final isNameDifferent = firstName != changes.firstName || lastName != changes.lastName;
    final isDateOfBirthDifferent = !(dateOfBirth
        ?.isAtSameMomentAs(changes.dateOfBirth ?? DateTime.now()) 
        ?? changes.dateOfBirth == null);

    final isSexDifferent = sex != changes.sex;
    final hasDifferentMedicalCondition = medicalCondition != changes.medicalCondition;

    final isLinkedToDifferentAccount = userAccountID.isNotEmpty && userAccountID != changes.userAccountID;
    final isCountryDifferent = country != changes.country;

    return isNameDifferent || isDateOfBirthDifferent || isSexDifferent || 
        hasDifferentMedicalCondition || isLinkedToDifferentAccount || isCountryDifferent;
  }

  @override
  String toString() => "$firstName $lastName's profile, with ID = $id";

  @override
  bool operator ==(Object? other) {

    if (other is! UserProfile) {
      return false;
    } 

    final isIdEqual = id == other.id;
    final isNameEqual = fullName == other.fullName;
    final isBirthDateEqual = (dateOfBirth == null && other.dateOfBirth == null) || 
      (dateOfBirth?.isAtSameMomentAs(other.dateOfBirth ?? DateTime.now()) ?? false);
    final areFeaturesEqual = sex == other.sex &&
      medicalCondition == other.medicalCondition &&
      occupation == other.occupation;
    final isWeightEqual = (weight - other.weight).abs() < 0.001;
    final isHeightEqual = (height - other.height).abs() < 0.001;
    final isAccountEqual = userAccountID == other.userAccountID;
    final areCoinsEqual = coins == other.coins;
    final isSelectedEnvEqual = selectedEnvironment.id == other.selectedEnvironment.id;
    final isCountryEqual = country == other.country;
    final areUnlockedEnvsEqual = unlockedEnvironments.length == other.unlockedEnvironments.length;

    return isIdEqual && isNameEqual && isBirthDateEqual && areFeaturesEqual
      && isWeightEqual && isHeightEqual && isAccountEqual && areCoinsEqual
      && isSelectedEnvEqual && isCountryEqual && areUnlockedEnvsEqual;
  }

  @override
  int get hashCode => Object.hashAll([ 
    id, firstName, lastName, dateOfBirth, sex, height, weight, 
    medicalCondition, occupation, userAccountID, selectedEnvironment.id, 
    coins, modificationCount, country, unlockedEnvironments 
  ]);
}
