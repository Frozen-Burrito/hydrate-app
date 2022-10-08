import 'dart:math';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:hydrate_app/src/db/migrations.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/db/where_clause.dart';
import 'package:hydrate_app/src/models/map_options.dart';
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

  final tableNames = <String>[
    Article.tableName,
    Goal.tableName,
    Tag.tableName,
    Country.tableName,
    Habits.tableName,
    MedicalData.tableName,
    HydrationRecord.tableName,
    UserProfile.tableName,
    Environment.tableName,
    ActivityRecord.tableName,
    ActivityType.tableName
  ];

  static const entityMapOptions = MapOptions(
    includeCompleteSubEntities: true,
    useCamelCasePropNames: false,
    useIntBooleanValues: true,
  );

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
  /// [entity] es convertida a un mapa usando su método [SQLiteModel.toMap()], 
  /// con las opciones especificadas en [entityMapOptions]. Estas opciones 
  /// determinan la forma en que serán manejadas las relaciones y transformación
  /// a columnas de SQLite.
  /// 
  /// Retorna el ID de la entidad insertada, o un entero negativo si la entidad 
  /// no pudo ser insertada.
  Future<int> insert(SQLiteModel entity) async {
    final db = await database;

    // Todas las columnas con tipos primarios, que no son relaciones 1-m o m-m.
    final simpleEntityColumns = await _filterSimpleColumns(entity);

    try {
      // Intentar insertar la entidad principal.
      final insertedId = await db.insert(entity.table, simpleEntityColumns);

      if (insertedId >= 0) {

        int totalRowsAltered = 1;

        // Manejar las relaciones muchos a muchos y uno a muchos de la entidad
        // insertada.
        totalRowsAltered += await _describeRelationships(
          entity, 
          insertedId: insertedId
        );

        print("Entity inserted, rows altered: $totalRowsAltered");

        // Retornar el ID de la entidad principal insertada.
        return insertedId;

      } else {
        return -1;
      }

    } on DatabaseException catch(ex) {
      // Ocurrió algún error relacionado con la base de datos durante esta 
      // operación de INSERT. Imprimir el error y retornar un entero negativo.
      //TODO: Considerar opciones para mejorar el manejo de errores de base de datos.
      print("DatabaseException: $ex");
      return -1;
    }
  }

  /// Retorna una lista con todos los registros de una tabla.
  Future<Iterable<T>> select<T extends SQLiteModel>(
    T Function(Map<String, Object?>) mapper,
    final String table,
    { 
      final List<WhereClause> where = const <WhereClause>[],
      final List<String> whereUnions = const <String>[],
      final int? limit,
      final bool queryManyToMany = false,
      final bool includeOneToMany = false,
      final String? orderByColumn,
      final bool? orderByAsc,
    }
  ) async 
  {

    if (where.isNotEmpty) {
      assert(where.length == (whereUnions.length + 1), "There must be 1 less union than where clauses");
    }

    final db = await database;

    final fullWhere = where.isNotEmpty
      ? MultiWhereClause.fromConditions(where, whereUnions)
      : null;

    print('WHERE query: ${fullWhere?.where}, ARGS: ${fullWhere?.args}');

    final records = await db.query(table, 
      where: fullWhere?.where,
      whereArgs: fullWhere?.args,
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
  /// 
  /// Retorna la cantidad de filas alteradas (1 = Actualización exitosa).
  Future<int> update(SQLiteModel entity) async {
    final db = await database;

    // Todas las columnas con tipos primarios, que no son relaciones 1-m o m-m.
    final columnValues = await _filterSimpleColumns(entity);

    int totalRowsAltered = await _describeRelationships(entity);

    totalRowsAltered += await db.update(
      entity.table, 
      columnValues, 
      where: 'id = ?', 
      whereArgs: [columnValues['id']]
    );

    return totalRowsAltered;
  }

  /// Elimina de la [table] un registro con el [id] especificado.
  /// 
  /// Retorna el número de filas modificadas.
  Future<int> delete(final String table, final int id) async {

    final db = await database;
    final result = await db.delete(table, where: 'id = ?', whereArgs: [ id ]);

    return result;
  }

  /// Produce un mapa con todas las columnas y valores de una entidad que sean 
  /// soportados por SQLite.
  /// 
  /// Si la columna es un tipo soportado por SQLite, su valor no es modificado.
  /// Si la columna es un SQLiteModel, se determina si la otra entidad existe y 
  /// se crea una llave foránea en el mapa de [entity] con el id de la otra entidad.
  Future<Map<String, Object?>> _filterSimpleColumns(SQLiteModel entity) async {
    final db = await database;
    
    /// Mapa de la entidad con los valores sin convertir. 
    final Map<String, Object?> mappedEntity = entity.toMap(options: entityMapOptions);

    /// Mapa con los valores finales de las columnas de la entidad.
    final Map<String, Object?> entityColumnValues = {};

    for (var column in mappedEntity.entries) {

      Object? columnValue = column.value;

      // La entidad principal es la que contiene la propiedad de PK.
      // La entida dependiente es la que tiene las llaves foraneas y depende de la 
      // entidad principal.

      if (columnValue is SQLiteModel) {
        // Definir la llave foránea para la relación con la otra entidad.
        final otherEntity = columnValue.toMap(options: entityMapOptions);
        final otherEntityId = (otherEntity['id'] is int ? otherEntity['id'] as int : -1); 

        if (otherEntityId < 0) {
          // La otra entidad no existe, es necesario insertarla primero.
          int principalId = await db.insert(columnValue.table, otherEntity);

          if (principalId >= 0) {
            // Incluir el id de la nueva entidad en la fk.
            entityColumnValues['id_${columnValue.table}'] = principalId;
          }
        } else {
          // La otra entidad ya existe, incluir su id.
          entityColumnValues['id_${columnValue.table}'] = otherEntityId;
        }

      } else if (isTypeSupportedBySqlite(columnValue)) {
        // La columna tiene un valor primitivo, listar el valor como está.
        entityColumnValues[column.key] = columnValue;
        
      } else if (columnValue is! Iterable<SQLiteModel>) {
        throw ArgumentError(
          'El valor de la columna (${columnValue.runtimeType}) no es soportado por SQLite. ' 
          'Los tipos soportados son SQLiteModel, Iterable<SQLiteModel> y los primitivos de SQLite'
        );
      }
    }

    return entityColumnValues;
  }

  /// Determina si el tipo de un [value] es soportado por SQLite.
  /// 
  /// Los tipos de dato soportados por SQLite son NULL, INTEGER, REAL, TEXT y
  /// BLOB. 
  bool isTypeSupportedBySqlite(Object? value) {
    return (value == null || value is String || value is double || value is int || value is bool);
  }

  /// Encuentra las relaciones muchos a muchos de [entity], determina las 
  /// operaciones necesarias para establecer cada relación.
  /// 
  /// Si [insertedId] no es nulo, considera que se están describiendo las 
  /// relaciones de una operación de inserción. En este caso, utiliza [insertedId] 
  /// como la llave primaria de [entity].
  /// 
  /// Retorna la cantidad de filas modificadas.
  Future<int> _describeRelationships(
    final SQLiteModel entity, { 
      final int? insertedId,
    }
  ) async {
    final db = await database;

    /// Mapa de la entidad con los valores sin convertir. 
    final Map<String, Object?> mappedEntity = entity.toMap(options: entityMapOptions);

    // Determinar si se están describiendo las relaciones de una inserción o de 
    // una actualización.
    final isInsertOp = (insertedId != null);

    /// El número de filas modificadas.
    int totalRowsAltered = 0; 

    // Es una inserción, usar el id de la entidad original insertada.
    final int entityId = isInsertOp ? insertedId! : mappedEntity["id"] as int;

    /// Mapa con todas las inserciones colaterales que deben realizarse.
    Map<String, List<int>> secondaryInsertions = {};

    /// Mapa con todas las eliminaciones colaterales que deben realizarse. 
    Map<String, List<int>> secondaryDeletions = {};

    // En secondaryInsertions y secondaryDeletions, La llave de cada entrada es 
    // el nombre de la tabla relacionada, y su valor es una lista con todos los 
    // IDs de las entidades modificadas en la relación m-m con dicha tabla.

    for (final column in mappedEntity.entries) {

      final columnValue = column.value;

      if (columnValue is Iterable<SQLiteModel> && columnValue.isNotEmpty) {

        final rows = columnValue.map((e) => e.toMap(options: entityMapOptions)).toList();

        final relatedIds = reduceIds(rows, 'id').toList();

        final String relatedTable = columnValue.first.table;
        final String? mtmTable = manyToManyTables[entity.table]?[relatedTable];

        // Obtener las entidades de la tabla mtm.
        final relationshipEntities = (mtmTable != null) 
          ? await db.query(
            mtmTable,
            where: 'id_${entity.table} = ?',
            whereArgs: [ entityId ]
          )
          : <Map<String, Object?>>[];

        // Determinar inserciones a tabla muchos-a-muchos. 
        for (var principalEntity in columnValue) {

          final principalEntityMap = principalEntity.toMap(options: entityMapOptions);
          
          final principalId = (principalEntityMap['id'] is int ? principalEntityMap['id'] as int : -1);

          if (isInsertOp) {
            // Si la operación es un insert, solo es necesario obtener los Ids de
            // las otras entidades, o insertarlas si aún no existen.

            if (principalId < 0) {
              // La otra entidad no existe, es necesario insertarla primero.
              int secondaryId = await db.insert(principalEntity.table, principalEntityMap); 

              if (secondaryId >= 0) {
                
                totalRowsAltered++;
                // Incluir el id de la nueva entidad en la fk.
                if (secondaryInsertions[principalEntity.table] != null) {
                  secondaryInsertions[principalEntity.table]?.add(secondaryId); 
                } else {
                  secondaryInsertions[principalEntity.table] = <int>[secondaryId];
                }
              }
            } else {
              if (secondaryInsertions[principalEntity.table] != null) {
                secondaryInsertions[principalEntity.table]?.add(principalId); 
              } else {
                secondaryInsertions[principalEntity.table] = <int>[principalId];
              }
            }
          } else {
            // Agregar a mtm si principalEntity no existe en ella.
            final principalIdColumn = 'id_${principalEntity.table}';

            final isPrincipalEntityNotCreated = relationshipEntities
              .where((e) => e[principalIdColumn] == principalId)
              .isEmpty;

            if (isPrincipalEntityNotCreated) {

              if (secondaryInsertions[principalEntity.table] != null) {
                secondaryInsertions[principalEntity.table]?.add(principalId); 
              } else {
                secondaryInsertions[principalEntity.table] = <int>[principalId];
              }
            }
          }
        }

        if (!isInsertOp) {
          // Solo si no es una inserción: Encontrar registros de relacion que 
          // hayan sido removidos en las modificaciones a la entidad. 
          for (final relEntity in relationshipEntities) {

            int relEntityId = (relEntity['id'] is int) ? relEntity['id'] as int : -1;

            // Eliminar de mtm si el id_otraTabla no esta en los ids encontrados en colValue.
            if (relEntityId > 0 && !relatedIds.contains(relEntityId)) {

              if (secondaryDeletions[relatedTable] == null) {
                secondaryDeletions[relatedTable] = <int>[];
              } 

              secondaryDeletions[relatedTable]?.add(relEntityId); 
            }
          }
        } 
      }
    }

    final requiresMtmOperations = secondaryInsertions.isNotEmpty 
      || secondaryDeletions.isNotEmpty;

    if (entityId >= 0 && requiresMtmOperations) {
      // Hacer las operaciones necesarias en tablas muchos-a-muchos.
      totalRowsAltered += await _modifyManyToMany(
        entity.table, 
        entityId,
        otherInsertedRowIds: secondaryInsertions,
        otherDeletedRowIds: secondaryDeletions,
      );
    }

    return totalRowsAltered;
  }

  /// Agrega o elimina de [manyToManyTable] las filas con las modificaciones  
  /// de una relación muchos-a-muchos entre la [mainTable] y las tablas con los 
  /// nombres encontrados en [otherInsertedRows] y [otherDeletedRowIds].
  /// 
  /// Cada registro agregado o eliminado en [manyToManyTable] tiene tres columnas:
  ///  - 'id': el Id del registro en la tabla.
  ///  - 'id_{mainTable}': almacena el id de la entidad principal.
  ///  - 'id_{otherTable}': almacena el id de la entidad relacionada, obtenido de 
  ///     [otherInsertedRows].
  /// 
  /// Por ejemplo, si mainTable es 'meta' y otherTable es 'etiqueta', una columna
  /// será [id_meta] y la otra será [id_etiqueta].
  /// 
  /// Retorna el número total de filas alteradas.
  Future<int> _modifyManyToMany(
    String mainTable,
    int mainId, {
      Map<String, List<int>>? otherInsertedRowIds,
      Map<String, List<int>>? otherDeletedRowIds,
    }
  ) async {

    final db = await database;

    int alteredRowCount = 0;

    final insertedRowIds = otherInsertedRowIds?.entries ?? [];
    final deletedRowIds = otherDeletedRowIds?.entries ?? [];

    // Ciclar por cada tabla en donde hubo inserciones.
    for (var insertion in insertedRowIds) {
      
      // Obtener los nombres de la tabla relacionada y la tabla muchos a muchos.
      final String otherTable = insertion.key;
      final List<int> otherIds = insertion.value;

      String? mtmTable = manyToManyTables[mainTable]?[otherTable];

      if (mtmTable != null) {

        for (int otherId in otherIds) {
          
          // Mapa con datos del registro para insertar en tabla.
          final manyToManyMap = {
            'id_$mainTable': mainId,
            'id_$otherTable': otherId 
          };

          int resultId = await db.insert(mtmTable, manyToManyMap);
          
          // Solo incrementar las filas alteradas si se agregó el nuevo registro. 
          if (resultId >= 0) alteredRowCount++;
        }
      } 
    }

    // Ciclar por cada tabla en donde hubo eliminaciones.
    for (var deletion in deletedRowIds) {
      
      // Obtener los nombres de la tabla relacionada y la tabla muchos a muchos.
      final String otherTable = deletion.key;
      final List<int> otherIds = deletion.value;

      String? mtmTable = manyToManyTables[mainTable]?[otherTable];

      if (mtmTable != null) {

        for (int otherId in otherIds) {

          int rowsAffected = await db.delete(
            mtmTable, 
            where: 'id_$mainTable = ? AND id_$otherTable = ?',
            whereArgs: [ mainId, otherId ], 
          );

          alteredRowCount += rowsAffected;
        }
      } 
    }

    return alteredRowCount;
  }

  Iterable<String> foreignKeyTables(Map<String, Object?> row) {

    final tables = <String>[];

    for (String key in row.keys) {

      if (key.length > 3) {
        bool keyStartsWithId = key.substring(0, 3) == 'id_';
        bool keyRefersToTable = tableNames.contains(key.substring(3));

        if (keyStartsWithId && keyRefersToTable) {
          tables.add(key.substring(3));
        }
      }
    }

    return tables;
  }

  Iterable<int> reduceIds(List<Map<String, Object?>> rows, String idColumn) {
    return rows.map((row) => int.tryParse(row[idColumn].toString()) ?? -1);
  }
}
