import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // A reinstalled app must start signed out (issue #11). This runs before
  // AuthProvider reads the current user, so no screen sees the old session.
  try {
    await InstallGuard(
      prefs: await SharedPreferences.getInstance(),
      signOut: FirebaseAuth.instance.signOut,
    ).run();
  } catch (e) {
    // Never block startup on this; the worst case is staying signed in.
    debugPrint('Install guard failed: $e');
  }

  await Hive.initFlutter();

  Hive.registerAdapter(MealModelAdapter());

  // The cart reads its box synchronously, so it must be open before runApp.
  // The product cache box is opened lazily by ProductRepository.
  await Hive.openBox('shopping_cart');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: MaterialApp(
        title: 'Xurmo App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.orange,
          useMaterial3: true,
        ),
        home: const MainPage(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignupPage(),
          '/home': (context) => const MainPage(),
        },
      ),
    );
  }
}