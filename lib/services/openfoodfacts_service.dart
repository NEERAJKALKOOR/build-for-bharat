import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenFoodFactsService {
  static const String baseUrl =
      'https://world.openfoodfacts.org/api/v2/product';

  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/$barcode.json'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'];
          return {
            'name': product['product_name'] ?? '',
            'brand': product['brands'] ?? '',
            'category': product['categories'] ?? '',
            'imageUrl': product['image_url'] ?? '',
          };
        }
      }
      return null;
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }
}
