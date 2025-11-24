import 'product_model.dart';

class MealModel {
  final String id;
  final String name;
  final String category;
  final String area;
  final String imageUrl;
  final String instructions;
  final List<Ingredient> ingredients;

  MealModel({
    required this.id,
    required this.name,
    required this.category,
    required this.area,
    required this.imageUrl,
    required this.instructions,
    required this.ingredients,
  });

  factory MealModel.fromJson(Map<String, dynamic> json) {
    List<Ingredient> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'];
      final measure = json['strMeasure$i'];
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredients.add(Ingredient(
          name: ingredient,
          measure: measure ?? '',
        ));
      }
    }

    return MealModel(
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? '',
      category: json['strCategory'] ?? '',
      area: json['strArea'] ?? '',
      imageUrl: json['strMealThumb'] ?? '',
      instructions: json['strInstructions'] ?? '',
      ingredients: ingredients,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idMeal': id,
      'strMeal': name,
      'strCategory': category,
      'strArea': area,
      'strMealThumb': imageUrl,
      'strInstructions': instructions,
    };
  }

  // Convert MealModel to ProductModel for cart
  // Using a default price based on ingredients count
  ProductModel toProductModel() {
    // Calculate price based on ingredients (more ingredients = higher price)
    // Base price: $8.99, add $0.50 per ingredient (min $8.99, max around $18.99)
    final basePrice = 8.99;
    final ingredientPrice = ingredients.length * 0.5;
    final price = (basePrice + ingredientPrice).clamp(8.99, 18.99);
    
    // Calculate rating based on ingredients (more ingredients = slightly higher rating)
    final rating = (4.0 + (ingredients.length * 0.05)).clamp(4.0, 5.0);

    return ProductModel(
      id: id,
      name: name,
      category: category,
      price: price,
      imageUrl: imageUrl,
      rating: rating,
      description: instructions.isNotEmpty 
          ? instructions.substring(0, instructions.length > 100 ? 100 : instructions.length)
          : 'Delicious $name',
    );
  }
}

class Ingredient {
  final String name;
  final String measure;

  Ingredient({
    required this.name,
    required this.measure,
  });
}
