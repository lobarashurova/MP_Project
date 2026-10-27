import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:xurmo/data/models/meal_model.dart';
import 'package:xurmo/presentation/basket/cart.dart';
import 'package:xurmo/presentation/home/widgets/cart_item_card.dart';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_test_cart_card');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MealModelAdapter());
    }
    await Hive.openBox('shopping_cart');
  });

  setUp(() {
    Cart.instance.clear();
  });

  final testMeal = MealModel(
    id: '101',
    name: 'Test Meal',
    category: 'Test Category',
    price: 25.00,
    imageUrl: '',
    rating: 5.0,
    description: 'Delicious test meal',
  );

  group('CartItemCard Widget Test', () {
    testWidgets('should display meal name, price and quantity correctly', (WidgetTester tester) async {
      final cartItem = CartItem(product: testMeal, quantity: 3);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CartItemCard(cartItem: cartItem),
        ),
      ));

      expect(find.text('Test Meal'), findsOneWidget);
      expect(find.text('\$25.00'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('should increase quantity when plus button is pressed', (WidgetTester tester) async {
      Cart.instance.add(testMeal);
      final cartItem = Cart.instance.items.first;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CartItemCard(cartItem: cartItem),
        ),
      ));

      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byIcon(CupertinoIcons.plus));
      await tester.pump();

      final updatedQuantity = Cart.instance.getQuantity(testMeal.id);
      expect(updatedQuantity, 2);
    });

    testWidgets('should decrease quantity when minus button is pressed', (WidgetTester tester) async {
      Cart.instance.add(testMeal);
      Cart.instance.add(testMeal);
      final cartItem = Cart.instance.items.first;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CartItemCard(cartItem: cartItem),
        ),
      ));

      expect(Cart.instance.getQuantity(testMeal.id), 2);

      await tester.tap(find.byIcon(CupertinoIcons.minus));
      await tester.pump();

      final updatedQuantity = Cart.instance.getQuantity(testMeal.id);
      expect(updatedQuantity, 1);
    });
  });
}
