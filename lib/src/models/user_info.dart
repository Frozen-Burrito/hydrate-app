import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/country.dart';
import 'package:hydrate_app/src/models/medical_data.dart';

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

//TODO: Helper temporal
enum UserCountry {
  notSpecified,
  mexico,
  us,
}

class UserInfo extends SQLiteModel {
  
  int id;
  UserSex sex;
  double height;
  double weight;
  MedicCondition medicCondition;
  Occupation occupation;
  Country? country;

  UserInfo({
    this.id = -1,
    this.sex = UserSex.notSpecified,
    this.height = 0.0,
    this.weight = 0.0,
    this.medicCondition = MedicCondition.notSpecified,
    this.occupation = Occupation.notSpecified,
    this.country,
  });

  static const String tableName = 'info_usuario';

  @override
  String get table => tableName;

  /// El string de query para crear la tabla del modelo en SQLite.
  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      id ${SQLiteModel.idType},
      sexo ${SQLiteModel.integerType} ${SQLiteModel.notNullType},
      estatura ${SQLiteModel.realType} ${SQLiteModel.notNullType},
      peso ${SQLiteModel.realType} ${SQLiteModel.notNullType}, 
      padecimientos ${SQLiteModel.integerType} ${SQLiteModel.notNullType},
      ocupacion ${SQLiteModel.integerType} ${SQLiteModel.notNullType},
      id_pais ${SQLiteModel.integerType},

      ${SQLiteModel.fk} (id_pais) ${SQLiteModel.references} pais (id)
        ${SQLiteModel.onDelete} ${SQLiteModel.setNullAction}
    )
  ''';

  static UserInfo fromMap(Map<String, dynamic> map) {
    
    return UserInfo(
      id: map['id'],
      sex: UserSex.values[map['sexo']],
      height: map['estatura'],
      weight: map['peso'],
      medicCondition: MedicCondition.values[map['padecimientos']],
      occupation: Occupation.values[map['ocupacion']],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'sexo': sex.index,
      'estatura': height,
      'peso': weight,
      'padecimientos': medicCondition.index,
      'ocupacion': occupation.index,
      // 'pais': country,
    };

    if (id >= 0) map['id'] = id;

    return map;
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