import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/environment.dart';
import 'package:hydrate_app/src/models/models.dart';

class SQLiteMigrator {

  static final Map<int, List<String>> migrations = {
    11: [
      '${SQLiteModel.dropTableIfExists} ${Article.tableName}',
      '${SQLiteModel.dropTableIfExists} ${Goal.tableName}',
      '${SQLiteModel.dropTableIfExists} ${Tag.tableName}',
      '${SQLiteModel.dropTableIfExists} ${Country.tableName}',
      '${SQLiteModel.dropTableIfExists} ${Habits.tableName}',
      '${SQLiteModel.dropTableIfExists} ${MedicalData.tableName}',
      '${SQLiteModel.dropTableIfExists} ${HydrationRecord.tableName}',
      '${SQLiteModel.dropTableIfExists} ${UserProfile.tableName}',
      '${SQLiteModel.dropTableIfExists} ${Tag.tableName}s_${Goal.tableName}',
      '${SQLiteModel.dropTableIfExists} ${Environment.tableName}s_${UserProfile.tableName}',

      // Queries de los modelos iniciales.
      Article.createTableQuery,
      Goal.createTableQuery,
      Tag.createTableQuery,
      Country.createTableQuery,
      Habits.createTableQuery,
      MedicalData.createTableQuery,
      HydrationRecord.createTableQuery,
      UserProfile.createTableQuery,
      Environment.createTableQuery,

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

      // Query para crear la tabla muchos a muchos entre perfiles y entornos desbloqueados.
      '''
      CREATE TABLE ${Environment.tableName}s_${UserProfile.tableName} (
        id ${SQLiteModel.idType},
        id_${Environment.tableName} ${SQLiteModel.integerType} ${SQLiteModel.notNullType},
        id_${UserProfile.tableName} ${SQLiteModel.integerType} ${SQLiteModel.notNullType},

        ${SQLiteModel.fk} (id_${Environment.tableName}) ${SQLiteModel.references} ${Environment.tableName} (id)
          ${SQLiteModel.onDelete} ${SQLiteModel.cascadeAction},

        ${SQLiteModel.fk} (id_${UserProfile.tableName}) ${SQLiteModel.references} ${UserProfile.tableName} (id)
          ${SQLiteModel.onDelete} ${SQLiteModel.cascadeAction}
      );
      ''',

      '''INSERT INTO ${Country.tableName} VALUES (0, '--');''',
      '''INSERT INTO ${Country.tableName} VALUES (1, 'EU');''',
      '''INSERT INTO ${Country.tableName} VALUES (2, 'MX');''',      
    ],
  };

}