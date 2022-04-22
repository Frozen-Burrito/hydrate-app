import 'dart:math';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:hydrate_app/src/db/migrations.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/environment.dart';
import 'package:hydrate_app/src/models/models.dart';

/// Proporciona acceso a una base de datos local de SQLite, a través de [instance].
/// Permite realizar operaciones CRUD con sus métodos. Utiliza [SQLiteModel] para
/// todas las transacciones.
class SQLiteDB {

  static Database? _db;
  static final SQLiteDB instance = SQLiteDB._();

  SQLiteDB._();

  /// Obtiene la instancia de la base de datos, o la inicializa si no existe.
  Future<Database> get database async => _db ?? await init('hydrate.db');

  /// Almacena los nombres de las tablas muchos a muchos. 
  /// Se accede a ellos con los nombres de dos tablas.
  /// ```dart
  /// String tabla = manyToManyTables['meta']['etiqueta']; 
  /// print(tabla); // 'etiquetas_meta'
  /// ```
  Map<String, Map<String, String>> manyToManyTables = {
    Goal.tableName: { Tag.tableName: '${Tag.tableName}s_${Goal.tableName}' },
    UserProfile.tableName: { Environment.tableName: '${Environment.tableName}s_${UserProfile.tableName}' },
  };

  List<String> allTables = [
    Article.tableName,
    Country.tableName,
    Goal.tableName,
    Habits.tableName,
    HydrationRecord.tableName,
    MedicalData.tableName,
    Tag.tableName,
    UserProfile.tableName,
  ];

