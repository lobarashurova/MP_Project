import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xurmo/data/models/meal_model.dart';
import 'package:xurmo/data/repositories/favorites_repository.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoritesRepository _repository;
  List<MealModel> _favorites = [];
  Set<String> _favoriteIds = {};
  bool _isLoading = false;
  StreamSubscription? _favoritesSubscription;

  FavoritesProvider({FavoritesRepository? repository})
      : _repository = repository ?? FavoritesRepository();

  List<MealModel> get favorites => _favorites;
  Set<String> get favoriteIds => _favoriteIds;
  int get favoriteCount => _favorites.length;
  bool get isLoading => _isLoading;

  bool isFavorite(String mealId) => _favoriteIds.contains(mealId);

  void loadFavorites() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      _favorites = [];
      _favoriteIds = {};
      notifyListeners();
      return;
    }

    _favoritesSubscription?.cancel();

    _favoritesSubscription = _repository.getFavorites().listen((favoritesData) {
      try {
        _favorites = favoritesData.map((data) {
          return MealModel(
            id: data['id'] ?? '',
            name: data['name'] ?? 'Unknown Meal',
            category: data['category'] ?? 'General',
            price: (data['price'] as num?)?.toDouble() ?? 0.0,
            imageUrl: data['imageUrl'] ?? '',
            rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
            description: data['description'] ?? 'No description available', // Required field
            area: data['area'] ?? '',
            ingredients: List<String>.from(data['ingredients'] ?? []),
          );
        }).toList();

        _favoriteIds = _favorites.map((m) => m.id).toSet();
        notifyListeners();
      } catch (e) {
        debugPrint("Error parsing favorites: $e");
      }
    });
  }

  Future<void> addFavorite(MealModel meal) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _repository.addFavorite(meal.id, {
        'id': meal.id,
        'name': meal.name,
        'category': meal.category,
        'price': meal.price,
        'imageUrl': meal.imageUrl,
        'rating': meal.rating,
        'description': meal.description,
        'area': meal.area,
        'ingredients': meal.ingredients,
        'addedAt': FieldValue.serverTimestamp(),
      });


    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFavorite(String mealId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _repository.removeFavorite(mealId);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    super.dispose();
  }
}