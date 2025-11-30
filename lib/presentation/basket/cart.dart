import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:xurmo/data/models/meal_model.dart';

class CartItem {
  final MealModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  Map<String, dynamic> toMap() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<dynamic, dynamic> map) {
    final productMap = Map<String, dynamic>.from(map['product'] as Map);
    return CartItem(
      product: MealModel.fromJson(productMap),
      quantity: map['quantity'] as int,
    );
  }
}

class Cart {
  Cart._privateConstructor() {
    _loadCart();
  }

  static final Cart instance = Cart._privateConstructor();

  final List<CartItem> _items = [];
  final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  Box get _box => Hive.box('shopping_cart');

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItems => _items.length;

  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice {
    return _items.fold(
        0, (sum, item) => sum + item.product.price * item.quantity);
  }


  Future<void> _saveCart() async {
    try {
      final data = _items.map((item) => item.toMap()).toList();
      await _box.put('cart_items', data);
      notifier.value++;
    } catch (e) {
    }
  }

  void _loadCart() {
    try {
      if (_box.containsKey('cart_items')) {
        final data = _box.get('cart_items') as List<dynamic>;
        _items.clear();
        _items.addAll(
          data.map((e) => CartItem.fromMap(e as Map<dynamic, dynamic>)).toList(),
        );
        notifier.value++;
      }
    } catch (e) {
      _box.delete('cart_items');
    }
  }


  void add(MealModel product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    _saveCart();
  }

  void remove(MealModel product) {
    _items.removeWhere((item) => item.product.id == product.id);
    _saveCart();
  }

  void increaseQuantity(MealModel product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity++;
      _saveCart();
    }
  }

  void decreaseQuantity(MealModel product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      _saveCart();
    }
  }

  void clear() {
    _items.clear();
    _saveCart();
  }

  int getQuantity(String productId) {
    try {
      final item = _items.firstWhere(
            (item) => item.product.id == productId,
      );
      return item.quantity;
    } catch (e) {
      return 0;
    }
  }
}
