import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:xurmo/core/errors/app_exception.dart';
import 'package:xurmo/core/widgets/state_view.dart';
import 'package:xurmo/data/models/meal_model.dart';
import 'package:xurmo/data/repositories/product_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:xurmo/data/repositories/favorites_repository.dart';
import 'package:xurmo/presentation/favorites/provider/favorites_provider.dart';
import 'package:xurmo/presentation/home/providers/home_provider.dart';
import 'package:xurmo/presentation/search/search_page.dart';

/// Stands in for the real repository so we can drive every load outcome:
/// success, empty, offline-with-nothing-cached and offline-with-cache.
class FakeProductRepository extends ProductRepository {
  FakeProductRepository(this.result);

  ProductsResult result;
  int callCount = 0;

  @override
  Future<ProductsResult> fetchProducts({
    int count = 20,
    bool forceRefresh = false,
  }) async {
    callCount++;
    return result;
  }
}

MealModel buildMeal({String id = '1', String name = 'Teriyaki Chicken'}) {
  return MealModel(
    id: id,
    name: name,
    category: 'Chicken',
    price: 12.0,
    imageUrl: '',
    rating: 4.5,
    description: 'Tasty.',
    area: 'Japanese',
  );
}

Widget wrapWithProvider(Widget child, HomeProvider provider) {
  // Search results are MealCards, which read FavoritesProvider, so the
  // wrapper has to supply it alongside the HomeProvider under test.
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<HomeProvider>.value(value: provider),
      ChangeNotifierProvider<FavoritesProvider>(
        create: (_) => FavoritesProvider(
          repository: FavoritesRepository(),
          authStateChanges: const Stream<User?>.empty(),
        ),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('AppException classification', () {
    test('maps a Dio connection error to an offline failure', () {
      final failure = AppException.from(
        DioException(
          requestOptions: RequestOptions(path: '/random.php'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(failure.type, AppErrorType.noConnection);
      expect(failure.isConnectivityIssue, isTrue);
      expect(failure.title, "You're offline");
      expect(failure.message, contains('No internet connection'));
    });

    test('maps a timeout to a retryable timeout failure', () {
      final failure = AppException.from(
        DioException(
          requestOptions: RequestOptions(path: '/random.php'),
          type: DioExceptionType.receiveTimeout,
        ),
      );

      expect(failure.type, AppErrorType.timeout);
      expect(failure.isConnectivityIssue, isTrue);
    });

    test('maps a 500 to a server failure, not an offline one', () {
      final options = RequestOptions(path: '/random.php');
      final failure = AppException.from(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: 500),
        ),
      );

      expect(failure.type, AppErrorType.server);
      expect(failure.isConnectivityIssue, isFalse);
    });

    test('maps a 403 to an authorization failure', () {
      final options = RequestOptions(path: '/random.php');
      final failure = AppException.from(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: 403),
        ),
      );

      expect(failure.type, AppErrorType.unauthorized);
    });

    test('never leaks a raw exception string to the user', () {
      final failure = AppException.from(
        Exception('Bad state: FormatException at offset 42'),
      );

      expect(failure.type, AppErrorType.unknown);
      expect(failure.message, 'Something went wrong. Please try again.');
      expect(failure.message, isNot(contains('FormatException')));
    });

    test('passes an existing AppException through unchanged', () {
      const original = AppException.noConnection();
      expect(AppException.from(original), same(original));
    });
  });

  group('HomeProvider load outcomes', () {
    test('an offline load with no cache is a blocking error', () async {
      final provider = HomeProvider(
        repository: FakeProductRepository(
          const ProductsResult(
            products: [],
            failure: AppException.noConnection(),
          ),
        ),
      );

      await provider.loadProducts();

      expect(provider.hasBlockingError, isTrue);
      expect(provider.isOffline, isTrue);
      expect(provider.isEmpty, isFalse, reason: 'failed is not the same as empty');
      expect(provider.isLoading, isFalse);
    });

    test('an offline load with a cache keeps meals and flags stale data', () async {
      final provider = HomeProvider(
        repository: FakeProductRepository(
          ProductsResult(
            products: [buildMeal()],
            failure: const AppException.noConnection(),
            fromCache: true,
          ),
        ),
      );

      await provider.loadProducts();

      expect(provider.hasBlockingError, isFalse);
      expect(provider.isShowingStaleData, isTrue);
      expect(provider.isShowingCachedData, isTrue);
      expect(provider.meals, hasLength(1));
    });

    test('a successful but empty load is an empty state, not an error', () async {
      final provider = HomeProvider(
        repository: FakeProductRepository(
          const ProductsResult(products: []),
        ),
      );

      await provider.loadProducts();

      expect(provider.isEmpty, isTrue);
      expect(provider.hasError, isFalse);
      expect(provider.hasBlockingError, isFalse);
    });

    test('isEmpty is false before the first load finishes', () {
      final provider = HomeProvider(
        repository: FakeProductRepository(
          const ProductsResult(products: []),
        ),
      );

      expect(provider.isEmpty, isFalse);
    });

    test('a repository that throws still clears the loading state', () async {
      final provider = HomeProvider(repository: _ThrowingRepository());

      await provider.loadProducts();

      expect(provider.isLoading, isFalse);
      expect(provider.hasBlockingError, isTrue);
    });

    test('refreshProducts returns the failure and keeps existing meals',
        () async {
      final repository = FakeProductRepository(
        ProductsResult(products: [buildMeal()]),
      );
      final provider = HomeProvider(repository: repository);
      await provider.loadProducts();

      repository.result = const ProductsResult(
        products: [],
        failure: AppException.noConnection(),
      );
      final failure = await provider.refreshProducts();

      expect(failure?.type, AppErrorType.noConnection);
      expect(provider.meals, hasLength(1), reason: 'a failed refresh must not blank the page');
      expect(provider.isShowingStaleData, isTrue);
      expect(provider.isRefreshing, isFalse);
    });

    test('retry reloads after a blocking error', () async {
      final repository = FakeProductRepository(
        const ProductsResult(
          products: [],
          failure: AppException.noConnection(),
        ),
      );
      final provider = HomeProvider(repository: repository);
      await provider.loadProducts();
      expect(provider.hasBlockingError, isTrue);

      repository.result = ProductsResult(products: [buildMeal()]);
      await provider.retry();

      expect(provider.hasBlockingError, isFalse);
      expect(provider.hasError, isFalse);
      expect(provider.meals, hasLength(1));
      expect(repository.callCount, 2);
    });
  });

  group('StateView', () {
    testWidgets('renders empty copy with an optional action', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StateView.empty(
              icon: Icons.search,
              title: 'No results found',
              message: 'Try different keywords',
              actionLabel: 'Clear search',
              onAction: () => tapped++,
            ),
          ),
        ),
      );

      expect(find.text('No results found'), findsOneWidget);
      expect(find.text('Try different keywords'), findsOneWidget);

      await tester.tap(find.text('Clear search'));
      expect(tapped, 1);
    });

    testWidgets('renders offline copy and a retry for a connection error',
        (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StateView.error(
              error: const AppException.noConnection(),
              onRetry: () => retried++,
            ),
          ),
        ),
      );

      expect(find.text("You're offline"), findsOneWidget);
      expect(find.textContaining('No internet connection'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      expect(retried, 1);
    });

    testWidgets('omits the action when no retry is given', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StateView.error(error: const AppException.noConnection()),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  group('SearchPage states', () {
    // Search results are MealCards, and MealCard reads Cart.instance in
    // initState, which needs the cart box open before the first pump.
    setUpAll(() async {
      final tempDir = await Directory.systemTemp.createTemp('hive_test_search');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(MealModelAdapter());
      }

      await Hive.openBox('shopping_cart');
    });

    testWidgets('shows an offline error instead of "no results" when the menu '
        'failed to load', (tester) async {
      final provider = HomeProvider(
        repository: FakeProductRepository(
          const ProductsResult(
            products: [],
            failure: AppException.noConnection(),
          ),
        ),
      );
      await provider.loadProducts();

      await tester.pumpWidget(wrapWithProvider(const SearchPage(), provider));
      await tester.pump();

      expect(find.text("You're offline"), findsOneWidget);
      expect(find.text('No results found'), findsNothing);
    });

    testWidgets('prompts before typing, then reports no matches', (tester) async {
      final provider = HomeProvider(
        repository: FakeProductRepository(
          ProductsResult(products: [buildMeal(name: 'Teriyaki Chicken')]),
        ),
      );
      await provider.loadProducts();

      await tester.pumpWidget(wrapWithProvider(const SearchPage(), provider));
      await tester.pump();

      expect(find.text('Search for food'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'sushi');
      await tester.pump();

      expect(find.text('No dishes found'), findsOneWidget);
      expect(find.textContaining('sushi'), findsWidgets);

      await tester.tap(find.text('Clear search'));
      await tester.pump();

      expect(find.text('Search for food'), findsOneWidget);
    });

    testWidgets('filters the loaded meal list locally without another request',
        (tester) async {
      final repository = FakeProductRepository(
        ProductsResult(
          products: [
            MealModel(
              id: '2',
              name: 'Chicken Pilaf',
              category: 'Main Dishes',
              price: 56000,
              imageUrl: '',
              rating: 4.5,
              description: 'Rice dish',
              ingredients: ['chicken', 'rice'],
              area: 'Uzbek',
            ),
          ],
        ),
      );
      final provider = HomeProvider(repository: repository);
      await provider.loadProducts();

      await tester.pumpWidget(wrapWithProvider(const SearchPage(), provider));
      await tester.pump();
      expect(repository.callCount, 1);

      await tester.enterText(find.byType(TextField), 'rice');
      await tester.pump();

      expect(find.text('Chicken Pilaf'), findsOneWidget);
      expect(repository.callCount, 1);
    });
  });
}

class _ThrowingRepository extends ProductRepository {
  @override
  Future<ProductsResult> fetchProducts({
    int count = 20,
    bool forceRefresh = false,
  }) async {
    throw StateError('unexpected');
  }
}
