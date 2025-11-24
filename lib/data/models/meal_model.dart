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
}

class Ingredient {
  final String name;
  final String measure;

  Ingredient({
    required this.name,
    required this.measure,
  });
}
