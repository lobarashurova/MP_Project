# Presentation Module

The `presentation` directory contains all UI code for the app.
Each feature has its own folder with its screens, state providers, and supporting widgets.

## Structure

```
presentation/
 ├── auth/
 │    ├── pages/
 │    │     ├── login_page.dart
 │    │     └── signup_page.dart
 │    └── provider/
 │          └── auth_provider.dart

 ├── basket/
 │    ├── basket_page.dart
 │    └── cart.dart

 ├── dashboard/
 │    └── main_page.dart

 ├── favorites/
 │    ├── provider/
 │    │     └── favorites_provider.dart
 │    └── favorites_page.dart

 ├── home/
 │    ├── providers/
 │    │     └── home_provider.dart
 │    ├── widgets/
 │    │     ├── banner_widget.dart
 │    │     ├── cart_item_card.dart
 │    │     ├── category_bar.dart
 │    │     ├── home_header.dart
 │    │     ├── meal_card.dart
 │    │     ├── meal_card_shimmer.dart
 │    │     ├── meals_grid.dart
 │    │     ├── product_card.dart
 │    │     ├── search_bar_widget.dart
 │    │     └── search_field_widget.dart
 │    ├── home_page.dart
 │    └── product_detail_page.dart

 ├── orders/
 │    ├── checkout_page.dart
 │    ├── order_confirm_page.dart
 │    ├── order_detail_page.dart
 │    └── order_page.dart

 ├── profile/
 │    └── profile_page.dart
```

## What Each Section Is For

### auth/

Handles user login and signup.

* **pages/** contains the two authentication screens.
* **provider/** stores the auth logic and state.

### basket/

Everything related to the user’s basket.

* `basket_page.dart` shows the basket screen.
* `cart.dart` manages the local basket model.

### dashboard/

* `main_page.dart` is the main layout that acts as the top-level navigation shell.

### favorites/

Manages the user’s saved/favorited items.

* Includes the favorites provider and the favorites page.

### home/

Main landing area of the app.

* **providers/** contains the business logic for the home screen.
* **widgets/** includes reusable UI pieces used in the home feature (banners, cards, search widgets, shimmer loading widgets, etc.).
* `home_page.dart` is the home screen itself.
* `product_detail_page.dart` shows detailed info about a selected product.

### orders/

Handles the user’s order process from start to finish.
Includes checkout, confirmation, order history, and order details.

### profile/

Contains the user profile screen.
