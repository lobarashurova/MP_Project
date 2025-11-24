import 'package:flutter/foundation.dart';
import 'package:xurmo/data/models/meal_model.dart';
import 'package:xurmo/data/repositories/meal_repository.dart';

class HomeProvider extends ChangeNotifier {
  final MealRepository _repository;

  HomeProvider({MealRepository? repository})
      : _repository = repository ?? MealRepository();

  List<MealModel> _meals = [];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'All';
  String _visibleCategory = 'All';

  List<MealModel> get meals => _meals;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get visibleCategory => _visibleCategory;

  List<String> get categories {
    final Set<String> categorySet = {'All'};
    for (var meal in _meals) {
      categorySet.add(meal.category);
    }
    return categorySet.toList();
  }

  List<MealModel> getMealsByCategory(String category) {
    if (category == 'All') {
      return _meals;
    }
    return _meals.where((meal) => meal.category == category).toList();
  }

  Map<String, int> getCategoryStartIndices() {
    final Map<String, int> indices = {};
    const fixedWidgetsCount = 6;
    int currentIndex = fixedWidgetsCount;

    indices['All'] = currentIndex;

    for (final category in categories.where((c) => c != 'All')) {
      final categoryMeals = getMealsByCategory(category);
      final rows = (categoryMeals.length / 2).ceil();
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

  Future<void> loadMeals({int count = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _meals = await _repository.fetchRandomMeals(count);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshMeals({int count = 20}) async {
    _meals = [];
    _error = null;
    await loadMeals(count: count);
  }
}
