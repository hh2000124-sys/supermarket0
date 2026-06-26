import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/sale.dart';
import '../models/product.dart';
import '../constants/app_constants.dart';
import 'product_repository.dart';

class SalesRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ProductRepository _productRepo = ProductRepository();

  Future<int> createSale(List<Map<String, dynamic>> items) async {
    final db = await _dbHelper.database;

    return await db.transaction((txn) async {
      double totalAmount = 0;
      double totalProfit = 0;
      int itemsCount = 0;

      // Create sale record
      final saleId = await txn.insert(AppConstants.tableSales, {
        'date': DateTime.now().toIso8601String(),
        'total_amount': 0,
        'total_profit': 0,
        'items_count': 0,
      });

      // Process each item
      for (var item in items) {
        final product = item['product'] as Product;
        final quantity = item['quantity'] as int;

        final itemTotal = product.sellPrice * quantity;
        final itemProfit = (product.sellPrice - product.purchasePrice) * quantity;

        totalAmount += itemTotal;
        totalProfit += itemProfit;
        itemsCount += quantity;

        // Insert sale item
        await txn.insert(AppConstants.tableSaleItems, {
          'sale_id': saleId,
          'product_id': product.id,
          'product_name': product.name,
          'unit_price': product.sellPrice,
          'quantity': quantity,
          'total_price': itemTotal,
          'profit': itemProfit,
        });

        // Update product quantity
        final newQuantity = product.quantity - quantity;
        await txn.update(
          AppConstants.tableProducts,
          {
            'quantity': newQuantity,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [product.id],
        );
      }

      // Update sale totals
      await txn.update(
        AppConstants.tableSales,
        {
          'total_amount': totalAmount,
          'total_profit': totalProfit,
          'items_count': itemsCount,
        },
        where: 'id = ?',
        whereArgs: [saleId],
      );

      return saleId;
    });
  }

  Future<List<Sale>> getAllSales() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.tableSales,
      orderBy: 'date DESC',
    );
    return maps.map((map) => Sale.fromMap(map)).toList();
  }

  Future<List<Sale>> getSalesByDate(DateTime date) async {
    final db = await _dbHelper.database;
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    final maps = await db.query(
      AppConstants.tableSales,
      where: 'date >= ? AND date <= ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Sale.fromMap(map)).toList();
  }

  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.tableSales,
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Sale.fromMap(map)).toList();
  }

  Future<List<SaleItem>> getSaleItems(int saleId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.tableSaleItems,
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    return maps.map((map) => SaleItem.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getDailyReport(DateTime date) async {
    final sales = await getSalesByDate(date);

    double totalSales = 0;
    double totalProfit = 0;
    int totalItems = 0;

    for (var sale in sales) {
      totalSales += sale.totalAmount;
      totalProfit += sale.totalProfit;
      totalItems += sale.itemsCount;
    }

    return {
      'sales_count': sales.length,
      'total_sales': totalSales,
      'total_profit': totalProfit,
      'total_items': totalItems,
    };
  }

  Future<Map<String, dynamic>> getTopSellingProducts({int limit = 10}) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT 
        si.product_id,
        si.product_name,
        SUM(si.quantity) as total_quantity,
        SUM(si.total_price) as total_revenue,
        SUM(si.profit) as total_profit
      FROM ${AppConstants.tableSaleItems} si
      GROUP BY si.product_id
      ORDER BY total_quantity DESC
      LIMIT ?
    ''', [limit]);

    return {
      'products': maps,
      'count': maps.length,
    };
  }

  Future<double> getTotalSalesForMonth(int year, int month) async {
    final db = await _dbHelper.database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0).toIso8601String();

    final result = await db.rawQuery('''
      SELECT SUM(total_amount) as total FROM ${AppConstants.tableSales}
      WHERE date >= ? AND date <= ?
    ''', [startDate, endDate]);

    return result.first['total'] as double? ?? 0.0;
  }

  Future<double> getTotalProfitForMonth(int year, int month) async {
    final db = await _dbHelper.database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0).toIso8601String();

    final result = await db.rawQuery('''
      SELECT SUM(total_profit) as total FROM ${AppConstants.tableSales}
      WHERE date >= ? AND date <= ?
    ''', [startDate, endDate]);

    return result.first['total'] as double? ?? 0.0;
  }

  Future<int> deleteSale(int saleId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      AppConstants.tableSales,
      where: 'id = ?',
      whereArgs: [saleId],
    );
  }
}
