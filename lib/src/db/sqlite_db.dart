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

    Map<String, int> secondaryInsertions = {};

    print("Entity to insert: ${entity.toMap()}");

    entity.toMap().forEach((column, value) async { 

      // Revisar si el valor es un modelo anidado.
      if (value is List<SQLiteModel>) {
        for (var nestedEntity in value) { 
          print("Inserting a secondary entity: ${nestedEntity.toMap()}");

          int secondaryId = await insert(nestedEntity); 

          if (secondaryId >= 0) {
            secondaryInsertions[nestedEntity.table] = secondaryId;
          }
        }
      } else {

        simpleEntityColumns[column] = value;
      }
    });

    print("Inserting main entity");
    final result = await db.insert(entity.table, simpleEntityColumns);

    // Hacer las inserciones necesarias en tablas muchos-a-muchos.
    for (var insertion in secondaryInsertions.entries) {
      String? mtmTable = manyToManyTables[entity.table]?[insertion.key];

      if (mtmTable != null) {
        print("Inserting result into many-to-many table.");
        await db.insert(mtmTable, {
          'id_${entity.table}': result,
          'id_${insertion.key}': insertion.value 
        });
      }
    }

    return result;
  }

  //TODO: Manejar insercion, seleccion y eliminacion con estructura de modelos.
  //TODO: Probar con insercion de metas y etiquetas

  /// Retorna una lista con todos los registros de una tabla.
  Future<Iterable<T>> select<T extends SQLiteModel>(T Function(Map<String, Object?>) mapper, final String table, { final int? id }) async {
    final db = await database;

    final result = await db.query(table);

    if (result.isEmpty) return [];

    Iterable<T> data = result.map((e) => mapper(e));

    return data;
  }

  /// Elimina de la [table] un registro con el [id] especificado.
  Future<int> delete(final String table, final int id) async {
    final db = await database;
    final result = await db.delete(table, where: 'id = ?', whereArgs: [id]);

    return result;
  }
}