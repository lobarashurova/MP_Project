import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:xurmo/core/constants/app_pricing.dart';
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

  /// Sum of item prices times quantities, before any fees.
  double get subtotal {
    return _items.fold(
        0, (sum, item) => sum + item.product.price * item.quantity);
  }

  /// Delivery fee for the current basket. Zero when the basket is empty.
  double get deliveryFee => _items.isEmpty ? 0 : AppPricing.deliveryFee;

  /// Amount the customer pays: subtotal plus delivery fee.
  double get totalPrice => subtotal + deliveryFee;


  /// Persists the cart and tells listeners it changed.
  ///
  /// The in-memory cart has already changed when this runs, so listeners are
  /// notified even if writing to disk fails. Otherwise the screen would show
  /// a basket that no longer matches the real one. A failed write is logged
  /// and only means the change is not kept after the app restarts.
  Future<void> _saveCart() async {
    try {
      final data = _items.map((item) => item.toMap()).toList();
      await _box.put('cart_items', data);
    } catch (e, stack) {
      _logError('Could not save the cart', e, stack);
    } finally {
      notifier.value++;
    }
  }

  /// Restores the saved cart. Data that cannot be read, for example after the
  /// cart format changed, is logged and discarded so the app still opens with
  /// an empty basket instead of failing on every launch.
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
    } catch (e, stack) {
      _logError('Could not read the saved cart; starting with an empty one', e, stack);
      _items.clear();
      _box.delete('cart_items').catchError(
            (Object e, StackTrace s) => _logError('Could not clear the saved cart', e, s),
          );
    }
  }

  static void _logError(String message, Object error, StackTrace stack) {
    debugPrint('Cart: $message: $error');
    if (kDebugMode) debugPrintStack(stackTrace: stack, maxFrames: 5);
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
