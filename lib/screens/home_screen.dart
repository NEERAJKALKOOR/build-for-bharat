import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import 'inventory_list_screen.dart';
import 'billing_screen.dart';
import 'analytics_screen.dart';
import 'export_import_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BharatStore'),
        centerTitle: true,
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, inventory, _) {
          final lowStockCount = inventory.lowStockProducts.length;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (lowStockCount > 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$lowStockCount item${lowStockCount > 1 ? 's' : ''} low on stock!',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildMenuTile(
                        context,
                        'Inventory',
                        Icons.inventory_2,
                        Colors.blue,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryListScreen())),
                      ),
                      _buildMenuTile(
                        context,
                        'Billing',
                        Icons.receipt_long,
                        Colors.green,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillingScreen())),
                      ),
                      _buildMenuTile(
                        context,
                        'Analytics',
                        Icons.analytics,
                        Colors.purple,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
                      ),
                      _buildMenuTile(
                        context,
                        'Share/Export',
                        Icons.share,
                        Colors.orange,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportImportScreen())),
                      ),
                      _buildMenuTile(
                        context,
                        'Settings',
                        Icons.settings,
                        Colors.grey,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}