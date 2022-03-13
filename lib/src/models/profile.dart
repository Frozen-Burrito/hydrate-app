import 'package:hydrate_app/src/db/sqlite_model.dart';

class Profile extends SQLiteModel {

  int id;
  String firstName;
  String lastName;
  DateTime? birthDate;
  String? userAccountID;

  Profile({
    this.id = 0,
    this.firstName = '',
    this.lastName = '',
    this.birthDate,
    this.userAccountID,
  });

  static const String tableName = 'perfil';

  @override
  String get table => tableName;

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      id ${SQLiteModel.idType},
      nombre ${SQLiteModel.textType} ${SQLiteModel.notNullType},
      apellido ${SQLiteModel.textType} ${SQLiteModel.notNullType},
      fecha_nacimiento ${SQLiteModel.textType} ${SQLiteModel.notNullType}
    )
  ''';

  static Profile fromMap(Map<String, dynamic> map) => Profile(
    id: map['id'],
    firstName: map['nombre'],
    lastName: map['apellido'],
    birthDate: map['fecha_nacimiento'],
    userAccountID: map['id_usuario'],
  );

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'nombre': firstName,
      'apellido': lastName,
      'fecha_nacimiento': birthDate?.toIso8601String() ?? '',
      'id_usuario': userAccountID,
    };

    if (id >= 0) map['id'] = id;

    return map;
  }
}