  /// Abre la base de datos. Si no existe previamente, es creada.
  Future<Database> init(String filePath) async {
    
    // Obtiene el path para la base de datos.
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final int maxMigrationVersion = SQLiteMigrator.migrations.keys.reduce(max);

    return await openDatabase(
      path,
      version: maxMigrationVersion,
      onOpen: (db) {},
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  // Crea la base de datos, considerando la versión.
  // Ejecuta los queries de creación de tabla para cada modelo.
  Future _createDatabase(Database db, int version) async {

    var dbVersions = SQLiteMigrator.migrations.keys.toList()..sort();

    for (var version in dbVersions) {
      final List<String> queries = SQLiteMigrator.migrations[version] ?? [];

      for (var query in queries) {
        await db.execute(query);
      }
    }
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {

    for (var i = oldVersion+1; i <= newVersion; i++) {
      
      final List<String> queries = SQLiteMigrator.migrations[i] ?? [];

      for (var query in queries) {
        await db.execute(query);
      }
    }

    print('DB upgraded from v$oldVersion to v$newVersion');
  }

  /// Inserta un [SQLiteModel] en la base de datos.
  /// 
  /// Retorna el ID de la entidad insertada.
  Future<int> insert(SQLiteModel entity) async {
    final db = await database;

    // Todas las columnas con tipos primarios, que no son entidades anidadas.
    Map<String, Object?> simpleEntityColumns = {};

    // Mapa con todas los resultados de inserciones colaterales. 
    // La llave de cada entrada es el nombre de la tabla, y su valor es una lista
    // con todos los IDs de las entidades insertadas en dicha tabla.
    Map<String, List<int>> secondaryInsertions = {};

    // Revisar el tipo de cada columna, para ver si es anidado.
    for (var column in entity.toMap().entries) {

      Object? value = column.value;

      // Revisar si el valor es un modelo anidado.
      if (value is List<SQLiteModel>) {
        for (var nestedEntity in value) { 

          final nestedEntityMap = nestedEntity.toMap();
          final foreignKeyId = (nestedEntityMap['id'] is int ? nestedEntityMap['id'] as int : -1);

          if (foreignKeyId < 0) {
            // La otra entidad no existe, es necesario insertarla primero.
            int secondaryId = await db.insert(nestedEntity.table, nestedEntity.toMap()); 

            if (secondaryId >= 0) {
              // Incluir el id de la nueva entidad en la fk.
              if (secondaryInsertions[nestedEntity.table] != null) {
                secondaryInsertions[nestedEntity.table]?.add(secondaryId); 
              } else {
                secondaryInsertions[nestedEntity.table] = <int>[secondaryId];
              }
            }
          } else {
            if (secondaryInsertions[nestedEntity.table] != null) {
                secondaryInsertions[nestedEntity.table]?.add(foreignKeyId); 
              } else {
                secondaryInsertions[nestedEntity.table] = <int>[foreignKeyId];
              }
          }
        }
      } else if (value is SQLiteModel) {
        
        final otherEntity = value.toMap();
        final foreignKeyId = (otherEntity['id'] is int ? otherEntity['id'] as int : -1); 

        if (foreignKeyId < 0) {
          // La otra entidad no existe, es necesario insertarla primero.
          int secondaryId = await db.insert(value.table, value.toMap());

          if (secondaryId >= 0) {
            // Incluir el id de la nueva entidad en la fk.
            simpleEntityColumns['id_${value.table}'] = secondaryId;
          }
        } else {
          // La otra entidad ya existe, incluir su id.
          simpleEntityColumns['id_${value.table}'] = foreignKeyId;
        }

      } else {
        simpleEntityColumns[column.key] = value;
      }
    }

    // Insertar la entidad principal.
    final result = await db.insert(entity.table, simpleEntityColumns);

    // Hacer las inserciones necesarias en tablas muchos-a-muchos.
    //TODO: Revisar los ids regresados por _insertManyToMany para manejar errores.
    await _insertManyToMany(db, entity.table, result, secondaryInsertions);

    return result;
  }

  /// Retorna una lista con todos los registros de una tabla.
  Future<Iterable<T>> select<T extends SQLiteModel>(
    T Function(Map<String, Object?>) mapper, 
    final String table, 
    { 
      final List<WhereClause>? where,
      final List<String>? whereUnions,
      final int? limit,
      final bool queryManyToMany = false,
      final bool includeOneToMany = false,
      final String? orderByColumn,
      final bool? orderByAsc,
    }
  ) async {

    final db = await database;

    String whereQuery = '';
    List<String> whereArgs = [];

    if (where != null && whereUnions != null) {
      assert((where.length -1) == whereUnions.length);

      for (int i = 0; i < where.length; ++i) {
        WhereClause clause = where[i];

        whereQuery += clause.where;
        whereArgs.add(clause.arg);

        if (i < whereUnions.length) {
          whereQuery += ' ${whereUnions[i]} ';
        }
      }
    }

    print('WHERE query: $whereQuery, ARGS: $whereArgs');

    final records = await db.query(table, 
      where: (where != null) ? whereQuery : null,
      whereArgs: whereArgs,
      limit: limit,  
      orderBy: (orderByColumn != null && orderByAsc != null) 
          ? '$orderByColumn ${orderByAsc ? 'ASC' : 'DESC'}' : null,
    );

    if (records.isEmpty) return [];

    List<Map<String, Object?>> fullRecords = records.map((record) => Map<String, Object?>.from(record)).toList();

    print('Query result example: ${records[0]}');

    if (includeOneToMany) {
      final foreignTables = foreignKeyTables(fullRecords.first);

      final Map<String, List<Map<String, Object?>>> foreignEntities = {};

      for (String tableName in foreignTables)
      {
        final otmResults = await db.query(
          tableName,
          // where: 'id_$table IN (${resultIds.join(',')})'
        );

        foreignEntities[tableName] = otmResults;
      }

      for (var row in fullRecords) {

        for (String otherTable in foreignTables) {
          
          String fk = 'id_$otherTable';
          int relId = (row[fk] is int ? row[fk] as int : -1);

          if (relId < 0) continue;

          row[otherTable] = foreignEntities[otherTable]
            ?.firstWhere((entity) => entity['id'] as int == relId);
        }
      }
    }

    if (queryManyToMany && manyToManyTables[table] != null) {
      // Existe al menos 1 tabla muchos a muchos que usa la entidad solicitada.
      final resultIds = reduceIds(records, 'id').toList();

      for (var mtmTable in manyToManyTables[table]!.entries) {
        
        String otherEntityTable = mtmTable.key; // El nombre de la tabla de la otra entidad relacionada.
        String relationshipTable = mtmTable.value; // El nombre de la tabla muchos a muchos. 

        // Obtener todas las filas de la tabla muchos a muchos con un Id encontrado
        // en los resultados del query principal.
        final mtmResults = await db.query(
          relationshipTable, 
          where: 'id_$table IN (${resultIds.join(',')})', 
          // whereArgs: ['(${resultIds.join(',')})'],
        );

        print('Many to many results: $mtmResults');

        final otherEntityIds = reduceIds(mtmResults, 'id_$otherEntityTable').toList();

        final otherEntityResults = await db.query(
          otherEntityTable, 
          where: 'id IN (${otherEntityIds.join(',')})',
        );

        for (var row in fullRecords) { 

            // Todos los row con el id del row principal (si meta.id = 5, todos los row con 5).
            final mtmOccurrences = mtmResults.where((result) => result['id_$table'] == row['id']);
            
            // Los ids de las entidades relacionadas con el row principal.
            final otherIds = reduceIds(mtmOccurrences.toList(), 'id_$otherEntityTable');

            row['${otherEntityTable}s'] = otherEntityResults
                .where((otherRow) => otherIds.contains(otherRow['id']))
                .map((e) => Map<String, Object?>.from(e))
                .toList();

            // row['${otherEntityTable}s'] es un List<Map<String, Object?>> donde 
            // cada elemento es un mapa de la entidad asociada.
            // Si la entidad original es un Goal, cada Map representa un Tag asociado
            // con el Goal.

            print('Entidades relacionadas con el row(${row['id']}: ${row['${otherEntityTable}s']}');
        }
      }
    }

    Iterable<T> data = fullRecords.map((e) => mapper(e));

    return data;
  }

  /// Actualiza la fila con el id y los valores de [entity].
  Future<int> update(SQLiteModel entity) async {
    final db = await database;
    final result = await db.update(
      entity.table, 
      entity.toMap(), 
      where: 'id = ?', 
      whereArgs: [entity.toMap()['id']]
    );

    return result;
  }

  /// Elimina de la [table] un registro con el [id] especificado.
  Future<int> delete(final String table, final int id) async {
    final db = await database;
    final result = await db.delete(table, where: 'id = ?', whereArgs: [id]);

    return result;
  }

  /// Inserta en una tabla las entidades necesarias para una relación 
  /// muchos-a-muchos entre la [mainTable] y las tablas con los nombres encontrados
  /// en [otherInsertedRows].
  /// 
  /// Cada registro creado en [manyToManyTable] tiene tres columnas:
  ///  - 'id': el Id del registro en la tabla.
  ///  - 'id_{mainTable}': almacena el id de la entidad principal.
  ///  - 'id_{otherTable}': almacena el id de la entidad relacionada, obtenido de 
  ///     [otherInsertedRows].
  /// 
  /// Por ejemplo, si mainTable es 'meta' y otherTable es 'etiqueta', una columna
  /// será [id_meta] y la otra será [id_etiqueta].
  Future<List<int>> _insertManyToMany(
    Database db,
    String mainTable,
    int mainInsertionId,
    Map<String, List<int>> otherInsertedRows,
  ) async {

    final List<int> resultIds = <int>[];

    // Ciclar por cada tabla en donde hubo inserciones.
    for (var insertion in otherInsertedRows.entries) {
      
      // Obtener los nombres de la tabla relacionada y la tabla muchos a muchos.
      final String otherTable = insertion.key;
      final List<int> otherIds = insertion.value;

      String? mtmTable = manyToManyTables[mainTable]?[otherTable];

      if (mtmTable != null) {

        for (int otherId in otherIds) {
          
          // Mapa con datos del registro para insertar en tabla.
          final manyToManyMap = {
            'id_$mainTable': mainInsertionId,
            'id_$otherTable': otherId 
          };

          int id = await db.insert(mtmTable, manyToManyMap);
          resultIds.add(id);
        }
      } 
    }

    return resultIds;
  }

  Iterable<String> foreignKeyTables(Map<String, Object?> row) {
    List<String> tables = [];

    for (String key in row.keys) {
      bool keyStartsWithId = key.length > 3 && key.substring(0, 3) == 'id_';

      if (keyStartsWithId && !tables.contains(key)) {
        tables.add(key.substring(3));
      }
    }

    return tables;
  }

  Iterable<int> reduceIds(List<Map<String, Object?>> rows, String idColumn) {
    return rows.map((row) => int.tryParse(row[idColumn].toString()) ?? -1);
  }
}

class WhereClause {

  final String column;
  final String? whereOperator;
  final String argument;

  WhereClause(this.column, this.argument, { this.whereOperator });

  String get where => '$column ${whereOperator ?? '='} ?';

  String get arg => argument;
}