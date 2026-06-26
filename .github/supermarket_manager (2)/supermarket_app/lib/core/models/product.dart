import 'dart:convert';

class Product {
  final int? id;
  final String name;
  final String barcode;
  final double purchasePrice;
  final double sellPrice;
  final int quantity;
  final String category;
  final int minStock;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.name,
    required this.barcode,
    required this.purchasePrice,
    required this.sellPrice,
    required this.quantity,
    required this.category,
    this.minStock = 5,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isLowStock => quantity <= minStock;
  double get profit => sellPrice - purchasePrice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'purchase_price': purchasePrice,
      'sell_price': sellPrice,
      'quantity': quantity,
      'category': category,
      'min_stock': minStock,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      barcode: map['barcode'] as String,
      purchasePrice: map['purchase_price'] as double,
      sellPrice: map['sell_price'] as double,
      quantity: map['quantity'] as int,
      category: map['category'] as String,
      minStock: map['min_stock'] as int? ?? 5,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    double? purchasePrice,
    double? sellPrice,
    int? quantity,
    String? category,
    int? minStock,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellPrice: sellPrice ?? this.sellPrice,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      minStock: minStock ?? this.minStock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Product(id: $id, name: $name, barcode: $barcode)';
}
