import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import '../models/product.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import '../theme/app_theme.dart';

class InventoryListScreen extends StatefulWidget {
  final bool showLowStock;
  const InventoryListScreen({Key? key, this.showLowStock = false}) : super(key: key);

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  String _searchQuery = '';
  late bool _showLowStockOnly;

  @override
  void initState() {
    super.initState();
    _showLowStockOnly = widget.showLowStock;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Inventory', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showLowStockOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _showLowStockOnly ? AppTheme.primaryBlue : Colors.black87,
            ),
            onPressed: () => setState(() => _showLowStockOnly = !_showLowStockOnly),
            tooltip: 'Show low stock only',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              ),
            ),
          ),
          
          Expanded(
            child: Consumer<InventoryProvider>(
              builder: (context, inventory, _) {
                var products = _showLowStockOnly 
                  ? inventory.lowStockProducts 
                  : inventory.products;

                if (_searchQuery.isNotEmpty) {
                  products = products.where((p) => 
                    p.name.toLowerCase().contains(_searchQuery) ||
                    (p.barcode?.toLowerCase().contains(_searchQuery) ?? false)
                  ).toList();
                }

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _searchQuery.isNotEmpty 
                            ? 'No products found' 
                            : 'Inventory is empty',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to add items',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: products.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildProductCard(context, product);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddProductScreen()),
        ),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final currencyFormat = NumberFormat.compactSimpleCurrency(locale: 'en_IN');
    final isLowStock = product.isLowStock;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 2))],
        border: isLowStock ? Border.all(color: AppTheme.error.withOpacity(0.3)) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EditProductScreen(product: product)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Product Icon / Image Placeholder
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isLowStock ? AppTheme.error.withOpacity(0.1) : AppTheme.primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: isLowStock ? AppTheme.error : AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(product.price),
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: 14
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Stock Badge & Edit
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLowStock ? AppTheme.error.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Stock: ${product.quantity}',
                        style: TextStyle(
                          color: isLowStock ? AppTheme.error : Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (product.barcode != null && product.barcode!.isNotEmpty)
                       Padding(
                         padding: const EdgeInsets.only(top: 4.0),
                         child: Icon(Icons.qr_code_rounded, size: 16, color: Colors.grey[400]),
                       ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}