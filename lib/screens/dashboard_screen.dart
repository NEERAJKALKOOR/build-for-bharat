import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../models/bill.dart';
import '../models/product.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Low Stock Alert Banner
            Consumer<InventoryProvider>(
              builder: (context, inventory, _) {
                final lowStockCount = inventory.lowStockProducts.length;
                if (lowStockCount == 0) return const SizedBox(height: 16);

                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, 
                        color: AppTheme.errorColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$lowStockCount item${lowStockCount > 1 ? 's' : ''} running low on stock!',
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Stats Cards - 2 Column Grid with Square Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Row 1: Today's Sales & Weekly Sales
                  Row(
                    children: [
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: Hive.box<Bill>('bills').listenable(),
                          builder: (context, Box<Bill> box, _) {
                            final now = DateTime.now();
                            final today = DateTime(now.year, now.month, now.day);
                            
                            final todayBills = box.values.where((bill) {
                              final billDate = DateTime(
                                bill.timestamp.year,
                                bill.timestamp.month,
                                bill.timestamp.day,
                              );
                              return billDate == today;
                            }).toList();

                            final todaySales = todayBills.fold<double>(
                              0,
                              (sum, bill) => sum + bill.total,
                            );

                            return _buildSquareStatCard(
                              'Today\'s Sales',
                              currencyFormat.format(todaySales),
                              Icons.today,
                              AppTheme.primaryColor,
                              subtitle: '${todayBills.length} bills',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: Hive.box<Bill>('bills').listenable(),
                          builder: (context, Box<Bill> box, _) {
                            final cutoff = DateTime.now().subtract(const Duration(days: 7));
                            final weeklyBills = box.values.where((bill) => bill.timestamp.isAfter(cutoff)).toList();

                            final weeklySales = weeklyBills.fold<double>(
                              0,
                              (sum, bill) => sum + bill.total,
                            );

                            return _buildSquareStatCard(
                              'Weekly Sales',
                              currencyFormat.format(weeklySales),
                              Icons.calendar_month,
                              Color(0xFF059669),
                              subtitle: 'Last 7 days',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Row 2: Total Products & Total Transactions
                  Row(
                    children: [
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: Hive.box<Product>('products').listenable(),
                          builder: (context, Box<Product> box, _) {
                            return _buildSquareStatCard(
                              'Total Products',
                              '${box.values.length}',
                              Icons.inventory_2,
                              Color(0xFF3B82F6),
                              subtitle: 'In inventory',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: Hive.box<Bill>('bills').listenable(),
                          builder: (context, Box<Bill> box, _) {
                            return _buildSquareStatCard(
                              'Total Transactions',
                              '${box.values.length}',
                              Icons.receipt_long,
                              Color(0xFF8B5CF6),
                              subtitle: 'All time',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Row 3: Inventory Value & Low Stock
                  Row(
                    children: [
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: Hive.box<Product>('products').listenable(),
                          builder: (context, Box<Product> box, _) {
                            final totalValue = box.values.fold<double>(
                              0,
                              (sum, product) => sum + (product.price * product.quantity),
                            );

                            return _buildSquareStatCard(
                              'Inventory Value',
                              currencyFormat.format(totalValue),
                              Icons.account_balance_wallet,
                              Color(0xFFEC4899),
                              subtitle: 'Total worth',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: Hive.box<Product>('products').listenable(),
                          builder: (context, Box<Product> box, _) {
                            final lowStockProducts = box.values.where((p) => p.quantity < p.threshold).toList();

                            return _buildSquareStatCard(
                              'Low Stock',
                              '${lowStockProducts.length}',
                              Icons.warning_amber_rounded,
                              AppTheme.warningColor,
                              subtitle: lowStockProducts.isEmpty ? 'All good!' : 'Items',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Row 4: Most Selling Item & Average Order
                  Row(
                    children: [
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: Hive.box<Bill>('bills').listenable(),
                          builder: (context, Box<Bill> box, _) {
                            final productSales = <String, double>{};
                            final productNames = <String, String>{};

                            for (final bill in box.values) {
                              for (final item in bill.items) {
                                productSales[item.productId] = (productSales[item.productId] ?? 0) + item.quantity;
                                productNames[item.productId] = item.name;
                              }
                            }

                            final sortedProducts = productSales.entries.toList()
                              ..sort((a, b) => b.value.compareTo(a.value));

                            final topProduct = sortedProducts.isNotEmpty ? sortedProducts.first : null;
                            final topProductName = topProduct != null ? productNames[topProduct.key] ?? 'N/A' : 'N/A';
                            final topProductQty = topProduct?.value ?? 0;

                            return _buildSquareStatCard(
                              'Best Seller',
                              topProductName.length > 15 ? '${topProductName.substring(0, 15)}...' : topProductName,
                              Icons.star,
                              Color(0xFFF59E0B),
                              subtitle: '${topProductQty.toStringAsFixed(1)} units',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: Hive.box<Bill>('bills').listenable(),
                          builder: (context, Box<Bill> box, _) {
                            final bills = box.values.toList();
                            final avgOrder = bills.isEmpty ? 0.0 : bills.fold<double>(0, (sum, bill) => sum + bill.total) / bills.length;

                            return _buildSquareStatCard(
                              'Avg Order',
                              currencyFormat.format(avgOrder),
                              Icons.trending_up,
                              Color(0xFF06B6D4),
                              subtitle: 'Per transaction',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Top Selling Products
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Top Selling Products',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 12),

            ValueListenableBuilder(
              valueListenable: Hive.box<Bill>('bills').listenable(),
              builder: (context, Box<Bill> box, _) {
                final productSales = <String, double>{};
                final productNames = <String, String>{};

                for (final bill in box.values) {
                  for (final item in bill.items) {
                    productSales[item.productId] = (productSales[item.productId] ?? 0) + item.quantity;
                    productNames[item.productId] = item.name;
                  }
                }

                final sortedProducts = productSales.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                final topProducts = sortedProducts.take(5).toList();

                if (topProducts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'No sales data yet',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: topProducts.length,
                  itemBuilder: (context, index) {
                    final entry = topProducts[index];
                    final productName = productNames[entry.key] ?? 'Unknown';
                    final quantity = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppTheme.lightShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  'Sold: ${quantity.toStringAsFixed(1)} units',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return AspectRatio(
      aspectRatio: 1.15, // Slightly wider rectangle for better content fit
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
