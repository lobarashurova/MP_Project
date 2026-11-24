import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xurmo/data/models/meal_model.dart';
import 'package:xurmo/data/models/saved_address.dart';
import 'package:xurmo/data/repositories/saved_address_repository.dart';
import 'package:xurmo/presentation/basket/cart.dart';
import 'package:xurmo/presentation/orders/checkout_page.dart';

/// The checkout only reaches Firebase when the order is placed, so the saved
/// address picker can be driven in a plain widget test.
void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_test_checkout');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MealModelAdapter());
    }
    await Hive.openBox('shopping_cart');
  });

  final meal = MealModel(
    id: '1',
    name: 'Plov',
    category: 'Rice',
    price: 40000,
    imageUrl: '',
    rating: 4.8,
    description: 'Tashkent plov.',
    ingredients: const ['rice', 'lamb'],
    area: 'Uzbek',
  );

  late SavedAddressRepository repo;

  setUp(() async {
    Cart.instance.clear();
    Cart.instance.add(meal);
    SharedPreferences.setMockInitialValues({});
    repo = SavedAddressRepository(prefs: await SharedPreferences.getInstance());
  });

  Future<void> pumpCheckout(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: CheckoutPage(savedAddresses: repo)));
    await tester.pumpAndSettle();
  }

  Finder addressField() => find.byType(TextFormField).first;

  testWidgets('without saved addresses the field starts empty', (tester) async {
    await pumpCheckout(tester);

    expect(find.text('0 saved'), findsNothing);
    expect(tester.widget<TextFormField>(addressField()).controller?.text, '');
  });

  testWidgets('the most recent saved address fills the form on open',
      (tester) async {
    await repo.save(const SavedAddress(
      id: '1',
      label: 'Work',
      address: 'Mustaqillik 7, office 4',
      lastUsedAt: 10,
      phone: '+998901112233',
    ));
    await repo.save(const SavedAddress(
      id: '2',
      label: 'Home',
      address: 'Amir Temur 15, flat 9',
      lastUsedAt: 20,
      phone: '+998905556677',
    ));

    await pumpCheckout(tester);

    expect(find.text('2 saved'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(addressField()).controller?.text,
      'Amir Temur 15, flat 9',
    );
    // The phone saved with it comes along, and so does the "using saved" note.
    expect(find.text('+998905556677'), findsOneWidget);
    expect(find.textContaining('Using your saved "Home"'), findsOneWidget);
    // Nothing to save, so the switch row stays out of the way.
    expect(find.text('Save this address'), findsNothing);
  });

  testWidgets('tapping another saved address swaps the delivery details',
      (tester) async {
    await repo.save(const SavedAddress(
      id: '1',
      label: 'Work',
      address: 'Mustaqillik 7, office 4',
      lastUsedAt: 10,
    ));
    await repo.save(const SavedAddress(
      id: '2',
      label: 'Home',
      address: 'Amir Temur 15, flat 9',
      lastUsedAt: 20,
    ));

    await pumpCheckout(tester);
    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextFormField>(addressField()).controller?.text,
      'Mustaqillik 7, office 4',
    );
    expect(find.textContaining('Using your saved "Work"'), findsOneWidget);
  });

  testWidgets('typing a new address offers to save it under a label',
      (tester) async {
    await pumpCheckout(tester);

    await tester.enterText(addressField(), 'Shota Rustaveli 12, entrance 2');
    await tester.pumpAndSettle();

    expect(find.text('Save this address'), findsOneWidget);
    // Home is picked by default; the chips switch it.
    await tester.tap(find.widgetWithText(InkWell, 'Work').first);
    await tester.pumpAndSettle();

    expect(find.text('Work'), findsWidgets);
  });

  testWidgets('typing lays out on a narrow screen at the largest font size',
      (tester) async {
    // The label chips used to overflow here, which paints the red error box
    // over the checkout as soon as the customer starts typing.
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await repo.save(const SavedAddress(
      id: '1',
      label: 'Home',
      address: 'Amir Temur 15, flat 9',
      lastUsedAt: 5,
    ));

    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(
        size: Size(320, 640),
        textScaler: TextScaler.linear(1.6),
      ),
      child: MaterialApp(home: CheckoutPage(savedAddresses: repo)),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
        addressField(), 'Shota Rustaveli 12, entrance 2, flat 44');
    await tester.pumpAndSettle();

    expect(find.text('Save this address'), findsOneWidget);
  });

  testWidgets('removing a saved address asks first and then drops it',
      (tester) async {
    await repo.save(const SavedAddress(
      id: '1',
      label: 'Work',
      address: 'Mustaqillik 7, office 4',
      lastUsedAt: 10,
    ));
    await repo.save(const SavedAddress(
      id: '2',
      label: 'Home',
      address: 'Amir Temur 15, flat 9',
      lastUsedAt: 20,
    ));

    await pumpCheckout(tester);

    // Home is the selected one, so Work is the card showing a remove button.
    await tester.tap(find.byTooltip('Remove Work'));
    await tester.pumpAndSettle();
    expect(find.text('Remove address?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Remove'));
    await tester.pumpAndSettle();

    expect(find.text('1 saved'), findsOneWidget);
    expect((await repo.load()).map((a) => a.label), ['Home']);
  });

  testWidgets('keeping an address on the confirm dialog changes nothing',
      (tester) async {
    await repo.save(const SavedAddress(
      id: '1',
      label: 'Work',
      address: 'Mustaqillik 7, office 4',
      lastUsedAt: 10,
    ));
    await repo.save(const SavedAddress(
      id: '2',
      label: 'Home',
      address: 'Amir Temur 15, flat 9',
      lastUsedAt: 20,
    ));

    await pumpCheckout(tester);
    await tester.tap(find.byTooltip('Remove Work'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Keep'));
    await tester.pumpAndSettle();

    expect(find.text('2 saved'), findsOneWidget);
    expect(await repo.load(), hasLength(2));
  });
}
