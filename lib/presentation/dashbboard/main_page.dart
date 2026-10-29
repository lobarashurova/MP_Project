import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../basket/basket_page.dart';
import '../favorites/favorites_page.dart';
import '../home/home_page.dart';
import '../profile/profile_page.dart';
import 'widgets/app_bottom_nav.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  static const List<NavDestination> _destinations = <NavDestination>[
    NavDestination(
      icon: CupertinoIcons.house,
      activeIcon: CupertinoIcons.house_fill,
      label: 'Home',
    ),
    NavDestination(
      icon: CupertinoIcons.heart,
      activeIcon: CupertinoIcons.heart_fill,
      label: 'Favorites',
    ),
    NavDestination(
      icon: CupertinoIcons.cart,
      activeIcon: CupertinoIcons.cart_fill,
      label: 'Basket',
      showsCartBadge: true,
    ),
    NavDestination(
      icon: CupertinoIcons.person,
      activeIcon: CupertinoIcons.person_fill,
      label: 'Profile',
    ),
  ];

  final List<Widget> _pages = const [
    HomePage(),
    FavoritesPage(),
    BasketPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps each tab alive, so scroll position and in-progress
      // input survive switching tabs instead of rebuilding from scratch.
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        destinations: _destinations,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}
