import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/theme/app_theme.dart';
import 'package:xurmo/core/widgets/app_card.dart';
import 'package:xurmo/core/widgets/quantity_stepper.dart';

void main() {
  // AppColors.isDarkMode is global, so every test restores it rather than
  // leaking a dark palette into whatever runs next.
  tearDown(() => AppColors.isDarkMode = false);

  group('AppColors', () {
    test('tokens follow isDarkMode', () {
      AppColors.isDarkMode = false;
      expect(AppColors.background, AppColors.lightBackground);
      expect(AppColors.surfaceAlt, AppColors.lightSurfaceAlt);
      expect(AppColors.primarySoft, AppColors.lightPrimarySoft);
      expect(AppColors.shadowStrong, AppColors.lightShadowStrong);

      AppColors.isDarkMode = true;
      expect(AppColors.background, AppColors.darkBackground);
      expect(AppColors.surfaceAlt, AppColors.darkSurfaceAlt);
      expect(AppColors.primarySoft, AppColors.darkPrimarySoft);
      expect(AppColors.shadowStrong, AppColors.darkShadowStrong);
    });

    test('brand colours are identical in both themes', () {
      AppColors.isDarkMode = false;
      final lightBrand = [AppColors.primary, AppColors.onPrimary];

      AppColors.isDarkMode = true;
      expect([AppColors.primary, AppColors.onPrimary], lightBrand);
    });

    test('dark text sits light and light text sits dark', () {
      // Guards the pair being swapped by accident, which would make body
      // copy invisible rather than merely off-palette.
      expect(
        AppColors.darkTextPrimary.computeLuminance(),
        greaterThan(AppColors.darkBackground.computeLuminance()),
      );
      expect(
        AppColors.lightTextPrimary.computeLuminance(),
        lessThan(AppColors.lightBackground.computeLuminance()),
      );
    });
  });

  group('AppTheme', () {
    test('reports the brightness it was asked for', () {
      AppColors.isDarkMode = false;
      expect(AppTheme.lightTheme.brightness, Brightness.light);

      AppColors.isDarkMode = true;
      expect(AppTheme.darkTheme.brightness, Brightness.dark);
    });

    test('both themes style the same components', () {
      // The point of building both from one function: a component cannot be
      // themed in light mode and fall back to Material defaults in dark.
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        expect(theme.useMaterial3, isTrue);
        expect(theme.elevatedButtonTheme.style, isNotNull);
        expect(theme.outlinedButtonTheme.style, isNotNull);
        expect(theme.textButtonTheme.style, isNotNull);
        expect(theme.inputDecorationTheme.border, isNotNull);
        expect(theme.cardTheme.shape, isNotNull);
        expect(theme.chipTheme.shape, isNotNull);
        expect(theme.dialogTheme.shape, isNotNull);
        expect(theme.bottomSheetTheme.shape, isNotNull);
        expect(theme.switchTheme.trackColor, isNotNull);
        expect(theme.listTileTheme.shape, isNotNull);
        expect(theme.textTheme.bodyMedium, isNotNull);
        expect(theme.colorScheme.primary, AppColors.primary);
      }
    });

    test('dark scaffold and surfaces come from the dark palette', () {
      AppColors.isDarkMode = true;
      final dark = AppTheme.darkTheme;

      expect(dark.scaffoldBackgroundColor, AppColors.darkBackground);
      expect(dark.cardColor, AppColors.darkCardBackground);
      expect(dark.colorScheme.surface, AppColors.darkSurface);
      expect(dark.colorScheme.onSurface, AppColors.darkTextPrimary);
    });

    test('darkTheme does not depend on the isDarkMode flag being set', () {
      // _build reads the light/dark constants directly, so asking for the
      // dark theme while the flag still says light must not yield light
      // surfaces — MaterialApp builds both themes on every rebuild.
      AppColors.isDarkMode = false;
      expect(AppTheme.darkTheme.scaffoldBackgroundColor,
          AppColors.darkBackground);
      expect(AppTheme.lightTheme.scaffoldBackgroundColor,
          AppColors.lightBackground);
    });

    test('the spacing and radius scales ascend', () {
      expect(
        [
          AppTheme.spaceXs,
          AppTheme.spaceSm,
          AppTheme.spaceMd,
          AppTheme.spaceLg,
          AppTheme.spaceXl,
        ],
        orderedEquals(<double>[4, 8, 16, 24, 32]),
      );
      expect(AppTheme.radiusSmall, lessThan(AppTheme.radiusMedium));
      expect(AppTheme.radiusMedium, lessThan(AppTheme.radiusLarge));
      expect(AppTheme.radiusLarge, lessThan(AppTheme.radiusPill));
    });
  });

  group('AppCard', () {
    testWidgets('renders its child and reports taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppCard(
            onTap: () => taps++,
            child: const Text('panel'),
          ),
        ),
      ));

      expect(find.text('panel'), findsOneWidget);

      await tester.tap(find.text('panel'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('without onTap it is not tappable', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: AppCard(child: Text('static'))),
      ));

      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.onTap, isNull);
    });
  });

  group('AppSection', () {
    testWidgets('titles in caps and divides rows without trailing hairlines',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AppSection(
            title: 'Account',
            children: [Text('one'), Text('two'), Text('three')],
          ),
        ),
      ));

      expect(find.text('ACCOUNT'), findsOneWidget);
      // Three rows means two dividers, never four.
      expect(find.byType(Divider), findsNWidgets(2));
    });
  });

  group('QuantityStepper', () {
    testWidgets('shows the count and fires both callbacks', (tester) async {
      var down = 0;
      var up = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: QuantityStepper(
            quantity: 4,
            onDecrease: () => down++,
            onIncrease: () => up++,
          ),
        ),
      ));

      expect(find.text('4'), findsOneWidget);

      await tester.tap(find.byIcon(CupertinoIcons.minus));
      await tester.tap(find.byIcon(CupertinoIcons.plus));
      await tester.pump();

      expect(down, 1);
      expect(up, 1);
    });
  });
}
