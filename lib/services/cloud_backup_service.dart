import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cloud_backup_settings.dart';
import '../models/product.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';

class CloudBackupService {
  static const String _cloudBackupBoxName = 'cloudBackupSettingsBox';
  static const String _productsBoxName = 'productsBox';
  static const String _billsBoxName = 'billsBox';
  static const String _settingsBoxName = 'settingsBox';
  static const String _dailyMetricsBoxName = 'dailyMetricsBox';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate deterministic UID from email
  String generateUserId(String email) {
    final bytes = utf8.encode(email.toLowerCase().trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Get or create cloud backup settings
  Future<CloudBackupSettings> getSettings() async {
    final box = await Hive.openBox<CloudBackupSettings>(_cloudBackupBoxName);

    if (box.isEmpty) {
      final settings = CloudBackupSettings();
      await box.put('settings', settings);
      return settings;
    }

    return box.get('settings', defaultValue: CloudBackupSettings())!;
  }

  /// Save cloud backup settings
  Future<void> saveSettings(CloudBackupSettings settings) async {
    final box = await Hive.openBox<CloudBackupSettings>(_cloudBackupBoxName);
    await box.put('settings', settings);
  }

  /// Initialize user ID from email (called after OTP login)
  Future<void> initializeUserId(String email) async {
    final settings = await getSettings();
    settings.userEmail = email;
    settings.userId = generateUserId(email);
    await saveSettings(settings);
    print('✅ User ID initialized: ${settings.userId}');
  }

  /// Build complete backup JSON from all Hive boxes
  Future<String> buildBackupJson() async {
    print('📦 Building backup JSON...');

    final settings = await getSettings();
    if (settings.userId == null) {
      throw Exception('User ID not initialized. Please login first.');
    }

    // Open all Hive boxes
    final productsBox = await Hive.openBox<Product>(_productsBoxName);
    final billsBox = await Hive.openBox<Bill>(_billsBoxName);
    final settingsBox = await Hive.openBox(_settingsBoxName);
    final dailyMetricsBox = await Hive.openBox(_dailyMetricsBoxName);

    // Convert to serializable format
    final products = productsBox.values
        .map((p) => {
              'id': p.id,
              'name': p.name,
              'barcode': p.barcode,
              'price': p.price,
              'quantity': p.quantity,
              'threshold': p.threshold,
              'imageUrl': p.imageUrl,
              'brand': p.brand,
              'category': p.category,
              'unit': p.unit,
              'source': p.source,
            })
        .toList();

    final bills = billsBox.values
        .map((b) => {
              'id': b.id,
              'timestamp': b.timestamp.toIso8601String(),
              'total': b.total,
              'items': b.items
                  .map((item) => {
                        'productId': item.productId,
                        'name': item.name,
                        'quantity': item.quantity,
                        'price': item.price,
                        'unit': item.unit,
                      })
                  .toList(),
            })
        .toList();

    final settingsData = settingsBox.toMap();
    final metricsData = dailyMetricsBox.toMap();

    final backup = {
      'uid': settings.userId,
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'products': products,
      'bills': bills,
      'settings': settingsData,
      'dailyMetrics': metricsData,
    };

    final jsonString = jsonEncode(backup);
    print('✅ Backup JSON built: ${jsonString.length} bytes');
    return jsonString;
  }

  /// Sign in anonymously to Firebase
  Future<User> signInAnonymously() async {
    print('🔐 Signing in anonymously...');

    try {
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Anonymous sign-in failed');
      }

      print('✅ Signed in anonymously: ${user.uid}');
      return user;
    } catch (e) {
      print('❌ Anonymous sign-in error: $e');
      rethrow;
    }
  }

  /// Upload backup to Firestore
  Future<void> uploadBackup(String backupJson) async {
    final settings = await getSettings();

    if (settings.userId == null) {
      throw Exception('User ID not initialized');
    }

    if (!settings.cloudBackupEnabled) {
      throw Exception('Cloud backup is disabled');
    }

    print('☁️ Uploading backup to Firestore...');

    try {
      // Sign in anonymously
      await signInAnonymously();

      // Upload to Firestore
      final docRef = _firestore
          .collection('users')
          .doc(settings.userId)
          .collection('backups')
          .doc('latestBackup');

      await docRef.set({
        'uid': settings.userId,
        'data': backupJson,
        'timestamp': FieldValue.serverTimestamp(),
        'version': '1.0.0',
      });

      print('✅ Backup uploaded successfully');
    } catch (e) {
      print('❌ Upload error: $e');
      rethrow;
    }
  }

  /// Download backup from Firestore
  Future<String?> downloadBackup() async {
    final settings = await getSettings();

    if (settings.userId == null) {
      throw Exception('User ID not initialized');
    }

    print('☁️ Downloading backup from Firestore...');

    try {
      // Sign in anonymously
      await signInAnonymously();

      // Download from Firestore
      final docRef = _firestore
          .collection('users')
          .doc(settings.userId)
          .collection('backups')
          .doc('latestBackup');

      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        print('⚠️ No backup found');
        return null;
      }

      final data = snapshot.data();
      if (data == null || !data.containsKey('data')) {
        throw Exception('Invalid backup data');
      }

      final backupJson = data['data'] as String;
      print('✅ Backup downloaded: ${backupJson.length} bytes');
      return backupJson;
    } catch (e) {
      print('❌ Download error: $e');
      rethrow;
    }
  }

