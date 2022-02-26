import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/article.dart';
import 'package:hydrate_app/src/models/goal.dart';
import 'package:hydrate_app/src/models/tag.dart';

/// Proporciona acceso a una base de datos local de SQLite.
class SQLiteDB {

  static Database? _db;
  static final SQLiteDB db = SQLiteDB._();

  SQLiteDB._();

  /// Obtiene la instancia de la base de datos, o la inicializa si no existe.
  Future<Database> get database async => _db ?? await init('hydrate.db');

  Map<String, Map<String, String>> manyToManyTables = {
    'meta': { 'etiqueta': 'etiquetas_meta' },
  };

  // Abre la base de datos. Si no existe previamente, es creada.
  Future<Database> init(String filePath) async {
    
    // Obtiene el path para la base de datos.
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onOpen: (db) {},
      onCreate: _createDatabase,
      onUpgrade: (db, oldVersion, newVersion) async {
        print('Upgrading the database from $oldVersion to v$newVersion');
        await db.close();
        await deleteDatabase(path);

        init(filePath);
      }
    );
  }

  /// Crea la base de datos, considerando la versión.
  Future _createDatabase(Database db, int version) async {

    print('Re-creating db to version $version');

    await db.execute(Article.createTableQuery);

    await db.execute(Goal.createTableQuery);

    await db.execute(Tag.createTableQuery);

    await db.execute('''
      CREATE TABLE etiquetas_meta (
        id ${SQLiteModel.idType},
        id_meta ${SQLiteModel.integerType} ${SQLiteModel.notNullType},
        id_etiqueta ${SQLiteModel.integerType} ${SQLiteModel.notNullType},

        ${SQLiteModel.fk} (id_meta) ${SQLiteModel.references} meta (id)
          ${SQLiteModel.onDelete} ${SQLiteModel.cascadeAction},

        ${SQLiteModel.fk} (id_etiqueta) ${SQLiteModel.references} etiqueta (id)
          ${SQLiteModel.onDelete} ${SQLiteModel.cascadeAction}
      )
    ''');
  }

  /// Inserta un [SQLiteModel] en la base de datos.
  /// 
  /// Retorna el ID de la entidad insertada.
  Future<int> insert(SQLiteModel entity) async {
    final db = await database;

    // Todas las columnas con tipos primarios, que no son entidades anidadas.
    Map<String, dynamic> simpleEntityColumns = {};

    Map<String, List<int>> secondaryInsertions = {};

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
      } else {
        simpleEntityColumns[column.key] = value;
      }
    }

    final result = await db.insert(entity.table, simpleEntityColumns);

    // Hacer las inserciones necesarias en tablas muchos-a-muchos.
    for (var entry in secondaryInsertions.entries) {
      String? mtmTable = manyToManyTables[entity.table]?[entry.key];

      if (mtmTable != null) {

        for (var insertedId in entry.value) {
          final manyToManyMap = {
            'id_${entity.table}': result,
            'id_${entry.key}': insertedId 
          };
          
          print("Inserting result into many-to-many table ($mtmTable): $manyToManyMap");

          await db.insert(mtmTable, manyToManyMap);
        }
      } else {
        print('Warning: ManyToMany table name string was: $mtmTable');
      }
    }

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

  Iterable<int> reduceIds(List<Map<String, dynamic>> rows, String idColumn) {
    return rows.map((row) => int.tryParse(row[idColumn].toString()) ?? -1);
  }
}