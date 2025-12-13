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
import '../theme/app_theme.dart';

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

    return showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        double quantity = 1.0;

        return StatefulBuilder(
          builder: (BuildContext _, StateSetter setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add to Cart', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: AppTheme.backgroundColor,
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         const Text('Price/Unit', style: TextStyle(color: Colors.grey)),
                         Text('₹${product.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                       ],
                     ),
                   ),
                   const SizedBox(height: 16),
                   TextField(
                     controller: controller,
                     keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
                     textAlign: TextAlign.center,
                     style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                     autofocus: true,
                     decoration: InputDecoration(
                       filled: true,
                       fillColor: Colors.white,
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                       prefixIcon: IconButton(
                         icon: const Icon(Icons.remove_circle, color: Colors.grey),
                         onPressed: () {
                              double current = double.tryParse(controller.text) ?? 1.0;
                              double decrement = allowDecimal ? 0.1 : 1.0;
                              if (current > decrement) {
                                quantity = current - decrement;
                                controller.text = allowDecimal ? quantity.toStringAsFixed(2) : quantity.toInt().toString();
                                setState(() {});
                              }
                         },
                       ),
                       suffixIcon: IconButton(
                         icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
                         onPressed: () {
                              double current = double.tryParse(controller.text) ?? 1.0;
                              double increment = allowDecimal ? 0.1 : 1.0;
                              if (current < product.quantity) {
                                quantity = current + increment;
                                controller.text = allowDecimal ? quantity.toStringAsFixed(2) : quantity.toInt().toString();
                                setState(() {});
                              }
                         },
                       ),
                     ),
                     onChanged: (val) {
                       quantity = double.tryParse(val) ?? 1.0;
                       setState((){});
                     },
                   ),
                   const SizedBox(height: 16),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const Text('Total: ', style: TextStyle(fontSize: 16)),
                       Text(
                         '₹${(product.price * (double.tryParse(controller.text) ?? 1.0)).toStringAsFixed(2)}',
                         style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                       ),
                     ],
                   ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final qty = double.tryParse(controller.text) ?? 1.0;
                    Navigator.of(dialogContext).pop(qty);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('ADD TO CART', style: TextStyle(color: Colors.white)),
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
          final quantity = await _showQuantityDialog(product);
          if (quantity != null && mounted) {
             if (quantity > product.quantity) {
                _showSnack('Only ${product.quantity} available', isError: true);
                return;
             }
             context.read<BillingProvider>().addToCart(product, quantity: quantity);
             _showSnack('${product.name} added to cart');
          }
        } else {
          _showSnack('Product out of stock', isError: true);
        }
      } else {
        _showSnack('Product not found', isError: true);
      }
    }
  }

  Future<void> _addProductToCart(Product product) async {
    if (product.quantity > 0) {
      final quantity = await _showQuantityDialog(product);
      if (quantity != null && mounted) {
        if (quantity > product.quantity) {
           _showSnack('Stock limit reached', isError: true);
           return;
        }
        context.read<BillingProvider>().addToCart(product, quantity: quantity);
        _showSnack('${product.name} added');
      }
    } else {
      _showSnack('Out of stock', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : AppTheme.primaryColor,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 1500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.compactSimpleCurrency(locale: 'en_IN');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('New Bill', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.black87),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Scan Area
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _scanAndAddProduct,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          
          // Products Grid
          Expanded(
            child: Consumer<InventoryProvider>(
              builder: (context, inventory, _) {
                var products = inventory.products.where((p) => p.quantity > 0).toList();
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
                        Icon(Icons.remove_shopping_cart, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No products found', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) => _buildProductCard(products[index], currencyFormat),
                );
              },
            ),
          ),

          // Bottom Cart Summary
          Consumer<BillingProvider>(
            builder: (context, billing, _) {
              if (billing.currentCart.isEmpty) return const SizedBox.shrink();
              
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.orange[50], shape: BoxShape.circle),
                        child: Text('${billing.currentCart.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(currencyFormat.format(billing.cartTotal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillingCartScreen())),
                        style: ElevatedButton.styleFrom(
                           backgroundColor: AppTheme.primaryColor,
                           foregroundColor: Colors.white,
                           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                           elevation: 4,
                           shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                        ),
                        child: const Row(
                           children: [
                              Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                           ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, NumberFormat format) {
    return GestureDetector(
      onTap: () => _addProductToCart(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             Expanded(
               child: Container(
                 decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                 ),
                 child: Center(
                    child: Text(
                      product.name[0].toUpperCase(),
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor.withOpacity(0.4)),
                    ),
                 ),
               ),
             ),
             Padding(
               padding: const EdgeInsets.all(12),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                   Text(
                     '${format.format(product.price)} / ${product.unit}',
                     style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
                   ),
                   const SizedBox(height: 4),
                   Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text('${product.quantity} left', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ],
                   ),
                 ],
               ),
             ),
          ],
        ),
      ),
    );
  }
}
