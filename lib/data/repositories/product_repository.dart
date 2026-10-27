import 'package:hive_flutter/hive_flutter.dart';
import 'package:xurmo/core/errors/app_exception.dart';
import 'package:xurmo/core/network/network_module.dart';
import 'package:xurmo/core/utils/currency_formatter.dart';
import 'package:xurmo/data/models/meal_model.dart';

/// Outcome of a product load.
///
/// A load can succeed, fail outright, or half-succeed (network is down but we
/// still have a cached menu). Returning all three cases lets the UI tell an
/// empty menu apart from a failed one instead of guessing from an empty list.
class ProductsResult {
  final List<MealModel> products;

  /// Non-null when the network refresh failed. If [products] is also empty the
  /// screen has nothing to show and should render an error state; if products
  /// came from cache the screen should show them with an offline notice.
  final AppException? failure;

  /// True when [products] were read from the local Hive cache.
  final bool fromCache;

  const ProductsResult({
    required this.products,
    this.failure,
    this.fromCache = false,
  });

  bool get hasFailure => failure != null;

  bool get isEmpty => products.isEmpty;
}

class ProductRepository {
  final NetworkModule _networkModule;
  final String _boxName = 'mealsBox';

  ProductRepository({NetworkModule? networkModule})
      : _networkModule = networkModule ?? NetworkModule();

  Future<List<MealModel>> _cachedProducts() async {
    try {
      final box = await Hive.openBox<MealModel>(_boxName);
      return _normalizeCachedPrices(box);
    } catch (_) {
      // A corrupt or unavailable cache is not worth failing the screen over.
      return const [];
    }
  }

  /// Loads the menu, preferring the cache unless [forceRefresh] is set.
  ///
  /// Never throws: transport problems come back as [ProductsResult.failure] so
  /// the caller can decide between an error screen and a cached-with-notice
  /// screen.
  Future<ProductsResult> fetchProducts({
    int count = 20,
    bool forceRefresh = false,
  }) async {
    Box<MealModel>? box;
    try {
      box = await Hive.openBox<MealModel>(_boxName);

      if (box.isNotEmpty && !forceRefresh) {
        return ProductsResult(
          products: await _normalizeCachedPrices(box),
          fromCache: true,
        );
      }
    } catch (_) {
      box = null;
    }

    final List<MealModel> newProducts = [];
    AppException? lastFailure;

    for (int i = 0; i < count; i++) {
      try {
        final response = await _networkModule.get('random.php');

        final meals = response.data is Map ? response.data['meals'] : null;
        if (meals is List && meals.isNotEmpty) {
          try {
            newProducts.add(
              MealModel.fromJson(meals[0] as Map<String, dynamic>),
            );
          } catch (_) {
            // Skip a single malformed meal rather than dropping the batch.
            continue;
          }
        }
      } catch (e) {
        lastFailure = AppException.from(e);
        // Offline or timing out: the remaining 19 attempts will fail the same
        // way, so stop instead of making the user wait through every timeout.
        if (lastFailure.isConnectivityIssue) break;
      }
    }

    if (newProducts.isNotEmpty) {
      try {
        if (box != null) {
          await box.clear();
          await box.addAll(newProducts);
        }
      } catch (_) {
        // Failing to cache should not fail the load.
      }
      return ProductsResult(products: newProducts);
    }

    // Nothing came back from the network — fall back to whatever we stored.
    final cached = box != null
        ? await _normalizeCachedPrices(box)
        : await _cachedProducts();
    if (cached.isNotEmpty) {
      return ProductsResult(
        products: cached,
        failure: lastFailure ?? AppException.from(null),
        fromCache: true,
      );
    }

    return ProductsResult(
      products: const [],
      failure: lastFailure,
    );
  }

  Future<List<MealModel>> _normalizeCachedPrices(Box<MealModel> box) async {
    final products = <MealModel>[];
    for (final key in box.keys) {
      final meal = box.get(key);
      if (meal == null) continue;

      final normalizedPrice = normalizeLegacySomAmount(meal.price);
      final normalizedMeal = normalizedPrice == meal.price
          ? meal
          : meal.copyWith(price: normalizedPrice);
      if (!identical(normalizedMeal, meal)) {
        await box.put(key, normalizedMeal);
      }
      products.add(normalizedMeal);
    }
    return products;
  }
}
