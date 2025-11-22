import 'package:flutter/foundation.dart';
import '../models/product_model.dart';

class FavoritesManager extends ChangeNotifier {
  static final FavoritesManager _instance = FavoritesManager._internal();

  factory FavoritesManager() => _instance;

  FavoritesManager._internal();

  final Set<String> _favoriteIds = {};
  final Map<String, ProductModel> _favoriteProducts = {};

  // Get all favorite products
  List<ProductModel> get favorites => _favoriteProducts.values.toList();

  // Get favorite count
  int get favoriteCount => _favoriteProducts.length;

  // Check if a product is favorite
  bool isFavorite(String productId) {
    return _favoriteIds.contains(productId);
  }

  // Toggle favorite status
  void toggleFavorite(ProductModel product) {
    if (_favoriteIds.contains(product.id)) {
      _favoriteIds.remove(product.id);
      _favoriteProducts.remove(product.id);
    } else {
      _favoriteIds.add(product.id);
      _favoriteProducts[product.id] = product;
    }
    notifyListeners();
  }

  // Add to favorites
  void addFavorite(ProductModel product) {
    if (!_favoriteIds.contains(product.id)) {
      _favoriteIds.add(product.id);
      _favoriteProducts[product.id] = product;
      notifyListeners();
    }
  }

  // Remove from favorites
  void removeFavorite(String productId) {
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
      _favoriteProducts.remove(productId);
      notifyListeners();
    }
  }

  // Clear all favorites
  void clearFavorites() {
    _favoriteIds.clear();
    _favoriteProducts.clear();
    notifyListeners();
  }
}