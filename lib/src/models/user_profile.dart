import 'dart:math';

import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/environment.dart';

import 'country.dart';
import 'medical_data.dart';

class UserProfile extends SQLiteModel {

  int id;
  String firstName;
  String lastName;
  DateTime? birthDate;
  UserSex sex;
  double height;
  double weight;
  MedicalCondition medicalCondition;
  Occupation occupation;
  Country? country;
  String? userAccountID;
  int coins;
  int modificationCount;
  int selectedEnvId;
  List<Environment> unlockedEnvironments;

  UserProfile({
    this.id = -1,
    this.firstName = '',
    this.lastName = '',
    this.birthDate,
    this.sex = UserSex.notSpecified,
    this.height = 0.0,
    this.weight = 0.0,
    this.medicalCondition = MedicalCondition.notSpecified,
    this.occupation = Occupation.notSpecified,
    this.country,
    this.userAccountID,
    this.selectedEnvId = 0,
    this.coins = 0,
    this.modificationCount = 0,
    required this.unlockedEnvironments,
  });

  static const String tableName = 'perfil';

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      id ${SQLiteModel.idType},
      nombre ${SQLiteModel.textType},
      apellido ${SQLiteModel.textType},
      fecha_nacimiento ${SQLiteModel.textType},
      sexo ${SQLiteModel.integerType} ${SQLiteModel.notNullType},
      estatura ${SQLiteModel.realType},
      peso ${SQLiteModel.realType}, 
      padecimientos ${SQLiteModel.integerType} ${SQLiteModel.notNullType},
      ocupacion ${SQLiteModel.integerType} ${SQLiteModel.notNullType},
      entorno_sel ${SQLiteModel.integerType} ${SQLiteModel.notNullType},
      monedas ${SQLiteModel.integerType} ${SQLiteModel.notNullType},
      num_modificaciones ${SQLiteModel.integerType} ${SQLiteModel.notNullType},
      id_usuario ${SQLiteModel.textType},
      id_pais ${SQLiteModel.integerType},

      ${SQLiteModel.fk} (id_pais) ${SQLiteModel.references} pais (id)
        ${SQLiteModel.onDelete} ${SQLiteModel.setNullAction}
    )
  ''';

  static UserProfile from(UserProfile originalProfile) {
    return UserProfile(
      id: originalProfile.id,
      firstName: originalProfile.firstName,
      lastName: originalProfile.lastName,
      birthDate: originalProfile.birthDate,
      sex: originalProfile.sex,
      height: originalProfile.height,
      weight: originalProfile.weight,
      medicalCondition: originalProfile.medicalCondition,
      occupation: originalProfile.occupation,
      userAccountID: originalProfile.userAccountID,
      selectedEnvId: originalProfile.selectedEnvId,
      coins: originalProfile.coins,
      modificationCount: originalProfile.modificationCount,
      country: Country(id: originalProfile.country?.id ?? -1, code: originalProfile.country?.code ?? '--'),
      unlockedEnvironments: List.from(originalProfile.unlockedEnvironments)
    );
  }

  static UserProfile fromMap(Map<String, dynamic> map) {
    
    final country = Country.fromMap(map['pais']);

    final idxUserSex = max(map['sexo'] as int, UserSex.values.length -1);
    final idxOccupation = max(map['ocupacion'] as int, Occupation.values.length);
    final idxMedicalCondition = map['padecimientos'] ?? 0;

    var environments = map['entornos'];
    List<Environment> envList = <Environment>[];

    if (environments is List<Map<String, dynamic>> && environments.isNotEmpty) {
      envList = environments.map((environment) => Environment.fromMap(environment)).toList();
    }

    return UserProfile(
      id: map['id'],
      firstName: map['nombre'],
      lastName: map['apellido'],
      birthDate: DateTime.parse(map['fecha_nacimiento']),
      sex: UserSex.values[idxUserSex],
      height: map['estatura'],
      weight: map['peso'],
      medicalCondition: MedicalCondition.values[idxMedicalCondition],
      occupation: Occupation.values[idxOccupation],
      userAccountID: map['id_usuario'],
      selectedEnvId: map['entorno_sel'],
      coins: map['monedas'],
      modificationCount: map['num_modificaciones'],
      country: country,
      unlockedEnvironments: envList
    );
  } 

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
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
      'pais': country?.toMap() ?? <String, dynamic>{},
      'entornos': unlockedEnvironments
    };

    if (id >= 0) map['id'] = id;

    return map;
  }

  Environment get selectedEnvironment => unlockedEnvironments.isNotEmpty
      ? unlockedEnvironments.firstWhere((env) => env.id == selectedEnvId)
      : Environment();

  String get fullName => '$firstName $lastName';

  /// Obtiene las iniciales del usuario, en mayúsculas.
  String get initials {
    String firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '-';
    String lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '-';
    
    return firstInitial + lastInitial;
  }

  /// Verifica que [inputName] sea un string con longitud menor a 50.
  static String? validateFirstName(String? inputName) {

    if (inputName == null) return null;

    return (inputName.length <= 50)
        ? 'El nombre debe tener menos de 50 caracteres.'
        : null;
  }

  /// Verifica que [inputName] sea un string con longitud menor a 50.
  static String? validateLastName(String? inputLastName) {

    if (inputLastName == null) return null;

    return (inputLastName.length <= 50)
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
  notSpecified,
  woman,
  man,
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
