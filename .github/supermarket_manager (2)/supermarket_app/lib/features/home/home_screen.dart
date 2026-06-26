import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/services/product_repository.dart';
import '../../core/services/sales_repository.dart';
import '../../core/utils/formatters.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductRepository _productRepo = ProductRepository();
  final SalesRepository _salesRepo = SalesRepository();

  int _totalProducts = 0;
  int _lowStockCount = 0;
  double _todaySales = 0;
  double _todayProfit = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final products = await _productRepo.getTotalProductsCount();
      final lowStock = await _productRepo.getLowStockCount();
      final dailyReport = await _salesRepo.getDailyReport(DateTime.now());

      setState(() {
        _totalProducts = products;
        _lowStockCount = lowStock;
        _todaySales = dailyReport['total_sales'] as double;
        _todayProfit = dailyReport['total_profit'] as double;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدير السوبر ماركت'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDashboardCards(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildLowStockAlert(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDashboardCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _DashboardCard(
          title: 'إجمالي المنتجات',
          value: Formatters.number(_totalProducts),
          icon: Icons.inventory_2,
          color: AppColors.primary,
        ),
        _DashboardCard(
          title: 'مخزون منخفض',
          value: Formatters.number(_lowStockCount),
          icon: Icons.warning_amber,
          color: _lowStockCount > 0 ? AppColors.error : AppColors.success,
        ),
        _DashboardCard(
          title: 'مبيعات اليوم',
          value: Formatters.currency(_todaySales),
          icon: Icons.point_of_sale,
          color: AppColors.accent,
        ),
        _DashboardCard(
          title: 'ربح اليوم',
          value: Formatters.currency(_todayProfit),
          icon: Icons.trending_up,
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'العمليات السريعة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _ActionCard(
              title: 'المبيعات',
              subtitle: 'تسجيل مبيعات جديدة',
              icon: Icons.shopping_cart,
              color: AppColors.primary,
              onTap: () => Navigator.pushNamed(context, '/sales'),
            ),
            _ActionCard(
              title: 'المخزون',
              subtitle: 'إدارة المنتجات',
              icon: Icons.inventory,
              color: AppColors.accent,
              onTap: () => Navigator.pushNamed(context, '/inventory'),
            ),
            _ActionCard(
              title: 'إضافة منتج',
              subtitle: 'منتج جديد للمخزون',
              icon: Icons.add_box,
              color: AppColors.success,
              onTap: () => Navigator.pushNamed(context, '/add_product'),
            ),
            _ActionCard(
              title: 'التقارير',
              subtitle: 'إحصائيات وتحليلات',
              icon: Icons.bar_chart,
              color: Colors.purple,
              onTap: () => Navigator.pushNamed(context, '/reports'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLowStockAlert() {
    if (_lowStockCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppColors.error, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تنبيه: مخزون منخفض!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'يوجد $_lowStockCount منتجات تحتاج إعادة شراء',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/inventory'),
            child: const Text('عرض'),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
