import 'package:xurmo/core/errors/app_exception.dart';
import 'package:xurmo/core/network/network_module.dart';
import 'package:xurmo/data/models/meal_model.dart';

class MealRepository {
  final NetworkModule _networkModule;

  MealRepository({NetworkModule? networkModule})
      : _networkModule = networkModule ?? NetworkModule();

  /// Fetches up to [count] random meals.
  ///
  /// Stops early on a connectivity failure rather than waiting out [count]
  /// timeouts, and only throws when it could not gather a single meal.
  Future<List<MealModel>> fetchRandomMeals(int count) async {
    final List<MealModel> meals = [];
    AppException? lastFailure;

    for (int i = 0; i < count; i++) {
      try {
        final response = await _networkModule.get('random.php');

        final mealsData = response.data is Map ? response.data['meals'] : null;
        if (mealsData is List && mealsData.isNotEmpty) {
          meals.add(MealModel.fromJson(mealsData[0] as Map<String, dynamic>));
        }
      } catch (e) {
        lastFailure = AppException.from(e);
        if (lastFailure.isConnectivityIssue) break;
      }
    }

    if (meals.isEmpty && lastFailure != null) throw lastFailure;

    return meals;
  }

  Future<MealModel> fetchRandomMeal() async {
    try {
      final response = await _networkModule.get('random.php');

      final mealsData = response.data is Map ? response.data['meals'] : null;
      if (mealsData is List && mealsData.isNotEmpty) {
        return MealModel.fromJson(mealsData[0] as Map<String, dynamic>);
      }

      throw const AppException(
        AppErrorType.server,
        'We could not load that meal. Please try again.',
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
