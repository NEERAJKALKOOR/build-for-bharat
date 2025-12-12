import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import '../models/product.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({Key? key}) : super(key: key);

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  String _searchQuery = '';
  bool _showLowStockOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: Icon(_showLowStockOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () => setState(() => _showLowStockOnly = !_showLowStockOnly),
            tooltip: 'Show low stock only',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
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
                        Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty 
                            ? 'No products found' 
                            : 'No products yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap + to add your first product',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: products.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: product.isLowStock ? Colors.red.shade50 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: product.isLowStock ? Colors.red : Colors.blue,
          child: Text(
            product.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.barcode != null) Text('Barcode: ${product.barcode}'),
            Text('Price: ${currencyFormat.format(product.price)}'),
            Row(
              children: [
                Text(
                  'Stock: ${product.quantity}',
                  style: TextStyle(
                    color: product.isLowStock ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text('(Alert at ${product.threshold})'),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (product.isLowStock)
              const Icon(Icons.warning, color: Colors.red),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditProductScreen(product: product)),
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}