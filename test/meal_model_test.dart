import 'package:flutter_test/flutter_test.dart';
import 'package:xurmo/data/models/meal_model.dart';

void main() {
  group('MealModel', () {
    test('should be created from json', () {
      final jsonMap = {
        'idMeal': '52772',
        'strMeal': 'Teriyaki Chicken Casserole',
        'strCategory': 'Chicken',
        'strMealThumb':
            'https://www.themealdb.com/images/media/meals/wvpsxx1468256321.jpg',
        'strInstructions': 'Instructions for Teriyaki Chicken Casserole',
        'strArea': 'Japanese',
        'strIngredient1': 'soy sauce',
        'strIngredient2': 'water',
        'strIngredient3': 'brown sugar',
        'strIngredient4': 'ground ginger',
        'strIngredient5': 'garlic powder',
        'strIngredient6': 'chicken breasts',
        'strIngredient7': 'cornstarch',
        'strIngredient8': 'white rice',
        'strIngredient9': 'sesame seeds',
      };
      final meal = MealModel.fromJson(jsonMap);
      expect(meal.id, '52772');
      expect(meal.name, 'Teriyaki Chicken Casserole');
      expect(meal.category, 'Chicken');
      expect(meal.imageUrl,
          'https://www.themealdb.com/images/media/meals/wvpsxx1468256321.jpg');
      expect(meal.description, 'Instructions for Teriyaki Chicken Casserole');
      expect(meal.area, 'Japanese');
      expect(meal.ingredients.length, 9);
      expect(meal.price, 20.0 + (9 * 4.0));
    });
  });
}
