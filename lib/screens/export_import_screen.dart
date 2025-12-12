import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/bill.dart';

class ExportImportScreen extends StatefulWidget {
  const ExportImportScreen({Key? key}) : super(key: key);

  @override
  State<ExportImportScreen> createState() => _ExportImportScreenState();
}

class _ExportImportScreenState extends State<ExportImportScreen> {
  bool _isProcessing = false;

  Future<void> _exportInventory() async {
    setState(() => _isProcessing = true);

    try {
      final box = Hive.box<Product>('products');
      final products = box.values.map((p) => p.toJson()).toList();
      
      final jsonString = const JsonEncoder.withIndent('  ').convert({
        'exportDate': DateTime.now().toIso8601String(),
        'type': 'inventory',
        'products': products,
      });

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/bharat_inventory_$timestamp.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'BharatStore Inventory Export',
        text: 'Inventory exported on ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Inventory exported: ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _exportTransactions() async {
    setState(() => _isProcessing = true);

    try {
      final box = Hive.box<Bill>('bills');
      final bills = box.values.map((b) => b.toJson()).toList();
      
      final jsonString = const JsonEncoder.withIndent('  ').convert({
        'exportDate': DateTime.now().toIso8601String(),
        'type': 'transactions',
        'bills': bills,
      });

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/bharat_transactions_$timestamp.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'BharatStore Transactions Export',
        text: 'Transactions exported on ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transactions exported: ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _importInventory() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return;

      setState(() => _isProcessing = true);

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = json.decode(jsonString);

      if (data['type'] != 'inventory') {
        throw Exception('Invalid file type. Expected inventory export.');
      }

      final products = (data['products'] as List)
        .map((p) => Product.fromJson(p))
        .toList();

      final box = Hive.box<Product>('products');
      
      // Ask user: merge or replace
      final action = await _showImportDialog('Inventory', products.length);
      
      if (action == null) return;

      if (action == 'replace') {
        await box.clear();
      }

      for (final product in products) {
        // Check for duplicates by barcode
        if (product.barcode != null) {
          final existing = box.values.firstWhere(
            (p) => p.barcode == product.barcode,
            orElse: () => Product(id: '', name: '', price: 0, quantity: 0, threshold: 0),
          );
          if (existing.id.isNotEmpty && action == 'merge') continue;
        }
        await box.put(product.id, product);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inventory imported successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _importTransactions() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return;

      setState(() => _isProcessing = true);

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = json.decode(jsonString);

      if (data['type'] != 'transactions') {
        throw Exception('Invalid file type. Expected transactions export.');
      }

      final bills = (data['bills'] as List)
        .map((b) => Bill.fromJson(b))
        .toList();

      final box = Hive.box<Bill>('bills');

      for (final bill in bills) {
        // Avoid duplicate bills by ID
        if (!box.containsKey(bill.id)) {
          await box.put(bill.id, bill);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transactions imported successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<String?> _showImportDialog(String type, int count) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import $type'),
        content: Text('Found $count item${count != 1 ? 's' : ''}. How do you want to import?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'merge'),
            child: const Text('MERGE'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'replace'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('REPLACE ALL'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export & Import'),
      ),
      body: _isProcessing
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Export Data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.inventory, color: Colors.blue),
                    title: const Text('Export Inventory'),
                    subtitle: const Text('Save all products to JSON file'),
                    trailing: ElevatedButton(
                      onPressed: _exportInventory,
                      child: const Text('EXPORT'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long, color: Colors.green),
                    title: const Text('Export Transactions'),
                    subtitle: const Text('Save all bills to JSON file'),
                    trailing: ElevatedButton(
                      onPressed: _exportTransactions,
                      child: const Text('EXPORT'),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Import Data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.upload_file, color: Colors.orange),
                    title: const Text('Import Inventory'),
                    subtitle: const Text('Load products from JSON file'),
                    trailing: ElevatedButton(
                      onPressed: _importInventory,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: const Text('IMPORT'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.upload_file, color: Colors.purple),
                    title: const Text('Import Transactions'),
                    subtitle: const Text('Load bills from JSON file'),
                    trailing: ElevatedButton(
                      onPressed: _importTransactions,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                      child: const Text('IMPORT'),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'How it works',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('• Exports create JSON files on your device'),
                      const Text('• Use "Share" to send files via WhatsApp, Email, etc.'),
                      const Text('• Import files from device storage'),
                      const Text('• Merge: Keep existing + add new items'),
                      const Text('• Replace: Delete all + add imported items'),
                      const SizedBox(height: 8),
                      Text(
                        '⚠️ No cloud/server - files stay on your device',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.blue.shade700,
                        ),
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