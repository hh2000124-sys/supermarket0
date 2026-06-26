import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/colors.dart';
import '../../core/models/product.dart';
import '../../core/services/product_repository.dart';
import '../../core/utils/formatters.dart';
import '../sales/sales_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final ProductRepository _productRepo = ProductRepository();
  bool _isScanning = true;
  bool _isProcessing = false;
  Product? _foundProduct;
  String? _errorMessage;

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning || _isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? barcode = barcodes.first.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _isScanning = false;
    });

    try {
      final product = await _productRepo.getProductByBarcode(barcode);

      if (mounted) {
        setState(() {
          _foundProduct = product;
          if (product == null) {
            _errorMessage = 'المنتج غير موجود في قاعدة البيانات\n\nالباركود: $barcode';
          }
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ أثناء البحث';
          _isProcessing = false;
        });
      }
    }
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _foundProduct = null;
      _errorMessage = null;
      _isProcessing = false;
    });
  }

  void _sellProduct() {
    if (_foundProduct == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SalesScreen(initialProduct: _foundProduct),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مسح الباركود'),
        actions: [
          if (!_isScanning)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetScanner,
              tooltip: 'مسح جديد',
            ),
        ],
      ),
      body: _isScanning ? _buildScanner() : _buildResult(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          onDetect: _onDetect,
          fit: BoxFit.cover,
        ),
        _buildScannerOverlay(),
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'جاري البحث...',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScannerOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.6),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 80),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.qr_code_scanner, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'وجه الكاميرا نحو الباركود',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CornerDecoration(),
                    _CornerDecoration(),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CornerDecoration(),
                    _CornerDecoration(),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'سيتم قراءة الباركود تلقائياً',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    if (_errorMessage != null) {
      return _buildErrorResult();
    }

    if (_foundProduct != null) {
      return _buildProductResult();
    }

    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorResult() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 80),
            const SizedBox(height: 24),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _resetScanner,
              icon: const Icon(Icons.refresh),
              label: const Text('مسح مرة أخرى'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/add_product'),
              child: const Text('إضافة منتج جديد'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductResult() {
    final product = _foundProduct!;
    final isLowStock = product.isLowStock;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'تم العثور على المنتج',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoRow('اسم المنتج', product.name),
                  _buildInfoRow('الباركود', product.barcode),
                  _buildInfoRow('التصنيف', product.category),
                  _buildInfoRow('سعر الشراء', Formatters.currency(product.purchasePrice)),
                  _buildInfoRow('سعر البيع', Formatters.currency(product.sellPrice)),
                  _buildInfoRow(
                    'الربح',
                    Formatters.currency(product.profit),
                    valueColor: AppColors.success,
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'الكمية المتاحة: ',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        Formatters.number(product.quantity),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isLowStock ? AppColors.error : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  if (isLowStock)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber, color: AppColors.error, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'مخزون منخفض!',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: product.quantity > 0 ? _sellProduct : null,
              icon: const Icon(Icons.shopping_cart, size: 28),
              label: const Text(
                'بيع المنتج',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _resetScanner,
              icon: const Icon(Icons.refresh),
              label: const Text('مسح منتج آخر'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerDecoration extends StatelessWidget {
  const _CornerDecoration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.primary, width: 4),
          left: BorderSide(color: AppColors.primary, width: 4),
        ),
      ),
    );
  }
}
