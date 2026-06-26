import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../constants/app_constants.dart';

class ProductRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insertProduct(Product product) async {
    final db = await _dbHelper.database;
    return await db.insert(
      AppConstants.tableProducts,
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.tableProducts,
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<Product?> getProductById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.tableProducts,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Product>> getAllProducts() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.tableProducts,
      orderBy: 'name ASC',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.tableProducts,
      where: 'name LIKE ? OR barcode LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.tableProducts,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getLowStockProducts() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.tableProducts,
      where: 'quantity <= min_stock',
      orderBy: 'quantity ASC',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    return await db.update(
      AppConstants.tableProducts,
      product.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> updateQuantity(int productId, int newQuantity) async {
    final db = await _dbHelper.database;
    return await db.update(
      AppConstants.tableProducts,
      {
        'quantity': newQuantity,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      AppConstants.tableProducts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getTotalProductsCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.tableProducts}'
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<int> getLowStockCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.tableProducts} WHERE quantity <= min_stock'
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<double> getTotalInventoryValue() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(quantity * purchase_price) as total FROM ${AppConstants.tableProducts}'
    );
    return result.first['total'] as double? ?? 0.0;
  }
}
