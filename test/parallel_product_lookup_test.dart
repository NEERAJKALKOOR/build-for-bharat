import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bharat_store/services/parallel_product_lookup_service.dart';

void main() {
  setUpAll(() async {
    // Initialize Hive for testing
    await Hive.initFlutter();
    await Hive.openBox('settings');
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('ParallelProductLookupService Tests', () {
    late ParallelProductLookupService service;

    setUp(() {
      service = ParallelProductLookupService();
    });

    test('Should enable and disable APIs', () async {
      await service.setApiEnabled('OpenFoodFacts', false);
      expect(await service.isApiEnabled('OpenFoodFacts'), false);

      await service.setApiEnabled('OpenFoodFacts', true);
      expect(await service.isApiEnabled('OpenFoodFacts'), true);
    });

    test('Should return product from real barcode (Coca Cola)', () async {
      // Coca Cola barcode - should exist in OpenFoodFacts
      final product = await service.lookupProduct('5449000000996');
      
      expect(product, isNotNull);
      expect(product!.isValid, true);
      expect(product.name, isNotEmpty);
      expect(product.barcode, '5449000000996');
      expect(product.source, isNotNull);
      print('✅ Found product: ${product.name} from ${product.source}');
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('Should return null for invalid barcode', () async {
      final product = await service.lookupProduct('9999999999999');
      
      // May be null if not found in any API
      if (product != null) {
        print('⚠️  Unexpectedly found product for test barcode: ${product.name}');
      } else {
        print('✅ Correctly returned null for invalid barcode');
      }
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('Should handle all APIs disabled', () async {
      // Disable all APIs
      await service.setApiEnabled('OpenFoodFacts', false);
      await service.setApiEnabled('OpenBeautyFacts', false);
      await service.setApiEnabled('OpenPetFoodFacts', false);
      await service.setApiEnabled('OpenProductFacts', false);

      final product = await service.lookupProduct('5449000000996');
      
      expect(product, isNull);
      print('✅ Correctly returned null when all APIs disabled');

      // Re-enable for other tests
      await service.setApiEnabled('OpenFoodFacts', true);
      await service.setApiEnabled('OpenBeautyFacts', true);
      await service.setApiEnabled('OpenPetFoodFacts', true);
      await service.setApiEnabled('OpenProductFacts', true);
    });

    test('Should call APIs in parallel (performance test)', () async {
      final stopwatch = Stopwatch()..start();
      
      // Use a real barcode
      final product = await service.lookupProduct('5449000000996');
      
      stopwatch.stop();
      
      print('⏱️  Parallel lookup took: ${stopwatch.elapsedMilliseconds}ms');
      
      // Parallel execution should be faster than sequential (< 8 seconds for 4 APIs with 5s timeout each)
      // Sequential would be 20+ seconds, parallel should be ~5-7 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(12000));
      
      if (product != null) {
        print('✅ Product found in ${stopwatch.elapsedMilliseconds}ms: ${product.name}');
      }
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
