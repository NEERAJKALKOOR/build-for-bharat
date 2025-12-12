import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/openfoodfacts_service.dart';

class InventoryProvider with ChangeNotifier {
  final ProductService _productService;
  final OpenFoodFactsService _apiService;

  InventoryProvider(this._productService, this._apiService);

  List<Product> get products => _productService.getAllProducts();
  List<Product> get lowStockProducts => _productService.getLowStockProducts();

  Future<Map<String, dynamic>?> fetchProductByBarcode(String barcode) async {
    return await _apiService.getProductByBarcode(barcode);
  }

  Product? getProductByBarcode(String barcode) {
    return _productService.getProductByBarcode(barcode);
  }

  Future<void> addProduct(Product product) async {
    await _productService.addProduct(product);
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    await _productService.updateProduct(product);
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    await _productService.deleteProduct(id);
    notifyListeners();
  }

  Future<void> updateQuantity(String productId, int change) async {
    await _productService.updateQuantity(productId, change.toDouble());
    notifyListeners();
  }

  Future<String> exportInventory() async {
    return Future.value('');
  }

  Future<void> importInventory(String json) async {
    notifyListeners();
  }
}