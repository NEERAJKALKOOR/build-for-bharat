import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';

class ProductService {
  static const String _boxName = 'products';
  Box<Product>? _box;
  final _uuid = const Uuid();

  Future<void> init() async {
    _box = await Hive.openBox<Product>(_boxName);
  }

  List<Product> getAllProducts() {
    return _box?.values.toList() ?? [];
  }

  Product? getProduct(String id) {
    return _box?.get(id);
  }

  Product? getProductByBarcode(String barcode) {
    return _box?.values.firstWhere(
      (p) => p.barcode == barcode,
      orElse: () => Product(id: '', name: '', price: 0, quantity: 0, threshold: 0),
    );
  }

  Future<void> addProduct(Product product) async {
    if (product.id.isEmpty) {
      product.id = _uuid.v4();
    }
    await _box?.put(product.id, product);
  }

  Future<void> updateProduct(Product product) async {
    await _box?.put(product.id, product);
  }

  Future<void> deleteProduct(String id) async {
    await _box?.delete(id);
  }

  List<Product> getLowStockProducts() {
    return _box?.values.where((p) => p.isLowStock).toList() ?? [];
  }

  Future<void> updateQuantity(String productId, double quantityChange) async {
    final product = _box?.get(productId);
    if (product != null) {
      product.quantity += quantityChange;
      await product.save();
    }
  }

  List<Map<String, dynamic>> exportToJson() {
    return getAllProducts().map((p) => p.toJson()).toList();
  }

  Future<void> importFromJson(List<dynamic> jsonList, {bool merge = true}) async {
    for (var json in jsonList) {
      final product = Product.fromJson(json);
      if (merge) {
        final existing = product.barcode != null 
          ? getProductByBarcode(product.barcode!)
          : getProduct(product.id);
        if (existing?.id.isNotEmpty ?? false) continue;
      }
      await addProduct(product);
    }
  }
}