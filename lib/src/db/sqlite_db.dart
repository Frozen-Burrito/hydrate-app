import 'package:path/path.dart';

import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:hydrate_app/src/models/article.dart';

/// Proporciona acceso a una base de datos local de SQLite.
class SQLiteDB {

  static Database? _db;
  static final SQLiteDB db = SQLiteDB._();

  SQLiteDB._();

  /// Obtiene la instancia de la base de datos, o la inicializa si no existe.
  Future<Database> get database async => _db ?? await init('hydrate.db');

  // Abre la base de datos. Si no existe previamente, es creada.
  Future<Database> init(String filePath) async {
    
    // Obtiene el path para la base de datos.
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onOpen: (db) {},
      onCreate: _createDatabase
    );
  }

  /// Crea la base de datos, considerando la versión.
  Future _createDatabase(Database db, int version) async {

    const textType = 'TEXT';
    const boolType = 'BOOLEAN';
    const integerType = 'INTEGER';
    const idType = '$integerType PRIMARY KEY AUTOINCREMENT';
    const notNullType = 'NOT NULL';

    await db.execute('''
      CREATE TABLE article (
        id $idType,
        title $textType $notNullType,
        description $textType,
        url $textType $notNullType,
        publishDate $textType
      )
    ''');
  }

  /// Inserta un [SQLiteModel] en la base de datos.
  /// 
  /// Retorna el ID de la entidad insertada.
  Future<int> insert(SQLiteModel entity) async {
    final db = await database;
    final result = await db.insert(entity.table, entity.toMap());

    return result;
  }

  /// Retorna una lista con todos los registros de una tabla.
  Future<List<SQLiteModel>> select(final String table, final int? id) async {
    final db = await database;

    final result = await db.query(table);

    if (result.isEmpty) return [];

    List<SQLiteModel> data = [];

    switch (table) {
      case 'article': //TODO: Quitar el nombre de tabla hardcoded
        data = result.map((e) => Article.fromMap(e)).toList();
        break;
    }

    return data;
  }

  /// Elimina de la [table] un registro con el [id] especificado.
  Future<int> delete(final String table, final int id) async {
    final db = await database;
    final result = await db.delete(table, where: 'id = ?', whereArgs: [id]);

    return result;
  }
}