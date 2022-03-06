import 'dart:math';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:hydrate_app/src/db/migrations.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
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
  };

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

    SQLiteMigrator.migrations.keys.toList()
      ..sort()
      ..forEach((version) async { 
        final List<String> queries = SQLiteMigrator.migrations[version] ?? [];

        for (var query in queries) {
          await db.execute(query);
        }
      });
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
    Map<String, dynamic> simpleEntityColumns = {};

    // Mapa con todas los resultados de inserciones colaterales. 
    // La llave de cada entrada es el nombre de la tabla, y su valor es una lista
    // con todos los IDs de las entidades insertadas en dicha tabla.
    Map<String, List<int>> secondaryInsertions = {};

    // Revisar el tipo de cada columna, para ver si es anidado.
    for (var column in entity.toMap().entries) {

      dynamic value = column.value;

      // Revisar si el valor es un modelo anidado.
      if (value is List<SQLiteModel>) {
        for (var nestedEntity in value) { 

          int secondaryId = await db.insert(nestedEntity.table, nestedEntity.toMap()); 

          if (secondaryId >= 0) {

            if (secondaryInsertions[nestedEntity.table] != null) {
              secondaryInsertions[nestedEntity.table]?.add(secondaryId); 
            } else {
              secondaryInsertions[nestedEntity.table] = <int>[secondaryId];
            }
          }
        }
      } else if (value is SQLiteModel) {
        //TODO: Manejar relaciones uno a muchos.
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
      final String? whereColumn,
      final String? whereOperator,
      final List<String>? whereArgs,
      final int? limit,
      final bool queryManyToMany = false,
    }
  ) async {

    final db = await database;

    final records = await db.query(table, 
      where: (whereColumn != null) ? '$whereColumn ${whereOperator ?? '='} ?' : null,
      whereArgs: whereArgs ?? [],
      limit: limit,  
    );

    if (records.isEmpty) return [];

    List<Map<String, Object?>> fullRecords = records.map((record) => Map<String, Object?>.from(record)).toList();

    print('Query result example: ${records[0]}');

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

  Iterable<int> reduceIds(List<Map<String, dynamic>> rows, String idColumn) {
    return rows.map((row) => int.tryParse(row[idColumn].toString()) ?? -1);
  }
}