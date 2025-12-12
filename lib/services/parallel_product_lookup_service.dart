import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product_data.dart';

class ParallelProductLookupService {
  static const String _settingsBoxName = 'settingsBox';
  
  // API Base URLs
  static const String _openFoodFactsUrl = 'https://world.openfoodfacts.org/api/v2/product';
  static const String _openBeautyFactsUrl = 'https://world.openbeautyfacts.org/api/v2/product';
  static const String _openPetFoodFactsUrl = 'https://world.openpetfoodfacts.org/api/v2/product';
  static const String _openProductFactsUrl = 'https://world.openproductfacts.org/api/v2/product';

  /// Main method: Lookup product from all enabled APIs in parallel
  Future<ProductData?> lookupProduct(String barcode) async {
    if (barcode.trim().isEmpty) {
      return null;
    }

    try {
      // Get enabled APIs from settings
      final enabledApis = await _getEnabledApis();

      // Build list of futures based on enabled APIs
      final futures = <Future<ProductData?>>[];

      if (enabledApis['openFoodFacts'] == true) {
        futures.add(_fetchFromFoodFacts(barcode));
      }
      if (enabledApis['openBeautyFacts'] == true) {
        futures.add(_fetchFromBeautyFacts(barcode));
      }
      if (enabledApis['openPetFoodFacts'] == true) {
        futures.add(_fetchFromPetFoodFacts(barcode));
      }
      if (enabledApis['openProductFacts'] == true) {
        futures.add(_fetchFromProductFacts(barcode));
      }

      if (futures.isEmpty) {
        print('⚠️ All product APIs are disabled in settings');
        return null;
      }

      print('🔍 Searching barcode $barcode in ${futures.length} databases...');

      // Execute all API calls in parallel
      final results = await Future.wait(
        futures,
        eagerError: false, // Don't stop on first error
      );

      // Filter valid results
      final validResults = results.where((r) => r != null && r.isValid).toList();

      if (validResults.isEmpty) {
        print('❌ No valid product found in any database');
        return null;
      }

      // Return first valid result
      final product = validResults.first;
      print('✅ Product found: ${product?.name} (source: ${product?.source})');
      return product;
    } catch (e) {
      print('❌ Error in parallel product lookup: $e');
      return null;
    }
  }

  /// Fetch from OpenFoodFacts API
  Future<ProductData?> _fetchFromFoodFacts(String barcode) async {
    return _fetchFromApi(
      '$_openFoodFactsUrl/$barcode.json',
      'OpenFoodFacts',
    );
  }

  /// Fetch from OpenBeautyFacts API
  Future<ProductData?> _fetchFromBeautyFacts(String barcode) async {
    return _fetchFromApi(
      '$_openBeautyFactsUrl/$barcode.json',
      'OpenBeautyFacts',
    );
  }

  /// Fetch from OpenPetFoodFacts API
  Future<ProductData?> _fetchFromPetFoodFacts(String barcode) async {
    return _fetchFromApi(
      '$_openPetFoodFactsUrl/$barcode.json',
      'OpenPetFoodFacts',
    );
  }

  /// Fetch from OpenProductFacts API
  Future<ProductData?> _fetchFromProductFacts(String barcode) async {
    return _fetchFromApi(
      '$_openProductFactsUrl/$barcode.json',
      'OpenProductFacts',
    );
  }

  /// Generic API fetch method
  Future<ProductData?> _fetchFromApi(String url, String apiSource) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'BharatStore/1.0'},
      ).timeout(
        const Duration(seconds: 5), // 5 second timeout per API
        onTimeout: () {
          print('⏱️ Timeout: $apiSource');
          return http.Response('{"status": 0}', 408);
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final status = json['status'] as int?;

        if (status == 1) {
          // Product found
          final productData = ProductData.fromJson(json, apiSource);
          if (productData.isValid) {
            print('✅ $apiSource: Found "${productData.name}"');
            return productData;
          } else {
            print('⚠️ $apiSource: Product found but no name');
          }
        } else {
          print('❌ $apiSource: Product not found (status: $status)');
        }
      } else {
        print('❌ $apiSource: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ $apiSource: Error - $e');
    }

    return null;
  }

  /// Get enabled APIs from settings (all enabled by default)
  Future<Map<String, bool>> _getEnabledApis() async {
    try {
      final box = await Hive.openBox(_settingsBoxName);
      
      return {
        'openFoodFacts': box.get('api_openFoodFacts', defaultValue: true) as bool,
        'openBeautyFacts': box.get('api_openBeautyFacts', defaultValue: true) as bool,
        'openPetFoodFacts': box.get('api_openPetFoodFacts', defaultValue: true) as bool,
        'openProductFacts': box.get('api_openProductFacts', defaultValue: true) as bool,
      };
    } catch (e) {
      print('⚠️ Error reading API settings: $e');
      // Return all enabled by default
      return {
        'openFoodFacts': true,
        'openBeautyFacts': true,
        'openPetFoodFacts': true,
        'openProductFacts': true,
      };
    }
  }

  /// Update API enabled status
  Future<void> setApiEnabled(String apiName, bool enabled) async {
    try {
      final box = await Hive.openBox(_settingsBoxName);
      await box.put('api_$apiName', enabled);
      print('⚙️ $apiName ${enabled ? "enabled" : "disabled"}');
    } catch (e) {
      print('❌ Error updating API setting: $e');
    }
  }

  /// Get API enabled status
  Future<bool> isApiEnabled(String apiName) async {
    try {
      final box = await Hive.openBox(_settingsBoxName);
      return box.get('api_$apiName', defaultValue: true) as bool;
    } catch (e) {
      return true; // Default to enabled
    }
  }
}
