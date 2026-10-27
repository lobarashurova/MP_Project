import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xurmo/core/errors/app_exception.dart';
import 'package:xurmo/data/models/meal_model.dart';
import 'package:xurmo/data/repositories/favorites_repository.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoritesRepository _repository;
  List<MealModel> _favorites = [];
  Set<String> _favoriteIds = {};
  bool _isLoading = false;
  bool _isSignedIn = false;
  bool _hasLoadedOnce = false;
  AppException? _failure;
  StreamSubscription? _favoritesSubscription;

  FavoritesProvider({FavoritesRepository? repository})
      : _repository = repository ?? FavoritesRepository();

  List<MealModel> get favorites => _favorites;
  Set<String> get favoriteIds => _favoriteIds;
  int get favoriteCount => _favorites.length;
  bool get isLoading => _isLoading;

  /// False when nobody is signed in — the page should prompt for sign-in
  /// instead of claiming the user has no favorites.
  bool get isSignedIn => _isSignedIn;

  AppException? get failure => _failure;
  String? get error => _failure?.message;
  bool get hasError => _failure != null;

  /// A failure with nothing on screen to fall back on.
  bool get hasBlockingError => _failure != null && _favorites.isEmpty;

  /// Loaded successfully and the list really is empty.
  bool get isEmpty => _hasLoadedOnce && _favorites.isEmpty && _failure == null;

  bool isFavorite(String mealId) => _favoriteIds.contains(mealId);

  void loadFavorites() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    _favoritesSubscription?.cancel();

    if (userId == null) {
      _favorites = [];
      _favoriteIds = {};
      _isSignedIn = false;
      _isLoading = false;
      _hasLoadedOnce = true;
      _failure = null;
      notifyListeners();
      return;
    }

    _isSignedIn = true;
    _isLoading = !_hasLoadedOnce;
    _failure = null;
    notifyListeners();

    _favoritesSubscription = _repository.getFavorites().listen(
      (favoritesData) {
        try {
          _favorites = favoritesData.map(_mapFavorite).toList();
          _favoriteIds = _favorites.map((m) => m.id).toSet();
          _failure = null;
        } catch (e) {
          debugPrint('Error parsing favorites: $e');
          _failure = AppException.from(e);
        } finally {
          _isLoading = false;
          _hasLoadedOnce = true;
          notifyListeners();
        }
      },
      onError: (Object e) {
        // Offline, permission denied, or a Firestore outage: surface it so the
        // page can show an error state with a retry instead of staying blank.
        debugPrint('Error loading favorites: $e');
        _failure = AppException.from(e);
        _isLoading = false;
        _hasLoadedOnce = true;
        notifyListeners();
      },
    );
  }

  /// Re-subscribes after a failure.
  void retry() => loadFavorites();

  MealModel _mapFavorite(Map<String, dynamic> data) {
    return MealModel(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Unknown Meal',
      category: data['category'] ?? 'General',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] ?? 'No description available',
      area: data['area'] ?? '',
      ingredients: List<String>.from(data['ingredients'] ?? []),
    );
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
      throw AppException.from(e);
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
      throw AppException.from(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Removes everything in one pass so a mid-list failure cannot leave the
  /// caller looping over a list that is mutating underneath it.
  Future<void> clearFavorites() async {
    final ids = _favorites.map((m) => m.id).toList();
    AppException? firstFailure;

    for (final id in ids) {
      try {
        await _repository.removeFavorite(id);
      } catch (e) {
        firstFailure ??= AppException.from(e);
      }
    }

    if (firstFailure != null) throw firstFailure;
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    super.dispose();
  }
}
