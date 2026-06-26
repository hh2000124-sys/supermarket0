import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableProducts} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT NOT NULL UNIQUE,
        purchase_price REAL NOT NULL,
        sell_price REAL NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0,
        category TEXT NOT NULL,
        min_stock INTEGER NOT NULL DEFAULT 5,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableSales} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        total_amount REAL NOT NULL DEFAULT 0,
        total_profit REAL NOT NULL DEFAULT 0,
        items_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableSaleItems} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        unit_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        total_price REAL NOT NULL,
        profit REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES ${AppConstants.tableSales}(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES ${AppConstants.tableProducts}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_product_barcode ON ${AppConstants.tableProducts}(barcode)
    ''');

    await db.execute('''
      CREATE INDEX idx_sale_date ON ${AppConstants.tableSales}(date)
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations here
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
