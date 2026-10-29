import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:xurmo/core/constants/app_pricing.dart';
import 'package:xurmo/data/models/meal_model.dart';
import 'package:xurmo/presentation/basket/cart.dart';
import 'package:xurmo/presentation/basket/basket_page.dart';
import 'package:xurmo/core/utils/money.dart';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_test_basket');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MealModelAdapter());
    }

    await Hive.openBox('shopping_cart');
  });

  setUp(() {
    Cart.instance.clear();
  });

  final testMeal1 = MealModel(
    id: '52772',
    name: 'Teriyaki Chicken Casserole',
    category: 'Chicken',
    price: 45000.0,
    imageUrl: 'https://www.themealdb.com/images/media/meals/wvpsxx1468256321.jpg',
    rating: 4.5,
    description: 'A delicious Japanese dish.',
    ingredients: ['soy sauce', 'chicken', 'rice'],
    area: 'Japanese',
  );

  final testMeal2 = MealModel(
    id: '52873',
    name: 'Beef Stroganoff',
    category: 'Beef',
    price: 35000.0,
    imageUrl: 'https://www.themealdb.com/images/media/meals/svprys1511876957.jpg',
    rating: 4.3,
    description: 'A creamy Russian classic.',
    ingredients: ['beef', 'sour cream', 'mushrooms'],
    area: 'Russian',
  );

  group('BasketPage Integration Tests', () {
    testWidgets('should display empty basket when cart is empty', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const BasketPage(),
      ));

      expect(find.text('Your Basket'), findsOneWidget);
      expect(find.text('Your basket is empty'), findsOneWidget);
    });

    testWidgets('should display single item in basket with correct details', (WidgetTester tester) async {
      Cart.instance.add(testMeal1);

      await tester.pumpWidget(MaterialApp(
        home: const BasketPage(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Teriyaki Chicken Casserole'), findsOneWidget);

      // Subtotal is item price; discount is 30%; total adds delivery fee on top.
      final expectedSubtotal = 45000.0;
      final discount = expectedSubtotal * AppPricing.promoDiscountPercent / 100;
      final expectedTotal = expectedSubtotal - discount + AppPricing.deliveryFee;

      expect(find.text(formatSum(45000.0)), findsWidgets);
      expect(find.text(formatSum(AppPricing.deliveryFee)), findsOneWidget);

      final totalFinder = find.byWidgetPredicate(
        (Widget widget) =>
            widget is Text &&
            widget.data == formatSum(expectedTotal) &&
            widget.style?.fontSize == 20.0,
        description: 'Total text with a font size of 20.0',
      );

      expect(totalFinder, findsOneWidget);
    });

    testWidgets('should display multiple items in basket', (WidgetTester tester) async {
      Cart.instance.add(testMeal1);
      Cart.instance.add(testMeal2);

      await tester.pumpWidget(MaterialApp(
        home: const BasketPage(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Teriyaki Chicken Casserole'), findsOneWidget);
      expect(find.text('Beef Stroganoff'), findsOneWidget);

      final expectedSubtotal = 80000.0;
      final discount = expectedSubtotal * AppPricing.promoDiscountPercent / 100;
      final expectedTotal = expectedSubtotal - discount + AppPricing.deliveryFee;

      expect(find.text(formatSum(80000.0)), findsOneWidget);

      final totalFinder = find.byWidgetPredicate(
        (Widget widget) =>
            widget is Text &&
            widget.data == formatSum(expectedTotal) &&
            widget.style?.fontSize == 20.0,
        description: 'Total text with a font size of 20.0',
      );

      expect(totalFinder, findsOneWidget);
    });

    testWidgets('should not charge a delivery fee on an empty cart', (WidgetTester tester) async {
      expect(Cart.instance.subtotal, 0);
      expect(Cart.instance.deliveryFee, 0);
      expect(Cart.instance.totalPrice, 0);

      Cart.instance.add(testMeal1);
      final expectedSubtotal = 45000.0;
      final discount = expectedSubtotal * AppPricing.promoDiscountPercent / 100;
      final expectedTotal = expectedSubtotal - discount + AppPricing.deliveryFee;

      expect(Cart.instance.subtotal, 45000.0);
      expect(Cart.instance.deliveryFee, AppPricing.deliveryFee);
      expect(Cart.instance.totalPrice, expectedTotal);
    });

    testWidgets('should display Order Now button', (WidgetTester tester) async {
      Cart.instance.add(testMeal1);

      await tester.pumpWidget(MaterialApp(
        home: const BasketPage(),
      ));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ElevatedButton, 'Order Now'), findsOneWidget);
    });
  });
}
