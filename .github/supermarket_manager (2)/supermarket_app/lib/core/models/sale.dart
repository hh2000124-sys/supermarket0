import 'product.dart';

class Sale {
  final int? id;
  final DateTime date;
  final double totalAmount;
  final double totalProfit;
  final int itemsCount;
  final List<SaleItem>? items;

  Sale({
    this.id,
    required this.date,
    required this.totalAmount,
    required this.totalProfit,
    required this.itemsCount,
    this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'total_amount': totalAmount,
      'total_profit': totalProfit,
      'items_count': itemsCount,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      totalAmount: map['total_amount'] as double,
      totalProfit: map['total_profit'] as double,
      itemsCount: map['items_count'] as int,
    );
  }
}

class SaleItem {
  final int? id;
  final int saleId;
  final int productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double totalPrice;
  final double profit;

  SaleItem({
    this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    required this.profit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'total_price': totalPrice,
      'profit': profit,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      unitPrice: map['unit_price'] as double,
      quantity: map['quantity'] as int,
      totalPrice: map['total_price'] as double,
      profit: map['profit'] as double,
    );
  }
}
