import 'package:flutter/foundation.dart';
import '../models/bill_item.dart';
import '../models/product.dart';
import '../services/billing_service.dart';
import '../services/product_service.dart';

class BillingProvider with ChangeNotifier {
  final BillingService _billingService;
  final ProductService _productService;
  
  final List<BillItem> _currentCart = [];

  BillingProvider(this._billingService, this._productService);

  List<BillItem> get currentCart => _currentCart;
  
  double get cartTotal => _currentCart.fold(0, (sum, item) => sum + item.total);

  void addToCart(Product product, {int quantity = 1}) {
    final existingIndex = _currentCart.indexWhere((item) => item.productId == product.id);
    
    if (existingIndex >= 0) {
      _currentCart[existingIndex].quantity += quantity;
    } else {
      _currentCart.add(BillItem(
        productId: product.id,
        name: product.name,
        price: product.price,
        quantity: quantity,
        unit: product.unit,
      ));
    }
    notifyListeners();
  }

  void updateCartItemQuantity(int index, int quantity) {
    if (quantity <= 0) {
      _currentCart.removeAt(index);
    } else {
      _currentCart[index].quantity = quantity;
    }
    notifyListeners();
  }

  void updateCartItemPrice(int index, double price) {
    _currentCart[index].price = price;
    notifyListeners();
  }

  void removeFromCart(int index) {
    _currentCart.removeAt(index);
    notifyListeners();
  }

  void clearCart() {
    _currentCart.clear();
    notifyListeners();
  }

  Future<String> finalizeBill() async {
    final billId = await _billingService.saveBill(List.from(_currentCart));
    
    for (var item in _currentCart) {
      await _productService.updateQuantity(item.productId, -item.quantity);
    }
    
    clearCart();
    
    return billId;
  }
}