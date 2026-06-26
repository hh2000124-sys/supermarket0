import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/product.dart';
import '../../core/services/product_repository.dart';
import '../../core/utils/formatters.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final ProductRepository _productRepo = ProductRepository();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterCategory = 'الكل';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _productRepo.getAllProducts();
      setState(() {
        _products = products;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    _filteredProducts = _products.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.barcode.contains(_searchQuery);
      final matchesCategory = _filterCategory == 'الكل' || p.category == _filterCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilter();
    });
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف "${product.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _productRepo.deleteProduct(product.id!);
      _loadProducts();
    }
  }

  void _editProduct(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditProductSheet(
        product: product,
        onSave: _loadProducts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المخزون'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو الباركود...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _onSearch(''),
                      )
                    : null,
              ),
            ),
          ),
          if (_filterCategory != 'الكل')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Chip(
                label: Text(_filterCategory),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _filterCategory = 'الكل';
                    _applyFilter();
                  });
                },
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? const Center(child: Text('لا توجد منتجات'))
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        child: ListView.builder(
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return _ProductListItem(
                              product: product,
                              onDelete: () => _deleteProduct(product),
                              onEdit: () => _editProduct(product),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add_product').then((_) => _loadProducts()),
        icon: const Icon(Icons.add),
        label: const Text('منتج جديد'),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصفية حسب التصنيف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['الكل', ...AppConstants.categories].map((cat) {
            return RadioListTile<String>(
              title: Text(cat),
              value: cat,
              groupValue: _filterCategory,
              onChanged: (v) {
                setState(() {
                  _filterCategory = v!;
                  _applyFilter();
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ProductListItem extends StatelessWidget {
  final Product product;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ProductListItem({
    required this.product,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'تعديل',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'حذف',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: product.isLowStock
                  ? AppColors.error.withOpacity(0.1)
                  : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              product.isLowStock ? Icons.warning_amber : Icons.inventory_2,
              color: product.isLowStock ? AppColors.error : AppColors.primary,
            ),
          ),
          title: Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الباركود: ${product.barcode}'),
              Text('التصنيف: ${product.category}'),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.currency(product.sellPrice),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'الكمية: ${Formatters.number(product.quantity)}',
                style: TextStyle(
                  fontSize: 13,
                  color: product.isLowStock ? AppColors.error : AppColors.textSecondary,
                  fontWeight: product.isLowStock ? FontWeight.bold : null,
                ),
              ),
            ],
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}

class _EditProductSheet extends StatefulWidget {
  final Product product;
  final VoidCallback onSave;

  const _EditProductSheet({required this.product, required this.onSave});

  @override
  State<_EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends State<_EditProductSheet> {
  late TextEditingController _nameController;
  late TextEditingController _sellPriceController;
  late TextEditingController _quantityController;
  late TextEditingController _minStockController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _sellPriceController = TextEditingController(text: widget.product.sellPrice.toString());
    _quantityController = TextEditingController(text: widget.product.quantity.toString());
    _minStockController = TextEditingController(text: widget.product.minStock.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'تعديل المنتج',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'اسم المنتج'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sellPriceController,
                  decoration: const InputDecoration(labelText: 'سعر البيع'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(labelText: 'الكمية'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _minStockController,
            decoration: const InputDecoration(labelText: 'الحد الأدنى للتنبيه'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final updated = widget.product.copyWith(
                name: _nameController.text,
                sellPrice: double.parse(_sellPriceController.text),
                quantity: int.parse(_quantityController.text),
                minStock: int.parse(_minStockController.text),
              );
              await ProductRepository().updateProduct(updated);
              widget.onSave();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('حفظ التعديلات'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
