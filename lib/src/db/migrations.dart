import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/models/models.dart';

class SQLiteMigrator {

  static final Map<int, List<String>> migrations = {
    11: [
      '${SQLiteKeywords.dropTableIfExists} ${Article.tableName}',
      '${SQLiteKeywords.dropTableIfExists} ${Goal.tableName}',
      '${SQLiteKeywords.dropTableIfExists} ${Tag.tableName}',
      '${SQLiteKeywords.dropTableIfExists} ${Country.tableName}',
      '${SQLiteKeywords.dropTableIfExists} ${Habits.tableName}',
      '${SQLiteKeywords.dropTableIfExists} ${MedicalData.tableName}',
      '${SQLiteKeywords.dropTableIfExists} ${HydrationRecord.tableName}',
      '${SQLiteKeywords.dropTableIfExists} ${UserProfile.tableName}',
      '${SQLiteKeywords.dropTableIfExists} ${Tag.tableName}s_${Goal.tableName}',
      '${SQLiteKeywords.dropTableIfExists} ${Environment.tableName}s_${UserProfile.tableName}',

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
        id ${SQLiteKeywords.idType},
        id_${Goal.tableName} ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
        id_${Tag.tableName} ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},

        ${SQLiteKeywords.fk} (id_${Goal.tableName}) ${SQLiteKeywords.references} ${Goal.tableName} (id)
          ${SQLiteKeywords.onDelete} ${SQLiteKeywords.cascadeAction},

        ${SQLiteKeywords.fk} (id_${Tag.tableName}) ${SQLiteKeywords.references} ${Tag.tableName} (id)
          ${SQLiteKeywords.onDelete} ${SQLiteKeywords.cascadeAction}
      );
      ''',

      // Query para crear la tabla muchos a muchos entre perfiles y entornos desbloqueados.
      '''
      CREATE TABLE ${Environment.tableName}s_${UserProfile.tableName} (
        id ${SQLiteKeywords.idType},
        id_${Environment.tableName} ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
        id_${UserProfile.tableName} ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},

        ${SQLiteKeywords.fk} (id_${Environment.tableName}) ${SQLiteKeywords.references} ${Environment.tableName} (id)
          ${SQLiteKeywords.onDelete} ${SQLiteKeywords.cascadeAction},

        ${SQLiteKeywords.fk} (id_${UserProfile.tableName}) ${SQLiteKeywords.references} ${UserProfile.tableName} (id)
          ${SQLiteKeywords.onDelete} ${SQLiteKeywords.cascadeAction}
      );
      ''',

      '''INSERT INTO ${Country.tableName} VALUES (0, '--');''',
      '''INSERT INTO ${Country.tableName} VALUES (1, 'EU');''',
      '''INSERT INTO ${Country.tableName} VALUES (2, 'MX');''',      
    ],
  };

}