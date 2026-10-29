import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:xurmo/data/models/meal_model.dart';
import 'package:xurmo/presentation/basket/cart.dart';
import 'package:xurmo/presentation/dashbboard/widgets/app_bottom_nav.dart';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_test_bottom_nav');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MealModelAdapter());
    }

    await Hive.openBox('shopping_cart');
  });

  setUp(() {
    Cart.instance.clear();
  });

  const destinations = <NavDestination>[
    NavDestination(
      icon: CupertinoIcons.house,
      activeIcon: CupertinoIcons.house_fill,
      label: 'Home',
    ),
    NavDestination(
      icon: CupertinoIcons.cart,
      activeIcon: CupertinoIcons.cart_fill,
      label: 'Basket',
      showsCartBadge: true,
    ),
  ];

  final testMeal = MealModel(
    id: '52772',
    name: 'Teriyaki Chicken Casserole',
    category: 'Chicken',
    price: 45.0,
    imageUrl: 'https://example.com/meal.jpg',
    rating: 0.0,
    description: 'A delicious Japanese dish.',
    ingredients: ['soy sauce', 'chicken', 'rice'],
    area: 'Japanese',
  );

  Widget wrap({
    required int currentIndex,
    required ValueChanged<int> onSelected,
  }) {
    return MaterialApp(
      home: Scaffold(
        bottomNavigationBar: AppBottomNav(
          currentIndex: currentIndex,
          destinations: destinations,
          onDestinationSelected: onSelected,
        ),
      ),
    );
  }

  group('AppBottomNav', () {
    testWidgets('shows the label of the selected destination only',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(currentIndex: 0, onSelected: (_) {}));
      await tester.pumpAndSettle();

      // Both labels are in the tree, but the unselected one is collapsed to
      // zero width and fully transparent.
      final homeOpacity = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.text('Home'),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      final basketOpacity = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.text('Basket'),
          matching: find.byType(AnimatedOpacity),
        ),
      );

      expect(homeOpacity.opacity, 1);
      expect(basketOpacity.opacity, 0);
    });

    testWidgets('reports the tapped destination', (WidgetTester tester) async {
      var selected = -1;
      await tester.pumpWidget(
        wrap(currentIndex: 0, onSelected: (i) => selected = i),
      );

      await tester.tap(find.byIcon(CupertinoIcons.cart));
      await tester.pumpAndSettle();

      expect(selected, 1);
    });

    testWidgets('ignores a tap on the already-selected destination',
        (WidgetTester tester) async {
      var callCount = 0;
      await tester.pumpWidget(
        wrap(currentIndex: 0, onSelected: (_) => callCount++),
      );

      await tester.tap(find.byIcon(CupertinoIcons.house_fill));
      await tester.pumpAndSettle();

      expect(callCount, 0);
    });

    testWidgets('hides the badge while the basket is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(currentIndex: 0, onSelected: (_) {}));
      await tester.pumpAndSettle();

      final badge = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(badge.scale, 0);
      // Scaled away visually, and kept out of the accessibility tree so a
      // screen reader does not announce a bare "0".
      final excluded = tester.widget<ExcludeSemantics>(
        find.ancestor(
          of: find.byType(AnimatedScale),
          matching: find.byType(ExcludeSemantics),
        ),
      );
      expect(excluded.excluding, isTrue);
    });

    testWidgets('shows the total quantity on the badge',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(currentIndex: 0, onSelected: (_) {}));

      // Cart.add persists to Hive and only notifies once that write settles,
      // so the write needs real async time before the badge can rebuild.
      await tester.runAsync(() async {
        Cart.instance.add(testMeal);
        Cart.instance.add(testMeal);
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      final badge = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(badge.scale, 1);
    });

    testWidgets('caps the badge at 99+', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(currentIndex: 0, onSelected: (_) {}));

      await tester.runAsync(() async {
        for (var i = 0; i < 101; i++) {
          Cart.instance.add(testMeal);
        }
        // Each add queues its own Hive write; wait for the whole queue to
        // drain rather than guessing at a fixed delay.
        while (Cart.instance.notifier.value < 101) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await tester.pumpAndSettle();

      expect(find.text('99+'), findsOneWidget);
    });
  });
}
