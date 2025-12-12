import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_data.dart';

class ParallelProductLookupService {
  // API Base URL
  static const String _openFoodFactsUrl = 'https://world.openfoodfacts.org/api/v2/product';

  /// Main method: Lookup product from OpenFoodFacts API
  Future<ProductData?> lookupProduct(String barcode) async {
    if (barcode.trim().isEmpty) {
      return null;
    }

    try {
      print('🔍 Searching barcode $barcode in OpenFoodFacts...');

      // Only use OpenFoodFacts API
      final productData = await _fetchFromFoodFacts(barcode);

      if (productData != null && productData.isValid) {
        print('✅ Product found: ${productData.name} (source: ${productData.source})');
        return productData;
      }

      print('❌ No valid product found in OpenFoodFacts');
      return null;
    } catch (e) {
      print('❌ Error in product lookup: $e');
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

  /// Generic API fetch method
  Future<ProductData?> _fetchFromApi(String url, String apiSource) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'BharatStore/1.0'},
      ).timeout(
        const Duration(seconds: 5), // 5 second timeout
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
}
