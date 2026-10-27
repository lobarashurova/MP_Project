import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:xurmo/data/models/meal_model.dart';
import 'package:xurmo/presentation/basket/cart.dart';
import 'package:xurmo/presentation/home/product_detail_page.dart';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_test_product_detail');
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
    id: '52772',
    name: 'Teriyaki Chicken Casserole',
    category: 'Chicken',
    price: 45.0,
    imageUrl: 'https://www.themealdb.com/images/media/meals/wvpsxx1468256321.jpg',
    rating: 0.0,
    description: 'A delicious Japanese dish.',
    ingredients: ['soy sauce', 'chicken', 'rice'],
    area: 'Japanese',
  );

  group('ProductDetailPage', () {
    testWidgets('should display all meal details correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ProductDetailPage(meal: testMeal),
      ));

      expect(find.text('Teriyaki Chicken Casserole'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
      expect(find.textContaining('A delicious Chicken dish'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'soy sauce'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Add to Basket'), findsOneWidget);
    });

    testWidgets('should show a SnackBar when Add to Basket is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ProductDetailPage(meal: testMeal),
      ));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add to Basket'));
      await tester.pumpAndSettle();

      expect(find.text('Teriyaki Chicken Casserole added to basket!'), findsOneWidget);
    });
  });
}
