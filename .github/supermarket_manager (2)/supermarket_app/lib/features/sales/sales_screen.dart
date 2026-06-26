import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/models/product.dart';
import '../../core/services/product_repository.dart';
import '../../core/services/sales_repository.dart';
import '../../core/utils/formatters.dart';

class SalesScreen extends StatefulWidget {
  final Product? initialProduct;

  const SalesScreen({super.key, this.initialProduct});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final ProductRepository _productRepo = ProductRepository();
  final SalesRepository _salesRepo = SalesRepository();

  final List<Map<String, dynamic>> _cart = [];
  final _barcodeController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialProduct != null) {
      _addToCart(widget.initialProduct!, 1);
    }
  }

  void _addToCart(Product product, int quantity) {
    if (product.quantity < quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الكمية المطلوبة غير متوفرة'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final existingIndex = _cart.indexWhere((item) => item['product'].id == product.id);

    setState(() {
      if (existingIndex >= 0) {
        final newQty = _cart[existingIndex]['quantity'] + quantity;
        if (product.quantity < newQty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('الكمية المطلوبة غير متوفرة')),
          );
          return;
        }
        _cart[existingIndex]['quantity'] = newQty;
      } else {
        _cart.add({
          'product': product,
          'quantity': quantity,
        });
      }
    });
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.pushNamed(context, '/barcode_scanner');
  }

  Future<void> _searchByBarcode() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) return;

    final product = await _productRepo.getProductByBarcode(barcode);
    if (product != null) {
      _addToCart(product, int.parse(_quantityController.text));
      _barcodeController.clear();
      _quantityController.text = '1';
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('المنتج غير موجود'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _completeSale() async {
    if (_cart.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      await _salesRepo.createSale(_cart);

      if (mounted) {
        setState(() {
          _cart.clear();
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت عملية البيع بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  double get _totalAmount => _cart.fold(
    0, (sum, item) => sum + (item['product'].sellPrice * item['quantity']),
  );

  double get _totalProfit => _cart.fold(
    0, (sum, item) => sum + (item['product'].profit * item['quantity']),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نقطة البيع')),
      body: Column(
        children: [
          _buildSearchSection(),
          Expanded(
            child: _cart.isEmpty
                ? _buildEmptyCart()
                : _buildCartList(),
          ),
          _buildTotalSection(),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _barcodeController,
              decoration: InputDecoration(
                hintText: 'أدخل الباركود...',
                prefixIcon: const Icon(Icons.qr_code),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: _scanBarcode,
                  tooltip: 'مسح بالكاميرا',
                ),
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _searchByBarcode(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'الكمية',
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _searchByBarcode,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'السلة فارغة',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'امسح باركود المنتج أو أدخله يدوياً',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList() {
    return ListView.builder(
      itemCount: _cart.length,
      itemBuilder: (context, index) {
        final item = _cart[index];
        final product = item['product'] as Product;
        final quantity = item['quantity'] as int;

        return Dismissible(
          key: Key(product.id.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            color: AppColors.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            setState(() => _cart.removeAt(index));
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text('${index + 1}'),
              ),
              title: Text(product.name),
              subtitle: Text(
                '${Formatters.currency(product.sellPrice)} × ${Formatters.number(quantity)}',
              ),
              trailing: Text(
                Formatters.currency(product.sellPrice * quantity),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الإجمالي:', style: TextStyle(fontSize: 16)),
                Text(
                  Formatters.currency(_totalAmount),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الربح المتوقع:', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                Text(
                  Formatters.currency(_totalProfit),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _cart.isEmpty || _isProcessing ? null : _completeSale,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle, size: 28),
                label: Text(
                  _isProcessing ? 'جاري المعالجة...' : 'إتمام البيع',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
