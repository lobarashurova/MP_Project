import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:xurmo/data/models/meal_model.dart';
import 'package:xurmo/data/repositories/local_storage_repo.dart';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MealModelAdapter());
    }

    await Hive.openBox<MealModel>(LocalStorageRepository.favBoxName);
    await Hive.openBox<MealModel>(LocalStorageRepository.cartBoxName);
    await Hive.openBox(LocalStorageRepository.orderBoxName);
  });

  tearDown(() async {
    await Hive.box<MealModel>(LocalStorageRepository.favBoxName).clear();
    await Hive.box<MealModel>(LocalStorageRepository.cartBoxName).clear();
    await Hive.box(LocalStorageRepository.orderBoxName).clear();
  });

  final testMeal1 = MealModel(
    id: '1',
    name: 'Test Meal 1',
    category: 'Test',
    price: 10.0,
    imageUrl: '',
    rating: 5.0,
    description: 'A delicious test meal.',
  );

  final testMeal2 = MealModel(
    id: '2',
    name: 'Test Meal 2',
    category: 'Test',
    price: 20.0,
    imageUrl: '',
    rating: 4.0,
    description: 'Another delicious test meal.',
  );

  final repository = LocalStorageRepository();

  group('Favorites Functionality', () {
    test('should add a meal to favorites', () async {
      await repository.toggleFavorite(testMeal1);
      final isFavorite = await repository.isFavorite(testMeal1.id);
      expect(isFavorite, isTrue);
    });

    test('should remove a meal from favorites', () async {
      await repository.toggleFavorite(testMeal1);
      await repository.toggleFavorite(testMeal1);
      final isFavorite = await repository.isFavorite(testMeal1.id);
      expect(isFavorite, isFalse);
    });

    test('should get all favorite meals', () async {
      await repository.toggleFavorite(testMeal1);
      await repository.toggleFavorite(testMeal2);
      final favorites = await repository.getFavorites();
      expect(favorites.length, 2);
      expect(favorites.first.id, testMeal1.id);
    });
  });

  group('Cart Functionality', () {
    test('should add a meal to the cart', () async {
      await repository.addToCart(testMeal1);
      final cartItems = await repository.getCartItems();
      expect(cartItems.length, 1);
      expect(cartItems.first.id, testMeal1.id);
    });

    test('should clear all items from the cart', () async {
      await repository.addToCart(testMeal1);
      await repository.addToCart(testMeal2);

      await repository.clearCart();
      final cartItems = await repository.getCartItems();
      expect(cartItems, isEmpty);
    });
  });

  group('Order Functionality', () {
    test('should place an order and retrieve it', () async {
      final orderItems = [testMeal1, testMeal2];
      const orderTotal = 30.0;

      await repository.placeOrder(orderItems, orderTotal);

      final orders = await repository.getOrders();
      expect(orders.length, 1);
      final placedOrder = orders.first;
      expect(placedOrder['total'], orderTotal);
      expect(placedOrder['items'].length, 2);
      expect(placedOrder['status'], 'preparing');
    });
  });
}
