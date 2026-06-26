import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/colors.dart';
import '../../core/services/product_repository.dart';
import '../../core/services/sales_repository.dart';
import '../../core/utils/formatters.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ProductRepository _productRepo = ProductRepository();
  final SalesRepository _salesRepo = SalesRepository();

  Map<String, dynamic> _dailyReport = {};
  Map<String, dynamic> _topProducts = {};
  List<Map<String, dynamic>> _monthlyData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    try {
      final daily = await _salesRepo.getDailyReport(DateTime.now());
      final top = await _salesRepo.getTopSellingProducts(limit: 5);

      final weeklyData = <Map<String, dynamic>>[];
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final report = await _salesRepo.getDailyReport(date);
        weeklyData.add({
          'date': date,
          'sales': report['total_sales'],
          'profit': report['total_profit'],
        });
      }

      setState(() {
        _dailyReport = daily;
        _topProducts = top;
        _monthlyData = weeklyData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التقارير والإحصائيات'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.today), text: 'اليوم'),
              Tab(icon: Icon(Icons.trending_up), text: 'الأكثر مبيعاً'),
              Tab(icon: Icon(Icons.show_chart), text: 'الرسم البياني'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildDailyReport(),
                  _buildTopProducts(),
                  _buildChartReport(),
                ],
              ),
      ),
    );
  }

  Widget _buildDailyReport() {
    return RefreshIndicator(
      onRefresh: _loadReports,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildReportCard(
              'مبيعات اليوم',
              Formatters.currency(_dailyReport['total_sales'] ?? 0),
              Icons.point_of_sale,
              AppColors.primary,
            ),
            const SizedBox(height: 12),
            _buildReportCard(
              'أرباح اليوم',
              Formatters.currency(_dailyReport['total_profit'] ?? 0),
              Icons.trending_up,
              AppColors.success,
            ),
            const SizedBox(height: 12),
            _buildReportCard(
              'عدد العمليات',
              Formatters.number(_dailyReport['sales_count'] ?? 0),
              Icons.receipt_long,
              AppColors.accent,
            ),
            const SizedBox(height: 12),
            _buildReportCard(
              'المنتجات المباعة',
              Formatters.number(_dailyReport['total_items'] ?? 0),
              Icons.inventory_2,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProducts() {
    final products = _topProducts['products'] as List<dynamic>? ?? [];

    if (products.isEmpty) {
      return const Center(child: Text('لا توجد بيانات كافية'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRankColor(index),
              child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
            ),
            title: Text(
              product['product_name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'الكمية: ${Formatters.number(product['total_quantity'] as int)}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.currency((product['total_revenue'] as num).toDouble()),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'ربح: ${Formatters.currency((product['total_profit'] as num).toDouble())}',
                  style: const TextStyle(fontSize: 12, color: AppColors.success),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0: return const Color(0xFFFFD700);
      case 1: return const Color(0xFFC0C0C0);
      case 2: return const Color(0xFFCD7F32);
      default: return AppColors.primary;
    }
  }

  Widget _buildChartReport() {
    if (_monthlyData.isEmpty) {
      return const Center(child: Text('لا توجد بيانات كافية'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'مبيعات آخر 7 أيام',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY(),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < _monthlyData.length) {
                          final date = _monthlyData[value.toInt()]['date'] as DateTime;
                          return Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          Formatters.number(value.toInt()),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _monthlyData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: (entry.value['sales'] as num).toDouble(),
                        color: AppColors.primary,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxY() {
    double max = 0;
    for (var data in _monthlyData) {
      final sales = (data['sales'] as num).toDouble();
      if (sales > max) max = sales;
    }
    return max > 0 ? max * 1.2 : 100;
  }
}
