import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/models.dart';

class SQLiteMigrator {

  static final Map<int, List<String>> migrations = {
    8: [
      '${SQLiteModel.dropTableIfExists} ${Article.tableName}',
      '${SQLiteModel.dropTableIfExists} ${Goal.tableName}',
      '${SQLiteModel.dropTableIfExists} ${Tag.tableName}',
      '${SQLiteModel.dropTableIfExists} ${Country.tableName}',
      '${SQLiteModel.dropTableIfExists} ${UserInfo.tableName}',
      '${SQLiteModel.dropTableIfExists} ${Habits.tableName}',
      '${SQLiteModel.dropTableIfExists} ${MedicalData.tableName}',
      '${SQLiteModel.dropTableIfExists} ${HydrationRecord.tableName}',
      '${SQLiteModel.dropTableIfExists} ${Profile.tableName}',
    ],
    9: [
      // Queries de los modelos iniciales.
      Article.createTableQuery,
      Goal.createTableQuery,
      Tag.createTableQuery,
      Country.createTableQuery,
      UserInfo.createTableQuery,
      Habits.createTableQuery,
      MedicalData.createTableQuery,
      HydrationRecord.createTableQuery,
      Profile.createTableQuery,

      // Query para crear la tabla muchos a muchos entre metas y etiquetas.
      '''
      CREATE TABLE ${Tag.tableName}s_${Goal.tableName} (
        id ${SQLiteModel.idType},
        id_${Goal.tableName} ${SQLiteModel.integerType} ${SQLiteModel.notNullType},
        id_${Tag.tableName} ${SQLiteModel.integerType} ${SQLiteModel.notNullType},

        ${SQLiteModel.fk} (id_${Goal.tableName}) ${SQLiteModel.references} ${Goal.tableName} (id)
          ${SQLiteModel.onDelete} ${SQLiteModel.cascadeAction},

        ${SQLiteModel.fk} (id_${Tag.tableName}) ${SQLiteModel.references} ${Tag.tableName} (id)
          ${SQLiteModel.onDelete} ${SQLiteModel.cascadeAction}
      );
      ''',
    ],
    10: [
      'ALTER TABLE ${Profile.tableName} ADD COLUMN id_usuario ${SQLiteModel.textType}',
    ],
  };

}