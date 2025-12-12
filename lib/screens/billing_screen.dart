import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/billing_provider.dart';
import '../providers/inventory_provider.dart';
import '../models/product.dart';
import 'barcode_scanner_screen.dart';
import 'billing_cart_screen.dart';
import 'sales_history_screen.dart';
import '../constants/product_units.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({Key? key}) : super(key: key);

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  String _searchQuery = '';

  Future<double?> _showQuantityDialog(Product product) async {
    final bool allowDecimal = ProductUnits.supportsDecimal(product.unit);
    final TextEditingController controller = TextEditingController(text: '1');
    final scaffoldContext = context; // Capture the context that has Scaffold

    return showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        double quantity = 1.0;

        return StatefulBuilder(
          builder: (BuildContext _, StateSetter setState) {
            return AlertDialog(
              title: const Text('Enter Quantity'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Price: ₹${product.price.toStringAsFixed(2)} / ${product.unit}'),
                  Text(
                    'Available Stock: ${product.quantity} ${product.unit}',
                    style: TextStyle(
                      color:
                          product.quantity < 10 ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: allowDecimal),
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: allowDecimal
                          ? 'Quantity (decimal allowed)'
                          : 'Quantity',
                      border: const OutlineInputBorder(),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              double current =
                                  double.tryParse(controller.text) ?? 1.0;
                              double decrement = allowDecimal ? 0.1 : 1.0;
                              if (current > decrement) {
                                quantity = current - decrement;
                                controller.text = allowDecimal
                                    ? quantity.toStringAsFixed(2)
                                    : quantity.toInt().toString();
                                setState(() {});
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              double current =
                                  double.tryParse(controller.text) ?? 1.0;
                              double increment = allowDecimal ? 0.1 : 1.0;
                              if (current < product.quantity) {
                                quantity = current + increment;
                                controller.text = allowDecimal
                                    ? quantity.toStringAsFixed(2)
                                    : quantity.toInt().toString();
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    onChanged: (value) {
                      quantity = double.tryParse(value) ?? 1.0;
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: ₹${(product.price * (double.tryParse(controller.text) ?? 1.0)).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    FocusScope.of(dialogContext).unfocus();
                    Navigator.of(dialogContext).pop(null);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final qty = double.tryParse(controller.text) ?? 1.0;
                    FocusScope.of(dialogContext).unfocus();
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop(qty);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Add to Cart'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _scanAndAddProduct() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (barcode != null && mounted) {
      final inventory = context.read<InventoryProvider>();
      final product = inventory.getProductByBarcode(barcode);

      if (product != null && product.id.isNotEmpty) {
        if (product.quantity > 0) {
          // Show quantity dialog for scanned product
          final quantity = await _showQuantityDialog(product);
          if (quantity != null && mounted) {
            // Validate quantity
            if (quantity <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid quantity'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            if (quantity > product.quantity) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Only ${product.quantity} ${product.unit} available'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            context
                .read<BillingProvider>()
                .addToCart(product, quantity: quantity);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${product.name} x$quantity added to cart'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Product out of stock'),
                backgroundColor: Colors.red),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Product not found in inventory'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addProductToCart(Product product) async {
    if (product.quantity > 0) {
      // Show quantity dialog
      final quantity = await _showQuantityDialog(product);
      if (quantity != null && mounted) {
        // Validate quantity
        if (quantity <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid quantity'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        if (quantity > product.quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Only ${product.quantity} ${product.unit} available'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        context.read<BillingProvider>().addToCart(product, quantity: quantity);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} x$quantity added to cart'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Out of stock'), backgroundColor: Colors.red),
      );
    }
  }

  void _viewCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BillingCartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Consumer<BillingProvider>(
            builder: (context, billing, _) {
              final itemCount = billing.currentCart.length;
              final total = billing.cartTotal;

              return Container(
                padding: const EdgeInsets.all(16),
                color: Colors.orange.shade100,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Items: $itemCount',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'Total: ${currencyFormat.format(total)}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: itemCount > 0 ? _viewCart : null,
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('VIEW CART'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _scanAndAddProduct,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('SCAN BARCODE TO ADD'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Quick Add Products:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: Consumer<InventoryProvider>(
              builder: (context, inventory, _) {
                var products =
                    inventory.products.where((p) => p.quantity > 0).toList();

                if (_searchQuery.isNotEmpty) {
                  products = products
                      .where((p) =>
                          p.name.toLowerCase().contains(_searchQuery) ||
                          (p.barcode?.toLowerCase().contains(_searchQuery) ??
                              false))
                      .toList();
                }

                if (products.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'No products found'
                          : 'No products in stock',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildProductCard(product, currencyFormat);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, NumberFormat currencyFormat) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _addProductToCart(product),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Icon(
                    Icons.shopping_bag,
                    size: 48,
                    color: Colors.orange.shade300,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${currencyFormat.format(product.price)} / ${product.unit}',
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold),
              ),
              Text(
                'Stock: ${product.quantity} ${product.unit}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
