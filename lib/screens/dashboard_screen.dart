import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/bill.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import 'billing_screen.dart';
import 'inventory_list_screen.dart';
import 'sales_history_screen.dart';
import 'settings_screen.dart';
import 'add_product_screen.dart';
import 'analytics_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final currencyFormat = NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 0);
  final smallCurrency = NumberFormat.compactSimpleCurrency(locale: 'en_IN');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: ValueListenableBuilder<Box<Bill>>(
          valueListenable: Hive.box<Bill>('bills').listenable(),
          builder: (context, billsBox, _) {
            return ValueListenableBuilder<Box<Product>>(
              valueListenable: Hive.box<Product>('products').listenable(),
              builder: (context, productsBox, _) {
                
                // --- DATA PROCESSING ---
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final yesterday = today.subtract(const Duration(days: 1));

                // 1. Today's Metrics
                final billsList = billsBox.values.toList();
                final todayBills = billsList.where((b) {
                  final d = b.timestamp;
                  return d.year == today.year && d.month == today.month && d.day == today.day;
                }).toList();
                
                final todayRevenue = todayBills.fold<double>(0, (sum, b) => sum + b.total);
                
                // 2. Low Stock
                final products = productsBox.values.toList();
                final lowStockItems = products.where((p) => p.quantity <= 5).toList();
                final outOfStockItems = products.where((p) => p.quantity == 0).toList(); // Subset of low stock usually, or strict 0
                
                // 3. Top Selling Today
                final itemSales = <String, double>{}; // Name -> Qty
                for (var bill in todayBills) {
                  for (var item in bill.items) {
                    itemSales[item.name] = (itemSales[item.name] ?? 0) + item.quantity;
                  }
                }
                final sortedItems = itemSales.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final topItems = sortedItems.take(5).toList();

                // 4. Comparison (Yesterday)
                final yesterdayBills = billsList.where((b) {
                  final d = b.timestamp;
                  return d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day;
                }).toList();
                final yesterdayRevenue = yesterdayBills.fold<double>(0, (sum, b) => sum + b.total);
                
                // Inventory Value
                final inventoryValue = products.fold<double>(0, (sum, p) => sum + (p.price * p.quantity));


                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🟢 SECTION A: Header
                      _buildHeader(),
                      const SizedBox(height: 24),

                      // 🟦 SECTION B: Quick Metrics Row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        child: Row(
                          children: [
                            _buildMicroCard('Today\'s Sales', smallCurrency.format(todayRevenue), AppTheme.primaryBlue, Icons.currency_rupee),
                            const SizedBox(width: 12),
                            _buildMicroCard('Bills Today', todayBills.length.toString(), AppTheme.hotPink, Icons.receipt),
                            const SizedBox(width: 12),
                            _buildMicroCard('Low Stock', lowStockItems.length.toString(), AppTheme.error, Icons.warning_amber_rounded, isAlert: lowStockItems.isNotEmpty),
                            const SizedBox(width: 12),
                            _buildMicroCard('Products', products.length.toString(), AppTheme.tealAccent, Icons.inventory_2),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 🟩 SECTION C: Quick Action Buttons (High Visibility)
                      const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildQuickActionButton(
                            'Add Product', 
                            Icons.add_box_rounded, 
                            AppTheme.primaryBlue, 
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()))
                          ),
                          _buildQuickActionButton(
                            'New Bill', 
                            Icons.receipt_long_rounded, 
                            AppTheme.darkNavy, 
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillingScreen()))
                          ),
                          _buildQuickActionButton(
                            'Search', 
                            Icons.search_rounded, 
                            Colors.orange, 
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryListScreen()))
                          ),
                          _buildQuickActionButton(
                            'Backup', 
                            Icons.cloud_upload_rounded, 
                            Colors.purple, 
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // 🟧 SECTION D: Active Alerts (If any)
                      if (lowStockItems.isNotEmpty || outOfStockItems.isNotEmpty) ...[
                        Row(
                           children: [
                             const Icon(Icons.info_outline_rounded, color: AppTheme.error, size: 20),
                             const SizedBox(width: 8),
                             const Text('Attention Needed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.error)),
                             const Spacer(),
                             TextButton(
                               onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryListScreen(showLowStock: true))),
                               child: const Text('View All'),
                             )
                           ]
                        ),
                        const SizedBox(height: 8),
                        if (outOfStockItems.isNotEmpty)
                          _buildAlertCard(
                            '${outOfStockItems.length} items out of stock!',
                            'Stock up immediately to avoid lost sales.',
                            AppTheme.error,
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryListScreen(showLowStock: true))),
                          ),
                        
                        if (lowStockItems.isNotEmpty && outOfStockItems.isEmpty) // Only show this if OOS is empty or separate? Let's show filtered
                          _buildAlertCard(
                             '${lowStockItems.length} items running low',
                             'Tap to view low stock inventory.',
                             Colors.orange,
                             () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryListScreen(showLowStock: true))),
                          ),
                        const SizedBox(height: 32),
                      ],

                      // 🟪 SECTION E: Most Sold Today
                      if (topItems.isNotEmpty) ...[
                        Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             const Text('Most Sold Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                               decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                               child: const Text('Top 5', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                             )
                           ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppTheme.cardShadowLight,
                          ),
                          child: Column(
                            children: topItems.asMap().entries.map((entry) {
                               final index = entry.key;
                               final item = entry.value;
                               return Column(
                                 children: [
                                   ListTile(
                                     leading: CircleAvatar(
                                       backgroundColor: AppTheme.backgroundLight,
                                       child: Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                                     ),
                                     title: Text(item.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                                     trailing: Text(
                                       '${item.value.toInt()} sold', 
                                       style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryBlue)
                                     ),
                                   ),
                                   if (index != topItems.length - 1)
                                      const Divider(height: 1, indent: 16, endIndent: 16),
                                 ],
                               );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],


                      // 🟨 SECTION F: Quick Summary Cards
                      const Text('Business Snapshot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                           Expanded(
                             child: _buildSummaryCard(
                               'Performance', 
                               'vs Yesterday', 
                               todayRevenue >= yesterdayRevenue ? Icons.trending_up : Icons.trending_down,
                               todayRevenue >= yesterdayRevenue ? Colors.green : Colors.red,
                               '${((todayRevenue - yesterdayRevenue).abs()).toStringAsFixed(0)} diff',
                               () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
                             ),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: _buildSummaryCard(
                               'Inventory', 
                               'Total Value', 
                               Icons.account_balance_wallet,
                               AppTheme.electricPurple,
                               smallCurrency.format(inventoryValue),
                               () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
                             ),
                           ),
                        ],
                      ),
                      
                      const SizedBox(height: 100), // Bottom padding
                    ],
                  ),
                );
              }
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Namma Kirani', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.cloud_done_outlined, size: 14, color: AppTheme.success),
                const SizedBox(width: 4),
                Text(
                  'Backup: Today, 10:00 AM', 
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)
                ),
              ],
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: AppTheme.cardShadowLight,
          ),
          child: IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            icon: const Icon(Icons.person, color: AppTheme.darkNavy),
          ),
        ),
      ],
    );
  }

  Widget _buildMicroCard(String label, String value, Color color, IconData icon, {bool isAlert = false}) {
    return Container(
      width: 140, // Fixed width
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAlert ? Colors.red.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isAlert ? Border.all(color: Colors.red.withOpacity(0.3)) : null,
        boxShadow: isAlert ? [] : AppTheme.cardShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: isAlert ? Colors.red : color, size: 20),
              if (isAlert) const Icon(Icons.circle, color: Colors.red, size: 8),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isAlert ? Colors.red : AppTheme.darkNavy)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20), // Squircle
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark)
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.priority_high_rounded, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color.withOpacity(0.8)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String subtitle, IconData icon, Color color, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(20),
           boxShadow: AppTheme.cardShadowLight,
         ),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(
                     color: color.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child: Icon(icon, color: color, size: 18),
                 ),
                 // Icon(Icons.more_horiz, color: Colors.grey[300]),
               ],
             ),
             const SizedBox(height: 16),
             Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy)),
             const SizedBox(height: 2),
             Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
             const SizedBox(height: 12),
             Container(
               width: double.infinity,
               padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
               decoration: BoxDecoration(
                 color: AppTheme.backgroundLight,
                 borderRadius: BorderRadius.circular(10),
               ),
               child: Text(
                 value,
                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                 overflow: TextOverflow.ellipsis,
               ),
             ),
           ],
         ),
      ),
    );
  }
}