  /// Restore backup from JSON
  Future<void> restoreFromJson(String backupJson) async {
    print('📥 Restoring backup...');

    try {
      final backup = jsonDecode(backupJson) as Map<String, dynamic>;

      // Validate backup structure
      if (!backup.containsKey('uid') || !backup.containsKey('timestamp')) {
        throw Exception('Invalid backup format');
      }

      // Open all Hive boxes
      final productsBox = await Hive.openBox<Product>(_productsBoxName);
      final billsBox = await Hive.openBox<Bill>(_billsBoxName);
      final settingsBox = await Hive.openBox(_settingsBoxName);
      final dailyMetricsBox = await Hive.openBox(_dailyMetricsBoxName);

      // Clear existing data
      await productsBox.clear();
      await billsBox.clear();
      await dailyMetricsBox.clear();

      // Restore products
      final products = backup['products'] as List?;
      if (products != null) {
        for (final productData in products) {
          final product = Product(
            id: productData['id'] as String,
            name: productData['name'] as String,
            barcode: productData['barcode'] as String?,
            price: (productData['price'] as num).toDouble(),
            quantity: (productData['quantity'] as num).toDouble(),
            threshold: productData['threshold'] as int,
            imageUrl: productData['imageUrl'] as String?,
            brand: productData['brand'] as String?,
            category: productData['category'] as String?,
            unit: productData['unit'] as String,
            source: productData['source'] as String?,
          );
          await productsBox.put(product.id, product);
        }
        print('✅ Restored ${products.length} products');
      }

      // Restore bills
      final bills = backup['bills'] as List?;
      if (bills != null) {
        for (final billData in bills) {
          final items = (billData['items'] as List).map((itemData) {
            return BillItem(
              productId: itemData['productId'] as String,
              name: itemData['name'] as String,
              quantity: (itemData['quantity'] as num).toDouble(),
              price: (itemData['price'] as num).toDouble(),
              unit: itemData['unit'] as String? ?? 'piece',
            );
          }).toList();

          final bill = Bill(
            id: billData['id'] as String,
            timestamp: DateTime.parse(billData['timestamp'] as String),
            total: (billData['total'] as num).toDouble(),
            items: items,
          );
          await billsBox.put(bill.id, bill);
        }
        print('✅ Restored ${bills.length} bills');
      }

      // Restore daily metrics
      final metrics = backup['dailyMetrics'] as Map<String, dynamic>?;
      if (metrics != null) {
        for (final entry in metrics.entries) {
          await dailyMetricsBox.put(entry.key, entry.value);
        }
        print('✅ Restored ${metrics.length} daily metrics');
      }

      // Don't restore settings to preserve local preferences
      print('✅ Backup restored successfully');
    } catch (e) {
      print('❌ Restore error: $e');
      rethrow;
    }
  }

  /// Main backup flow (manual trigger)
  Future<void> backupNow() async {
    print('🚀 Starting manual backup...');

    final settings = await getSettings();

    if (!settings.cloudBackupEnabled) {
      throw Exception('Cloud backup is not enabled');
    }

    if (settings.userId == null) {
      throw Exception('User ID not initialized. Please login first.');
    }

    try {
      // Build backup JSON
      final backupJson = await buildBackupJson();

      // Upload to Firestore
      await uploadBackup(backupJson);

      // Update last backup time
      settings.lastBackupTime = DateTime.now();
      await saveSettings(settings);

      print('✅ Manual backup completed successfully');
    } catch (e) {
      print('❌ Backup failed: $e');
      rethrow;
    }
  }

  /// Main restore flow (manual trigger)
  Future<void> restoreBackup() async {
    print('🚀 Starting manual restore...');

    final settings = await getSettings();

    if (settings.userId == null) {
      throw Exception('User ID not initialized. Please login first.');
    }

    try {
      // Download backup from Firestore
      final backupJson = await downloadBackup();

      if (backupJson == null) {
        throw Exception('No backup found');
      }

      // Restore from JSON
      await restoreFromJson(backupJson);

      print('✅ Manual restore completed successfully');
    } catch (e) {
      print('❌ Restore failed: $e');
      rethrow;
    }
  }
}
