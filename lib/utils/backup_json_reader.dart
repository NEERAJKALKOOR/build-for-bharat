import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/bill.dart';
import '../models/auth_model.dart';

/// Restores Hive boxes from backup JSON
class BackupJsonReader {
  Future<void> restoreFromJson(String jsonString) async {
    print('📦 Restoring from JSON...');

    final Map<String, dynamic> data = jsonDecode(jsonString);

    // Validate format
    if (!data.containsKey('products') || !data.containsKey('bills')) {
      throw Exception('Invalid backup file format');
    }

    // Open boxes
    Box<Product> productsBox;
    if (Hive.isBoxOpen('products')) {
      productsBox = Hive.box<Product>('products');
    } else {
      productsBox = await Hive.openBox<Product>('products');
    }

    Box<Bill> billsBox;
    if (Hive.isBoxOpen('bills')) {
      billsBox = Hive.box<Bill>('bills');
    } else {
      billsBox = await Hive.openBox<Bill>('bills');
    }

    Box<AuthModel> authBox;
    if (Hive.isBoxOpen('auth')) {
      authBox = Hive.box<AuthModel>('auth');
    } else {
      authBox = await Hive.openBox<AuthModel>('auth');
    }

    // Restore Products
    final productsList = (data['products'] as List).cast<Map<String, dynamic>>();
    await productsBox.clear();
    for (var pJson in productsList) {
      final product = Product.fromJson(pJson);
      await productsBox.put(product.id, product);
    }
    print('✅ Restored ${productsList.length} products');

    // Restore Bills
    final billsList = (data['bills'] as List).cast<Map<String, dynamic>>();
    await billsBox.clear();
    for (var bJson in billsList) {
      final bill = Bill.fromJson(bJson);
      await billsBox.put(bill.id, bill);
    }
    print('✅ Restored ${billsList.length} bills');

    // Restore Auth
    if (data.containsKey('auth')) {
      final authList = (data['auth'] as List).cast<Map<String, dynamic>>();
      await authBox.clear();
      for (var aJson in authList) {
        final auth = AuthModel(
          pinHash: aJson['pinHash'],
          securityQuestion: aJson['securityQuestion'],
          securityAnswerHash: aJson['securityAnswerHash'],
        );
        await authBox.put('auth', auth); // Assuming key 'auth' for single instance
      }
      print('✅ Restored auth settings');
    }
    
    // Note: Analytics are calculated on-the-fly from bills/products, 
    // so no separate box needs to be restored for them.
  }
}
