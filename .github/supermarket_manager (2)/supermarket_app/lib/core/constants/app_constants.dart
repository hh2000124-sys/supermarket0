class AppConstants {
  static const String appName = 'مدير السوبر ماركت';
  static const String dbName = 'supermarket.db';
  static const int dbVersion = 1;
  static const int lowStockThreshold = 5;

  static const String tableProducts = 'products';
  static const String tableSales = 'sales';
  static const String tableSaleItems = 'sale_items';

  static const List<String> categories = [
    'مأكولات',
    'مشروبات',
    'منظفات',
    'عناية شخصية',
    'مواد غذائية',
    'أخرى',
  ];
}
