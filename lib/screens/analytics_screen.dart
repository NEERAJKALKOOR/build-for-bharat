import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/bill.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedDays = 7; // Default 7 days

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.compactSimpleCurrency(locale: 'en_IN');
    final fullCurrencyFormat = NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight, // Beige/White
      appBar: AppBar(
        title: const Text('Analytics & Insights', style: TextStyle(color: AppTheme.darkNavy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.darkNavy),
        actions: [
          IconButton(onPressed: (){}, icon: const Icon(Icons.print_outlined))
        ],
      ),
      body: ValueListenableBuilder<Box<Bill>>(
        valueListenable: Hive.box<Bill>('bills').listenable(),
        builder: (context, billsBox, _) {
          return ValueListenableBuilder<Box<Product>>(
            valueListenable: Hive.box<Product>('products').listenable(),
            builder: (context, productsBox, _) {
              
              // --- CORE DATA PROCESSING ---
              final now = DateTime.now();
              final startDate = now.subtract(Duration(days: _selectedDays));
              
              // Filter Bills
              final periodBills = billsBox.values.where((b) => b.timestamp.isAfter(startDate)).toList();
              
              // Revenue
              final totalRevenue = periodBills.fold<double>(0, (sum, b) => sum + b.total);
              final totalOrders = periodBills.length;
              final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
              
              // Previous Period Comparison (Simple approx)
              final prevStartDate = startDate.subtract(Duration(days: _selectedDays));
              final prevBills = billsBox.values.where((b) => b.timestamp.isAfter(prevStartDate) && b.timestamp.isBefore(startDate)).toList();
              final prevRevenue = prevBills.fold<double>(0, (sum, b) => sum + b.total);
              final growth = prevRevenue > 0 ? ((totalRevenue - prevRevenue) / prevRevenue) * 100 : 100.0;

              // Daily Sales for Chart
              final dailyMap = <int, double>{};
              for(int i = 0; i < _selectedDays; i++) {
                final d = now.subtract(Duration(days: i));
                dailyMap[DateTime(d.year, d.month, d.day).millisecondsSinceEpoch] = 0.0;
              }
              for(var b in periodBills) {
                 final d = DateTime(b.timestamp.year, b.timestamp.month, b.timestamp.day);
                 dailyMap[d.millisecondsSinceEpoch] = (dailyMap[d.millisecondsSinceEpoch] ?? 0) + b.total;
              }
              final chartSpots = dailyMap.entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList()
                  ..sort((a,b) => a.x.compareTo(b.x));

              // Top Products
              final productQtyMap = <String, double>{};
              final productRevMap = <String, double>{};
              final productNameMap = <String, String>{};
              for(var b in periodBills) {
                 for(var item in b.items) {
                    productQtyMap[item.productId] = (productQtyMap[item.productId] ?? 0) + item.quantity;
                    productRevMap[item.productId] = (productRevMap[item.productId] ?? 0) + item.total;
                    productNameMap[item.productId] = item.name;
                 }
              }
              final topProductsQty = productQtyMap.entries.toList()
                 ..sort((a, b) => b.value.compareTo(a.value));
              final topProductsRev = productRevMap.entries.toList()
                 ..sort((a, b) => b.value.compareTo(a.value));

              // Dead Stock Logic (Slow moving)
              // Calculate last sale date for each product
              final lastSaleMap = <String, DateTime>{};
              for(var b in billsBox.values) { // Check ALL bills for last sale
                for(var item in b.items) {
                   final existing = lastSaleMap[item.productId];
                   if(existing == null || b.timestamp.isAfter(existing)) {
                     lastSaleMap[item.productId] = b.timestamp;
                   }
                }
              }
              final products = productsBox.values.toList();
              final deadStock = products.where((p) {
                 final last = lastSaleMap[p.id];
                 if (last == null) return true; // Never sold
                 final daysSince = now.difference(last).inDays;
                 return daysSince > 30; // Not sold in 30 days
              }).toList(); // Show ALL dead stock here for count, take 5 later



              // Category Data
              final categoryMap = <String, double>{};
              for(var b in periodBills) {
                for(var item in b.items) {
                   // Find product to get category
                   final p = productsBox.get(item.productId); // Might need null check if deleted
                   final cat = p?.category ?? 'Other';
                   categoryMap[cat] = (categoryMap[cat] ?? 0) + item.total;
                }
              }

              // --- BUSINESS PATTERNS LOGIC ---
              final hourlyCounts = <int, int>{};
              final dayCounts = <int, double>{}; // Weekday -> Revenue (or count)
              
              for (var b in billsBox.values) { // Analyse ALL time for better patterns, or periodBills? Let's use periodBills for trend
                 final dt = b.timestamp;
                 // Hourly
                 hourlyCounts[dt.hour] = (hourlyCounts[dt.hour] ?? 0) + 1;
                 // Daily
                 dayCounts[dt.weekday] = (dayCounts[dt.weekday] ?? 0) + b.total;
              }
              
              // Peak Hour
              int maxHourlyCount = 0;
              int peakHour = 12;
              hourlyCounts.forEach((h, c) {
                if (c > maxHourlyCount) {
                  maxHourlyCount = c;
                  peakHour = h;
                }
              });
              final peakSuffix = peakHour >= 12 ? 'PM' : 'AM';
              final peakHour12 = peakHour > 12 ? peakHour - 12 : (peakHour == 0 ? 12 : peakHour);
              final peakHourTime = maxHourlyCount == 0 ? '--' : '$peakHour12 $peakSuffix - ${peakHour12 == 12 ? 1 : peakHour12 + 1} $peakSuffix';

              // Busiest Day
              int busiestDay = 1;
              double maxDayRev = 0;
              dayCounts.forEach((d, r) {
                 if (r > maxDayRev) {
                   maxDayRev = r;
                   busiestDay = d;
                 }
              });
              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              final busiestDayName = maxDayRev == 0 ? '--' : days[busiestDay - 1];

              // --- ADVANCED INSIGHTS ---
              // --- ADVANCED INSIGHTS ---
              // 1. Top Category
              String topCategoryName = 'None';
              double topCatRev = 0;
              categoryMap.forEach((c, r) {
                 if(r > topCatRev) {
                    topCatRev = r;
                    topCategoryName = c;
                 }
              });
              final topCatPct = totalRevenue > 0 ? (topCatRev / totalRevenue * 100).toInt() : 0;
              
              // 2. Basket Size Analysis
              
              // 2. Basket Size Analysis
              int basketSmall = 0; // < ₹100
              int basketMedium = 0; // ₹100 - ₹500
              int basketLarge = 0; // > ₹500
              for (var b in periodBills) {
                 if (b.total < 100) basketSmall++;
                 else if (b.total <= 500) basketMedium++;
                 else basketLarge++;
              }
              final totalBaskets = periodBills.length > 0 ? periodBills.length : 1;

              // Smart Insights Generation (Moved here)
              final insights = <String>[];
              if (topProductsQty.isNotEmpty) {
                 final topName = productNameMap[topProductsQty.first.key] ?? 'Item';
                 final val = topProductsQty.first.value;
                 insights.add('$topName is trending — highest sales: ${val.toInt()} units.');
              }
              if (deadStock.isNotEmpty) {
                 insights.add('${deadStock.length} products haven\'t sold in 30 days — consider clearing.');
              }
              // Category Contribution
              if (topCategoryName != 'None') {
                 insights.add('$topCategoryName category contributes $topCatPct% to your revenue.');
              }
              if (insights.isEmpty) insights.add('Collect more sales data to generate smart insights.');

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🟣 SECTION A: Time Filter
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildTimeFilter(7, '7 Days'),
                          const SizedBox(width: 8),
                          _buildTimeFilter(30, '30 Days'),
                          const SizedBox(width: 8),
                          _buildTimeFilter(90, '90 Days'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 🟢 SECTION B: Revenue Overview Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppTheme.blueGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                           BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Revenue', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                                child: Row(
                                  children: [
                                    Icon(growth >= 0 ? Icons.trending_up : Icons.trending_down, color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text('${growth.abs().toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(fullCurrencyFormat.format(totalRevenue), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              _buildWhiteMetric('Bills', totalOrders.toString()),
                              const SizedBox(width: 24),
                              _buildWhiteMetric('Avg Order', currencyFormat.format(avgOrderValue)),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 🟦 SECTION C: Business Patterns (Cool Insights)
                    const Text('Business Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.cardShadowLight),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [Icon(Icons.access_time_filled_rounded, color: Colors.orange, size: 18), SizedBox(width: 8), Text('Peak Time', style: TextStyle(color: AppTheme.textMuted, fontSize: 12))]),
                                const SizedBox(height: 8),
                                Text(peakHourTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.darkNavy)),
                                Text('Most bills generated', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                            child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.cardShadowLight),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [Icon(Icons.calendar_today_rounded, color: AppTheme.electricPurple, size: 18), SizedBox(width: 8), Text('Busiest Day', style: TextStyle(color: AppTheme.textMuted, fontSize: 12))]),
                                const SizedBox(height: 8),
                                Text(busiestDayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.darkNavy)),
                                Text('Highest revenue day', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    


                    // ✨ NEW INSIGHTS: Winning Category & Baskets
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF6B46C1), Color(0xFF805AD5)]),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(color: const Color(0xFF6B46C1).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                            ),
                            child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Row(children: [Icon(Icons.emoji_events_rounded, color: Colors.white, size: 16), SizedBox(width: 8), Text('Winning Category', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10))]),
                                 const SizedBox(height: 8),
                                 Text(topCategoryName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                                 const SizedBox(height: 4),
                                 Text('$topCatPct% of total sales', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold)),
                               ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppTheme.cardShadowLight),
                            child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 const Text('Basket Size', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                 const SizedBox(height: 12),
                                 _buildBasketBar('Small', basketSmall, totalBaskets, Colors.blue),
                                 const SizedBox(height: 8),
                                 _buildBasketBar('Med', basketMedium, totalBaskets, Colors.orange),
                                 const SizedBox(height: 8),
                                 _buildBasketBar('Large', basketLarge, totalBaskets, Colors.teal),
                               ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),



                    // 🟨 SECTION E1: Top Selling (Volume)
                    const Text('Top Sellers (Volume)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                    const SizedBox(height: 16),
                    Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.cardShadowLight),
                          child: Column(
                            children: topProductsQty.take(5).toList().asMap().entries.map((entry) {
                               final index = entry.key;
                               final item = entry.value;
                               final name = productNameMap[item.key] ?? 'Unknown';
                               return Column(
                                 children: [
                                   ListTile(
                                     leading: CircleAvatar(
                                       backgroundColor: index < 3 ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.grey[100],
                                       child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: index < 3 ? AppTheme.primaryBlue : Colors.grey)),
                                     ),
                                     title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                     trailing: Text('${item.value.toInt()} units', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.darkNavy)),
                                   ),
                                   if (index != topProductsQty.take(5).length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
                                 ],
                               );
                            }).toList(),
                          ),
                    ),
                    const SizedBox(height: 32),

                    // 🟨 SECTION E2: Top Grossing (Revenue)
                    const Text('Top Earning Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                    const SizedBox(height: 16),
                    Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.cardShadowLight),
                          child: Column(
                            children: topProductsRev.take(5).toList().asMap().entries.map((entry) {
                               final index = entry.key;
                               final item = entry.value;
                               final name = productNameMap[item.key] ?? 'Unknown';
                               return Column(
                                 children: [
                                   ListTile(
                                     leading: CircleAvatar(
                                       backgroundColor: index < 3 ? Colors.amber.withOpacity(0.1) : Colors.grey[100],
                                       child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: index < 3 ? Colors.amber[800] : Colors.grey)),
                                     ),
                                     title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                     trailing: Text(fullCurrencyFormat.format(item.value), style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.darkNavy)),
                                   ),
                                   if (index != topProductsRev.take(5).length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
                                 ],
                               );
                            }).toList(),
                          ),
                    ),
                    const SizedBox(height: 32),

                    // 🟧 SECTION F: Slow Moving / Dead Stock
                    const Text('Dead & Slow Stock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.error)),
                    const SizedBox(height: 4),
                    Text('Items with no sales in 30+ days', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(height: 16),
                    if (deadStock.isEmpty)
                       Container(
                         padding: const EdgeInsets.all(20),
                         decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.withOpacity(0.2))),
                         child: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Inventory is healthy!')]),
                       )
                    else 
                       Container(
                         decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppTheme.cardShadowLight,
                            border: Border.all(color: AppTheme.error.withOpacity(0.2)),
                          ),
                         child: Column(
                            children: deadStock.take(5).map((p) {
                               final last = lastSaleMap[p.id];
                               final days = last == null ? 'Never Sold' : '${now.difference(last).inDays}d ago';
                               return ListTile(
                                 title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                 subtitle: Text('Instock: ${p.quantity.toInt()}'),
                                 trailing: Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                   decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                   child: Text(days, style: const TextStyle(color: AppTheme.error, fontSize: 12, fontWeight: FontWeight.bold)),
                                 ),
                               );
                            }).toList(),
                         ),
                       ),
                    
                    const SizedBox(height: 32),

                    // 🟫 SECTION H: Daily Summary Insights (AI)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.softLavender,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.darkNavy.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Row(children: [
                              Icon(Icons.auto_awesome, color: AppTheme.darkNavy, size: 20),
                              const SizedBox(width: 8),
                              const Text('Daily AI Summary', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                           ]),
                           const SizedBox(height: 16),
                           ...insights.map((msg) => Padding(
                             padding: const EdgeInsets.only(bottom: 12),
                             child: Row(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                                 Expanded(child: Text(msg, style: const TextStyle(fontSize: 14, color: AppTheme.textDark, height: 1.4))),
                               ],
                             ),
                           )).toList(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                    
                    // 🟩 SECTION I: Export Reports
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: (){ 
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export feature coming in v1.1'))); 
                        },
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text('Export Full Report (PDF)'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppTheme.darkNavy),
                          foregroundColor: AppTheme.darkNavy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTimeFilter(int days, String label) {
    bool isSelected = _selectedDays == days;
    return GestureDetector(
      onTap: () => setState(() => _selectedDays = days),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.darkNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.darkNavy),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.darkNavy,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBasketBar(String label, int count, int total, Color color) {
    if (total == 0) return const SizedBox();
    final pct = count / total;
    return Row(
      children: [
        SizedBox(width: 32, child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))),
        Expanded(
          child: Stack(
            children: [
               Container(height: 6, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10))),
               FractionallySizedBox(widthFactor: pct, child: Container(height: 6, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)))),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text('${(pct*100).toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }



  Widget _buildWhiteMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
      ],
    );
  }
}