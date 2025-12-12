import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/bill.dart';
import '../models/product.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Today's Sales
            ValueListenableBuilder(
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

                return _buildStatCard(
                  'Today\'s Sales',
                  currencyFormat.format(todaySales),
                  Icons.today,
                  Colors.blue,
                  subtitle: '${todayBills.length} transaction${todayBills.length != 1 ? 's' : ''}',
                );
              },
            ),
            const SizedBox(height: 12),

            // Weekly Sales
            ValueListenableBuilder(
              valueListenable: Hive.box<Bill>('bills').listenable(),
              builder: (context, Box<Bill> box, _) {
                final cutoff = DateTime.now().subtract(const Duration(days: 7));
                final weeklyBills = box.values.where((bill) => bill.timestamp.isAfter(cutoff)).toList();

                final weeklySales = weeklyBills.fold<double>(
                  0,
                  (sum, bill) => sum + bill.total,
                );

                return _buildStatCard(
                  'Last 7 Days Sales',
                  currencyFormat.format(weeklySales),
                  Icons.calendar_month,
                  Colors.green,
                  subtitle: '${weeklyBills.length} transaction${weeklyBills.length != 1 ? 's' : ''}',
                );
              },
            ),
            const SizedBox(height: 12),

            // Low Stock Alert
            ValueListenableBuilder(
              valueListenable: Hive.box<Product>('products').listenable(),
              builder: (context, Box<Product> box, _) {
                final lowStockProducts = box.values.where((p) => p.quantity < p.threshold).toList();

                return _buildStatCard(
                  'Low Stock Items',
                  '${lowStockProducts.length}',
                  Icons.warning,
                  Colors.red,
                  subtitle: lowStockProducts.isEmpty ? 'All good!' : 'Needs attention',
                );
              },
            ),
            const SizedBox(height: 12),

            // Total Inventory Value
            ValueListenableBuilder(
              valueListenable: Hive.box<Product>('products').listenable(),
              builder: (context, Box<Product> box, _) {
                final totalValue = box.values.fold<double>(
                  0,
                  (sum, product) => sum + (product.price * product.quantity),
                );

                return _buildStatCard(
                  'Total Inventory Value',
                  currencyFormat.format(totalValue),
                  Icons.inventory,
                  Colors.purple,
                  subtitle: '${box.length} unique product${box.length != 1 ? 's' : ''}',
                );
              },
            ),
            const SizedBox(height: 24),

            // Top Selling Products
            const Text(
              'Top Selling Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder(
              valueListenable: Hive.box<Bill>('bills').listenable(),
              builder: (context, Box<Bill> box, _) {
                final productSales = <String, int>{};
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
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No sales data yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  );
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: topProducts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final product = entry.value;
                        final name = productNames[product.key] ?? 'Unknown';
                        final quantity = product.value;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _getColorForRank(index),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                '$quantity sold',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Sales Trend Chart (Last 7 Days)
            const Text(
              'Sales Trend (Last 7 Days)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder(
              valueListenable: Hive.box<Bill>('bills').listenable(),
              builder: (context, Box<Bill> box, _) {
                return _buildSalesChart(box.values.toList());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForRank(int rank) {
    switch (rank) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  Widget _buildSalesChart(List<Bill> bills) {
    final Map<int, double> dailySales = {};
    final now = DateTime.now();

    // Initialize last 7 days with 0
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
      dailySales[key] = 0;
    }

    // Aggregate sales by day
    for (final bill in bills) {
      final billDate = DateTime(bill.timestamp.year, bill.timestamp.month, bill.timestamp.day);
      final key = billDate.millisecondsSinceEpoch;
      if (dailySales.containsKey(key)) {
        dailySales[key] = (dailySales[key] ?? 0) + bill.total;
      }
    }

    final sortedEntries = dailySales.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final maxY = sortedEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY > 0 ? (maxY * 1.2).ceilToDouble() : 100,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('dd').format(date),
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '₹${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: sortedEntries.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.value.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.value,
                      color: Colors.orange,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}