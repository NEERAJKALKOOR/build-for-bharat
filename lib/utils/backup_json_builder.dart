import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/bill.dart';
import '../models/auth_model.dart';

/// Builds a complete backup JSON from Hive boxes
class BackupJsonBuilder {
  Future<String> buildBackupJson() async {
    print('📦 Building backup JSON...');

    // Access already open boxes or open them if needed
    // Note: Boxes are usually opened in main.dart or services.
    // We'll attempt to open them to be safe.
    
    // Products
    Box<Product> productsBox;
    if (Hive.isBoxOpen('products')) {
      productsBox = Hive.box<Product>('products');
    } else {
      productsBox = await Hive.openBox<Product>('products');
    }

    // Bills
    Box<Bill> billsBox;
    if (Hive.isBoxOpen('bills')) {
      billsBox = Hive.box<Bill>('bills');
    } else {
      billsBox = await Hive.openBox<Bill>('bills');
    }

    // Auth (Settings/Profile)
    Box<AuthModel> authBox;
    if (Hive.isBoxOpen('auth')) {
      authBox = Hive.box<AuthModel>('auth');
    } else {
      authBox = await Hive.openBox<AuthModel>('auth');
    }

    // Convert products
    final products = productsBox.values.map((p) => p.toJson()).toList();

    // Convert bills
    final bills = billsBox.values.map((b) => b.toJson()).toList();

    // Convert auth/settings
    // AuthModel doesn't have toJson, so we map manually
    final authData = authBox.values.map((a) => {
      'pinHash': a.pinHash,
      'securityQuestion': a.securityQuestion,
      'securityAnswerHash': a.securityAnswerHash,
    }).toList();

    // Construct backup object
    final backup = {
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'products': products,
      'bills': bills,
      'auth': authData,
      // 'settings': ... if there were other settings
    };

    final jsonString = jsonEncode(backup);
    print('✅ Backup JSON built: ${products.length} products, ${bills.length} bills');
    return jsonString;
  }
}
