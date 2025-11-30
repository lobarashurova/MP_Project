import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

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

  await Hive.initFlutter();

  Hive.registerAdapter(MealModelAdapter());

  await Hive.openBox<MealModel>('productsBox');
  await Hive.openBox<MealModel>('favoritesBox');
  await Hive.openBox('shopping_cart');
  await Hive.openBox('ordersBox');

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