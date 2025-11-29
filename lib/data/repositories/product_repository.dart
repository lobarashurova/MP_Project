import 'package:hive_flutter/hive_flutter.dart';
import 'package:xurmo/core/network/network_module.dart';
import 'package:xurmo/data/models/meal_model.dart';

class ProductRepository {
  final NetworkModule _networkModule;
  final String _boxName = 'mealsBox';

  ProductRepository({NetworkModule? networkModule})
      : _networkModule = networkModule ?? NetworkModule();

  Future<List<MealModel>> fetchProducts({int count = 20, bool forceRefresh = false}) async {
    try {
      var box = await Hive.openBox<MealModel>(_boxName);

      if (box.isNotEmpty && !forceRefresh) {
        return box.values.toList();
      }

      final List<MealModel> newProducts = [];

      for (int i = 0; i < count; i++) {
        try {
          final response = await _networkModule.get('random.php');

          if (response.data != null) {
            final meals = response.data['meals'];

            if (meals != null && meals is List && meals.isNotEmpty) {
              try {
                final meal = MealModel.fromJson(meals[0] as Map<String, dynamic>);
                newProducts.add(meal);
              } catch (e) {
                continue;
              }
            }
          }
        } catch (e) {
          continue;
        }
      }

      if (newProducts.isNotEmpty) {
        await box.clear();
        await box.addAll(newProducts);
      }

      return newProducts;
    } catch (e) {
      try {
        var box = await Hive.openBox<MealModel>(_boxName);
        if (box.isNotEmpty) {
          return box.values.toList();
        }
      } catch (_) {}
      throw Exception('Failed to fetch products: $e');
    }
  }
}