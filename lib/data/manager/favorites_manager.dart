import 'package:flutter/foundation.dart';
import '../models/meal_model.dart';

class FavoritesManager extends ChangeNotifier {
  static final FavoritesManager _instance = FavoritesManager._internal();

  factory FavoritesManager() => _instance;

  FavoritesManager._internal();

  final Set<String> _favoriteIds = {};
  final Map<String, MealModel> _favoriteProducts = {};

  List<MealModel> get favorites => _favoriteProducts.values.toList();

  int get favoriteCount => _favoriteProducts.length;

  bool isFavorite(String productId) {
    return _favoriteIds.contains(productId);
  }

  void toggleFavorite(MealModel product) {
    if (_favoriteIds.contains(product.id)) {
      _favoriteIds.remove(product.id);
      _favoriteProducts.remove(product.id);
    } else {
      _favoriteIds.add(product.id);
      _favoriteProducts[product.id] = product;
    }
    notifyListeners();
  }

  void addFavorite(MealModel product) {
    if (!_favoriteIds.contains(product.id)) {
      _favoriteIds.add(product.id);
      _favoriteProducts[product.id] = product;
      notifyListeners();
    }
  }

  void removeFavorite(String productId) {
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
      _favoriteProducts.remove(productId);
      notifyListeners();
    }
  }

  void clearFavorites() {
    _favoriteIds.clear();
    _favoriteProducts.clear();
    notifyListeners();
  }
}