import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/billing_provider.dart';
import '../providers/inventory_provider.dart';

class FinalizeBillScreen extends StatefulWidget {
  const FinalizeBillScreen({Key? key}) : super(key: key);

  @override
  State<FinalizeBillScreen> createState() => _FinalizeBillScreenState();
}

class _FinalizeBillScreenState extends State<FinalizeBillScreen> {
  final _upiIdController = TextEditingController(text: '7892886596@axl');
  bool _showUpiQr = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _upiIdController.dispose();
    super.dispose();
  }

  Future<void> _finalizeBill() async {
    setState(() => _isProcessing = true);

    try {
      final billing = context.read<BillingProvider>();
      await billing.finalizeBill();

      if (!mounted) return;

      context.read<InventoryProvider>();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('✓ Bill Saved'),
          content: const Text('Transaction completed successfully!\nInventory has been updated.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _generateUpiString(double amount) {
    final upiId = _upiIdController.text.trim();
    return 'upi://pay?pa=$upiId&pn=BharatStore&am=$amount&cu=INR';
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalize Bill'),
      ),
      body: Consumer<BillingProvider>(
        builder: (context, billing, _) {
          final cart = billing.currentCart;
          final total = billing.cartTotal;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bill Summary',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Divider(),
                        ...cart.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('${item.name} x ${item.quantity}'),
                              ),
                              Text(
                                currencyFormat.format(item.total),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )),
                        const Divider(),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'TOTAL',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              currencyFormat.format(total),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Payment Options',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _upiIdController,
                          decoration: const InputDecoration(
                            labelText: 'UPI ID (Optional)',
                            hintText: 'yourname@upi',
                            prefixIcon: Icon(Icons.account_balance_wallet),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _showUpiQr = !_showUpiQr),
                          icon: Icon(_showUpiQr ? Icons.qr_code : Icons.qr_code_scanner),
                          label: Text(_showUpiQr ? 'HIDE UPI QR' : 'GENERATE UPI QR'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        ),
                        if (_showUpiQr) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                QrImageView(
                                  data: _generateUpiString(total),
                                  version: QrVersions.auto,
                                  size: 200,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Scan to pay ${currencyFormat.format(total)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _finalizeBill,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Colors.green,
                  ),
                  child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('CONFIRM & SAVE BILL'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}