import 'package:flutter/foundation.dart';
import 'package:xurmo/core/errors/app_exception.dart';
import 'package:xurmo/data/models/meal_model.dart';
import 'package:xurmo/data/repositories/product_repository.dart';

class HomeProvider extends ChangeNotifier {
  final ProductRepository _repository;

  HomeProvider({ProductRepository? repository})
      : _repository = repository ?? ProductRepository();

  List<MealModel> _products = [];
  bool _isLoading = false;
  bool _hasLoadedOnce = false;
  bool _isRefreshing = false;
  AppException? _failure;
  bool _isShowingCachedData = false;
  String _selectedCategory = 'All';
  String _visibleCategory = 'All';

  List<MealModel> get products => _products;
  List<MealModel> get meals => _products;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String get selectedCategory => _selectedCategory;
  String get visibleCategory => _visibleCategory;

  /// The failure from the last load, if any.
  AppException? get failure => _failure;
  String? get error => _failure?.message;
  bool get hasError => _failure != null;

  /// A blocking error: the load failed and we have nothing to show.
  bool get hasBlockingError => _failure != null && _products.isEmpty;

  /// A non-blocking error: the refresh failed but cached meals are on screen.
  bool get isShowingStaleData => _failure != null && _products.isNotEmpty;

  bool get isOffline => _failure?.isConnectivityIssue ?? false;

  /// True once a load has completed and legitimately returned nothing — an
  /// empty menu rather than a failed one.
  bool get isEmpty => _hasLoadedOnce && _products.isEmpty && _failure == null;

  bool get isShowingCachedData => _isShowingCachedData;

  List<String> get categories {
    final Set<String> categorySet = {'All'};
    for (var p in _products) {
      categorySet.add(p.category);
    }
    return categorySet.toList();
  }

  List<MealModel> getProductsByCategory(String category) {
    if (category == 'All') {
      return _products;
    }
    return _products.where((p) => p.category == category).toList();
  }

  Map<String, int> getCategoryStartIndices() {
    final Map<String, int> indices = {};
    const fixedWidgetsCount = 6;
    int currentIndex = fixedWidgetsCount;

    indices['All'] = currentIndex;

    for (final category in categories.where((c) => c != 'All')) {
      final categoryProducts = getProductsByCategory(category);
      final rows = (categoryProducts.length / 2).ceil();
      indices[category] = currentIndex;
      currentIndex += rows;
    }

    return indices;
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setVisibleCategory(String category) {
    _visibleCategory = category;
    notifyListeners();
  }

  Future<void> loadProducts() async {
    if (_isLoading) return;

    _isLoading = true;
    _failure = null;
    notifyListeners();

    await _load();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMeals() async {
    await loadProducts();
  }

  /// Pull-to-refresh / retry-after-error. Keeps existing meals on screen while
  /// the request is in flight so a failed refresh never blanks the page.
  ///
  /// Returns the failure, or null when the refresh succeeded, so the caller can
  /// surface a snackbar without reading provider state back.
  Future<AppException?> refreshProducts() async {
    if (_isRefreshing) return _failure;

    _isRefreshing = true;
    notifyListeners();

    await _load(forceRefresh: true);

    _isRefreshing = false;
    notifyListeners();
    return _failure;
  }

  /// Retry from an error state: shows the loading skeleton again because there
  /// is nothing on screen to preserve.
  Future<void> retry() async {
    if (_products.isEmpty) {
      await loadProducts();
    } else {
      await refreshProducts();
    }
  }

  Future<void> _load({bool forceRefresh = false}) async {
    try {
      final result = await _repository.fetchProducts(forceRefresh: forceRefresh);

      if (result.products.isNotEmpty) {
        _products = result.products;
      }
      _failure = result.failure;
      _isShowingCachedData = result.fromCache;
      _hasLoadedOnce = true;
    } catch (e) {
      // The repository is not supposed to throw, but never let an unexpected
      // error leave the page stuck on a spinner.
      _failure = AppException.from(e);
      _hasLoadedOnce = true;
    }
  }

  /// Clears a non-blocking error, e.g. after it has been shown in a snackbar.
  void clearError() {
    if (_failure == null) return;
    _failure = null;
    notifyListeners();
  }
}
