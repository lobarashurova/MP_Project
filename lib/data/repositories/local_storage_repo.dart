import 'package:hive_flutter/hive_flutter.dart';
import 'package:xurmo/data/models/meal_model.dart';

class LocalStorageRepository {
  static const String favBoxName = 'favoritesBox';
  static const String cartBoxName = 'cartBox';
  static const String orderBoxName = 'ordersBox';

  Future<void> toggleFavorite(MealModel product) async {
    final box = await Hive.openBox<MealModel>(favBoxName);
    if (box.containsKey(product.id)) {
      await box.delete(product.id);
    } else {
      await box.put(product.id, product);
    }
  }

  Future<bool> isFavorite(String id) async {
    final box = await Hive.openBox<MealModel>(favBoxName);
    return box.containsKey(id);
  }

  Future<List<MealModel>> getFavorites() async {
    final box = await Hive.openBox<MealModel>(favBoxName);
    return box.values.toList();
  }

  Future<void> addToCart(MealModel product) async {
    final box = await Hive.openBox<MealModel>(cartBoxName);
    await box.add(product);
  }

  Future<List<MealModel>> getCartItems() async {
    final box = await Hive.openBox<MealModel>(cartBoxName);
    return box.values.toList();
  }

  Future<void> clearCart() async {
    final box = await Hive.openBox<MealModel>(cartBoxName);
    await box.clear();
  }

  Future<void> placeOrder(List<MealModel> items, double total) async {
    final box = await Hive.openBox(orderBoxName);

    final order = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'items': items.map((e) => e.name).toList(),
      'total': total,
      'date': DateTime.now().toIso8601String(),
      'status': 'preparing',
    };

    await box.add(order);
  }

  Future<List<Map<dynamic, dynamic>>> getOrders() async {
    final box = await Hive.openBox(orderBoxName);
    return box.values.map((e) => e as Map<dynamic, dynamic>).toList();
  }
}