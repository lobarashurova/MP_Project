import 'package:xurmo/core/network/network_module.dart';
import 'package:xurmo/data/models/meal_model.dart';

class MealRepository {
  final NetworkModule _networkModule;

  MealRepository({NetworkModule? networkModule})
      : _networkModule = networkModule ?? NetworkModule();

  Future<List<MealModel>> fetchRandomMeals(int count) async {
    try {
      final List<MealModel> meals = [];

      for (int i = 0; i < count; i++) {
        final response = await _networkModule.get('random.php');

        if (response.data != null && response.data['meals'] != null) {
          final mealsData = response.data['meals'] as List;
          if (mealsData.isNotEmpty) {
            meals.add(MealModel.fromJson(mealsData[0]));
          }
        }
      }

      return meals;
    } catch (e) {
      throw Exception('Failed to fetch meals: $e');
    }
  }

  Future<MealModel> fetchRandomMeal() async {
    try {
      final response = await _networkModule.get('random.php');

      if (response.data != null && response.data['meals'] != null) {
        final mealsData = response.data['meals'] as List;
        if (mealsData.isNotEmpty) {
          return MealModel.fromJson(mealsData[0]);
        }
      }

      throw Exception('No meal data found');
    } catch (e) {
      throw Exception('Failed to fetch meal: $e');
    }
  }
}
