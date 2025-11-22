import 'package:xurmo/data/models/product_model.dart';
import 'package:flutter/foundation.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class Cart {
  Cart._privateConstructor();
  static final Cart instance = Cart._privateConstructor();

  final List<CartItem> _items = [];

  // Notifier to trigger UI updates
  final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  List<CartItem> get items => List.unmodifiable(_items);

  // Total number of items (not quantity)
  int get totalItems => _items.length;

  // Total quantity of all items
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  void add(ProductModel product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifier.value++; // triggers UI updates
  }

  void remove(ProductModel product) {
    _items.removeWhere((item) => item.product.id == product.id);
    notifier.value++;
  }

  void increaseQuantity(ProductModel product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity++;
      notifier.value++;
    }
  }

  void decreaseQuantity(ProductModel product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0 && _items[index].quantity > 1) {
      _items[index].quantity--;
    } else if (index >= 0) {
      _items.removeAt(index);
    }
    notifier.value++;
  }

  double get totalPrice {
    return _items.fold(
        0, (sum, item) => sum + item.product.price * item.quantity);
  }

  // Helper methods for listener compatibility
  void addListener(VoidCallback listener) {
    notifier.addListener(listener);
  }

  void removeListener(VoidCallback listener) {
    notifier.removeListener(listener);
  }
}