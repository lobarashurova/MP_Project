import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yandex_maps_mapkit_lite/init.dart';

import 'package:xurmo/core/constants/map_config.dart';
import 'package:xurmo/core/theme/app_theme.dart';
import 'package:xurmo/core/theme/theme_provider.dart';

import 'package:xurmo/core/session/install_guard.dart';
import 'package:xurmo/data/models/meal_model.dart';
import 'package:xurmo/presentation/auth/provider/auth_provider.dart';
import 'package:xurmo/presentation/auth/pages/login_page.dart';
import 'package:xurmo/presentation/auth/pages/signup_page.dart';
import 'package:xurmo/presentation/favorites/provider/favorites_provider.dart';
import 'package:xurmo/presentation/home/providers/home_provider.dart';
import 'package:xurmo/presentation/dashbboard/main_page.dart';
import 'package:xurmo/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();

  // A reinstalled app must start signed out (issue #11). This runs before
  // AuthProvider reads the current user, so no screen sees the old session.
  try {
    await InstallGuard(
      prefs: prefs,
      signOut: FirebaseAuth.instance.signOut,
    ).run();
  } catch (e) {
    // Never block startup on this; the worst case is staying signed in.
    debugPrint('Install guard failed: $e');
  }

  // Yandex MapKit needs its key before any map is shown. Builds without a key
  // skip this, and the checkout hides the map picker.
  if (MapConfig.isMapAvailable) {
    await initMapkit(apiKey: MapConfig.yandexApiKey);
  }

  await Hive.initFlutter();

  Hive.registerAdapter(MealModelAdapter());

  // The cart reads its box synchronously, so it must be open before runApp.
  // The product cache box is opened lazily by ProductRepository.
  await Hive.openBox('shopping_cart');

  final isDarkMode = prefs.getBool('is_dark_mode') ?? false;

  runApp(MyApp(initialIsDarkMode: isDarkMode));
}

class MyApp extends StatelessWidget {
  final bool initialIsDarkMode;

  const MyApp({super.key, this.initialIsDarkMode = false});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(initialIsDarkMode: initialIsDarkMode)),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Xurmo App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const MainPage(),
            routes: {
              '/login': (context) => const LoginPage(),
              '/signup': (context) => const SignupPage(),
              '/home': (context) => const MainPage(),
            },
          );
        },
      ),
    );
  }
}
