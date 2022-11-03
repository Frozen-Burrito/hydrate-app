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

      '''INSERT INTO ${Country.tableName} VALUES (1, '--');''',
      '''INSERT INTO ${Country.tableName} VALUES (2, 'EU');''',
      '''INSERT INTO ${Country.tableName} VALUES (3, 'MX');''',     

      '''INSERT INTO ${MedicalData.tableName} VALUES (0, 20.0, 17.0, 200.0, 0.0, 100.0, 137.0, "2022-09-14T13:30:00.000000", "2022-09-21T13:30:00.000000", 1);''', 
    ],
    14: [
      '${SQLiteKeywords.dropTableIfExists} ${ActivityRecord.tableName}',
      '${SQLiteKeywords.dropTableIfExists} ${ActivityType.tableName}',

      // Queries de los modelos iniciales.
      ActivityRecord.createTableQuery,
      ActivityType.createTableQuery,
    ],
    17: [
      '${SQLiteKeywords.dropTableIfExists} ${ActivityRecord.tableName}',
      '${SQLiteKeywords.dropTableIfExists} ${ActivityType.tableName}',
      '${SQLiteKeywords.dropTableIfExists} ${Routine.tableName}',

      ActivityRecord.createTableQuery,
      ActivityType.createTableQuery,
      Routine.createTableQuery,

      // Insertar todos los tipos de actividad con modelos actualizados.
      '''INSERT INTO ${ActivityType.tableName} VALUES (1, 5.0, 4.3, 7);''',
      '''INSERT INTO ${ActivityType.tableName} VALUES (2, 8.0, 7.0, 8);''',
      '''INSERT INTO ${ActivityType.tableName} VALUES (3, 11.0, 7.5, 1);''',
      '''INSERT INTO ${ActivityType.tableName} VALUES (4, 0.0, 9.8, 82);''',
      '''INSERT INTO ${ActivityType.tableName} VALUES (5, 0.0, 7.0, 29);''',
      '''INSERT INTO ${ActivityType.tableName} VALUES (6, 0.0, 6.5, 12);''',
      '''INSERT INTO ${ActivityType.tableName} VALUES (7, 0.0, 4.0, 89);''',
      '''INSERT INTO ${ActivityType.tableName} VALUES (8, 0.0, 7.8, 24);''',
      '''INSERT INTO ${ActivityType.tableName} VALUES (9, 0.0, 1.3, 100);''',
    ],
    18: [
      '${SQLiteKeywords.dropTableIfExists} ${Environment.tableName}',
      
      Environment.createTableQuery,

      '''INSERT INTO ${Environment.tableName} VALUES (1, "1", 0);''',
      '''INSERT INTO ${Environment.tableName} VALUES (2, "2", 250);''',
    ],
    20: [
      '${SQLiteKeywords.dropTableIfExists} ${Country.tableName}',

      Country.createTableQuery,

      '''INSERT INTO ${Country.tableName} VALUES (1, '--');''',
      '''INSERT INTO ${Country.tableName} VALUES (2, 'MX');''',  
      '''INSERT INTO ${Country.tableName} VALUES (3, 'EU');''',
    ]
  };

}