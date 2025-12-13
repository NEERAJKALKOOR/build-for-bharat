import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../models/bill.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/product.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _touchedIndex = -1;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.compactSimpleCurrency(locale: 'en_IN');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Bill>('bills').listenable(),
        builder: (context, Box<Bill> box, _) {
           // Calculations
           final now = DateTime.now();
           final today = DateTime(now.year, now.month, now.day);
           
           // Today's Stats
           final todayBills = box.values.where((bill) {
              final bDate = DateTime(bill.timestamp.year, bill.timestamp.month, bill.timestamp.day);
              return bDate == today;
           }).toList();
           final todaySales = todayBills.fold<double>(0, (sum, bill) => sum + bill.total);
           
           // Weekly Data for Chart
           final weekData = List.generate(7, (index) {
              final day = today.subtract(Duration(days: 6 - index)); // Last 7 days including today
              final dayBills = box.values.where((bill) {
                 final bDate = DateTime(bill.timestamp.year, bill.timestamp.month, bill.timestamp.day);
                 return bDate == day;
              }).toList();
              final dayTotal = dayBills.fold<double>(0, (sum, bill) => sum + bill.total);
              return _ChartData(DateFormat('E').format(day), dayTotal, day);
           });

           // Overall Stats
           final totalBills = box.values.length;
           final avgOrder = totalBills > 0 ? box.values.fold<double>(0, (sum, bill) => sum + bill.total) / totalBills : 0.0;

           return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120.0,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.backgroundColor,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(
                        _greeting,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                      const Text(
                        'Dashboard',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                    ],
                  ),
                ),
                actions: [
                   Padding(
                     padding: const EdgeInsets.only(right: 16.0),
                     child: CircleAvatar(
                       backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                       child: const Icon(Icons.person, color: AppTheme.primaryColor),
                     ),
                   )
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Hero Card
                      _buildHeroCard(todaySales, todayBills.length),
                      const SizedBox(height: 24),

                      // 2. Weekly Activity Chart
                      const Text(
                        'Weekly Activity',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 220,
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
                        ),
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: weekData.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2 + 100, // Add buffer
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                tooltipBgColor: Colors.blueGrey,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    currencyFormat.format(rod.toY),
                                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  );
                                },
                              ),
                              touchCallback: (FlTouchEvent event, barTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      barTouchResponse == null ||
                                      barTouchResponse.spot == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                                });
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      child: Text(
                                        weekData[value.toInt()].label,
                                        style: TextStyle(
                                          color: value.toInt() == 6 ? AppTheme.primaryColor : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: weekData.asMap().entries.map((e) {
                              final index = e.key;
                              final data = e.value;
                              final isTouched = index == _touchedIndex;
                              final isToday = index == 6;
                              
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: data.value,
                                    color: isToday ? AppTheme.primaryColor : (isTouched ? AppTheme.primaryColor.withOpacity(0.8) : Colors.grey[200]),
                                    width: 16,
                                    borderRadius: BorderRadius.circular(6),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: (weekData.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2 + 100),
                                      color: const Color(0xfffafafa),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 3. Business Insights Scroll
                      const Text(
                        'Business Insights',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildInsightCard('Avg Order Value', currencyFormat.format(avgOrder), Icons.receipt_long, Colors.purple),
                            const SizedBox(width: 16),
                            _buildInsightCard('Total Orders', totalBills.toString(), Icons.shopping_bag, Colors.orange),
                            const SizedBox(width: 16),
                             ValueListenableBuilder(
                                valueListenable: Hive.box<Product>('products').listenable(),
                                builder: (context, Box<Product> pBox, _) {
                                   return _buildInsightCard('Products', pBox.length.toString(), Icons.inventory_2, Colors.blue);
                                }
                             ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 4. Recent Transactions List
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Transactions',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          TextButton(
                             onPressed: (){ 
                               // Navigate to history tab via main nav controller presumably, 
                               // but for now just visual.
                             }, 
                             child: const Text('View All')
                          )
                        ],
                      ),
                      // List of last 5 bills
                      ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: box.values.length > 5 ? 5 : box.values.length,
                        itemBuilder: (context, index) {
                           // Get reverse index for latest first
                           final bill = box.values.toList().reversed.toList()[index]; 
                           return Container(
                             margin: const EdgeInsets.only(bottom: 12),
                             padding: const EdgeInsets.all(16),
                             decoration: BoxDecoration(
                               color: Colors.white,
                               borderRadius: BorderRadius.circular(16),
                               border: Border.all(color: Colors.grey.shade100),
                             ),
                             child: Row(
                               children: [
                                 Container(
                                   padding: const EdgeInsets.all(10),
                                   decoration: BoxDecoration(
                                     color: Colors.green.shade50,
                                     shape: BoxShape.circle,
                                   ),
                                   child: const Icon(Icons.check, color: Colors.green, size: 16),
                                 ),
                                 const SizedBox(width: 16),
                                 Expanded(
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       Text(
                                         'Order #${bill.id.substring(0,6)}',
                                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                       ),
                                       Text(
                                         DateFormat('hh:mm a').format(bill.timestamp),
                                         style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                       ),
                                     ],
                                   ),
                                 ),
                                 Text(
                                   currencyFormat.format(bill.total),
                                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                 ),
                               ],
                             ),
                           );
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(double todaySales, int transactionCount) {
    final currencyFormat = NumberFormat.compactSimpleCurrency(locale: 'en_IN');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'TODAY',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.notifications_none, color: Colors.white, size: 18)
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Total Revenue',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(todaySales),
            style: const TextStyle(
              fontSize: 42, 
              fontWeight: FontWeight.bold, 
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$transactionCount Transactions',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  final String label;
  final double value;
  final DateTime date;
  _ChartData(this.label, this.value, this.date);
}
