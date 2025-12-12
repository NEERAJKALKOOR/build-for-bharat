import 'package:bharat_store/services/parallel_product_lookup_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Quick test script to verify the Parallel Product Lookup API
void main() async {
  print('🧪 Testing Parallel Product Lookup API...\n');
  
  // Initialize Hive
  await Hive.initFlutter();
  
  final service = ParallelProductLookupService();
  
  // Test barcodes
  final testBarcodes = {
    'Nutella': '3017620422003',
    'Coca-Cola': '5449000000996',
    'L\'Oréal Shampoo': '3600523307876',
    'Whiskas Cat Food': '5000213007174',
    'Invalid Product': '1234567890123',
  };
  
  for (final entry in testBarcodes.entries) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Testing: ${entry.key}');
    print('Barcode: ${entry.value}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final stopwatch = Stopwatch()..start();
    final product = await service.lookupProduct(entry.value);
    stopwatch.stop();
    
    if (product != null && product.isValid) {
      print('✅ SUCCESS (${stopwatch.elapsedMilliseconds}ms)');
      print('   Name: ${product.name}');
      print('   Brand: ${product.brand ?? 'N/A'}');
      print('   Category: ${product.category ?? 'N/A'}');
      print('   Source: ${product.source}');
      print('   Image: ${product.imageUrl != null ? 'Yes' : 'No'}');
    } else {
      print('❌ NOT FOUND (${stopwatch.elapsedMilliseconds}ms)');
      print('   Expected for invalid barcodes');
    }
    print('');
  }
  
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('✅ API Test Complete!');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  
  await Hive.close();
}
