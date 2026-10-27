import 'package:hive/hive.dart';

part 'meal_model.g.dart';

@HiveType(typeId: 0)
class MealModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final double price;

  @HiveField(4)
  final String imageUrl;

  @HiveField(5)
  final double rating;

  @HiveField(6)
  final String description;

  @HiveField(7)
  final List<String> ingredients;

  @HiveField(8)
  final String area;

  MealModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.rating,
    required this.description,
    this.ingredients = const [],
    this.area = '',
  });

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['idMeal'] as String? ?? '',
      name: json['strMeal'] as String? ?? '',
      category: json['strCategory'] as String? ?? 'Uncategorized',
      price: _calculatePrice(_parseIngredients(json).length),
      imageUrl: json['strMealThumb'] as String? ?? '',
      rating: (json['strRating'] as num?)?.toDouble() ?? 0.0,
      description: json['strInstructions'] as String? ?? '',
      area: json['strArea'] as String? ?? '',
      ingredients: _parseIngredients(json),
    );
  }

  static List<String> _parseIngredients(Map<String, dynamic> json) {
    final ingredients = <String>[];
    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'] as String?;
      if (ingredient != null && ingredient.isNotEmpty) {
        ingredients.add(ingredient);
      }
    }
    return ingredients;
  }

  MealModel copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? imageUrl,
    double? rating,
    String? description,
    List<String>? ingredients,
    String? area,
  }) {
    return MealModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      area: area ?? this.area,
    );
  }

  static double _calculatePrice(int ingredientCount) {
    // Base price: 20k
    // Add 4k per ingredient
    // Max price: 100k
    const basePrice = 20.0;
    const pricePerIngredient = 4.0;
    const maxPrice = 100.0;

    final calculatedPrice = basePrice + (ingredientCount * pricePerIngredient);
    return calculatedPrice.clamp(basePrice, maxPrice);
  }

  Map<String, dynamic> toJson() {
    return {
      'idMeal': id,
      'strMeal': name,
      'strCategory': category,
      'strPrice': price,
      'strMealThumb': imageUrl,
      'strRating': rating,
      'strInstructions': description,
      'strArea': area,
    };
  }
}