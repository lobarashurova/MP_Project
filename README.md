# Xurmo - Food Delivery App

A modern, feature-rich food delivery mobile application built with Flutter and Firebase. Xurmo provides a seamless experience for browsing meals, managing favorites, shopping cart, and order tracking.

## Features

### Core Features
- **Browse Menu**: Explore a wide variety of meals with beautiful UI and smooth scrolling
- **Category Filtering**: Smart category-based filtering with auto-scrolling navigation
- **Search Functionality**: Real-time search across meals by name, category, or description
- **Shopping Cart**: Add, remove, and manage items with quantity controls
- **Favorites**: Save your favorite meals for quick access
- **Order Management**: Complete checkout process with order history tracking
- **User Authentication**: Secure Firebase authentication with email/password
- **User Profile**: Manage personal information and view account statistics

### Technical Features
- **Offline Support**: Local caching with Hive for offline data access
- **State Management**: Provider pattern for efficient state management
- **Responsive Design**: Optimized UI for different screen sizes
- **Smooth Animations**: Polished transitions and micro-interactions
- **Real-time Updates**: Firebase Firestore for real-time data synchronization

## Tech Stack

### Frontend
- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language

### Backend & Services
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - NoSQL cloud database
- **Firebase Core** - Firebase SDK

### State Management & Storage
- **Provider** - State management solution
- **Hive** - Fast, lightweight local database
- **SharedPreferences** - Simple key-value storage

### Networking & Data
- **Dio** - Powerful HTTP client
- **Scrollable Positioned List** - Advanced list scrolling

### UI Components
- **Shimmer** - Loading placeholder animations
- **Cupertino Icons** - iOS-style icons
- **Material Design** - Android-style components

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart         # Color scheme
│   │   └── app_text_styles.dart    # Typography
│   └── ...
├── data/
│   ├── models/
│   │   └── meal_model.dart         # Meal data model
│   ├── repositories/
│   │   └── product_repository.dart # Data layer
│   └── manager/
│       └── favorites_manager.dart  # Favorites management
├── presentation/
│   ├── auth/
│   │   ├── pages/
│   │   │   ├── login_page.dart     # Login screen
│   │   │   └── signup_page.dart    # Registration screen
│   │   └── provider/
│   │       └── auth_provider.dart  # Auth state management
│   ├── home/
│   │   ├── home_page.dart          # Main home screen
│   │   ├── product_detail_page.dart # Product details
│   │   ├── providers/
│   │   │   └── home_provider.dart  # Home state
│   │   └── widgets/
│   │       ├── banner_widget.dart
│   │       ├── category_bar.dart
│   │       ├── meal_card.dart
│   │       └── search_bar_widget.dart
│   ├── search/
│   │   └── search_page.dart        # Search functionality
│   ├── favorites/
│   │   ├── favorites_page.dart     # Favorites list
│   │   └── provider/
│   │       └── favorites_provider.dart
│   ├── basket/
│   │   ├── basket_page.dart        # Shopping cart
│   │   └── cart.dart               # Cart singleton
│   ├── orders/
│   │   ├── order_page.dart         # Order history
│   │   ├── order_detail_page.dart  # Order details
│   │   └── checkout_page.dart      # Checkout flow
│   ├── profile/
│   │   ├── profile_page.dart       # User profile
│   │   ├── personal_info_page.dart # Edit profile
│   │   └── about_page.dart         # About app
│   └── dashbboard/
│       └── main_page.dart          # Bottom navigation
└── main.dart                        # App entry point
```

## Getting Started

### Prerequisites
- Flutter SDK (>=3.7.2)
- Dart SDK (>=3.7.2)
- Firebase account
- iOS Simulator / Android Emulator or Physical Device

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/xurmo.git
   cd xurmo
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add iOS and/or Android app to your Firebase project
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the appropriate directories:
     - Android: `android/app/google-services.json`
     - iOS: `ios/Runner/GoogleService-Info.plist`
   - Enable Authentication (Email/Password) in Firebase Console
   - Create Firestore database

4. **Generate Hive adapters**
   ```bash
   flutter pub run build_runner build
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## Firebase Configuration

### Firestore Collections Structure

**users/**
```
{
  name: string,
  email: string,
  createdAt: timestamp
}
```

**orders/**
```
{
  userId: string,
  items: array,
  totalAmount: number,
  status: string,
  deliveryAddress: string,
  createdAt: timestamp
}
```

**products/** (optional - can use API instead)
```
{
  name: string,
  description: string,
  price: number,
  category: string,
  imageUrl: string,
  rating: number
}
```

## App Architecture

### State Management
The app uses Provider pattern for state management:
- `AuthProvider` - Manages authentication state
- `HomeProvider` - Handles product listing and categories
- `FavoritesProvider` - Manages favorite items
- `Cart` - Singleton pattern for shopping cart

### Data Flow
1. **Remote Data**: Firebase Firestore → Repository → Provider → UI
2. **Local Cache**: Hive boxes for offline-first experience
3. **Authentication**: Firebase Auth → AuthProvider → UI updates

### Key Design Patterns
- **Repository Pattern**: Abstracts data sources
- **Provider Pattern**: State management and dependency injection
- **Singleton Pattern**: Cart management
- **Observer Pattern**: Real-time data updates

## Features in Detail

### Authentication Flow
- App starts with MainPage
- Profile tab shows login screen if not authenticated
- After login, profile data loads automatically
- Logout clears authentication state

### Home Screen
- Dynamic category filtering
- Two-column grid layout for products
- Sticky category bar on scroll
- Smooth scroll synchronization between categories and products
- Loading shimmer effects

### Search
- Real-time search as you type
- Searches across meal name, category, and description
- Grid view results
- Empty state handling

### Shopping Cart
- Add/remove items
- Quantity management
- Price calculation with delivery fee
- Persistent storage with Hive

### Orders
- Complete checkout process
- Order history with status tracking
- Order details view
- Address management

## Building for Production

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Testing
```bash
flutter test
```

## Troubleshooting

### Common Issues

1. **Firebase not initialized**
   - Ensure `google-services.json` / `GoogleService-Info.plist` are in correct locations
   - Verify Firebase configuration in `firebase_options.dart`

2. **Hive errors**
   - Run `flutter pub run build_runner build --delete-conflicting-outputs`

3. **Build errors**
   - Clean build: `flutter clean && flutter pub get`
   - Update dependencies: `flutter pub upgrade`

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Code Style

This project follows the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style) and uses:
- `flutter_lints` for linting
- 2-space indentation
- CamelCase for classes
- lowerCamelCase for variables and methods

## Performance Optimizations

- **Lazy Loading**: Products load on demand
- **Image Caching**: Network images are cached automatically
- **Local Database**: Hive for fast local data access
- **Efficient Rebuilds**: Provider with Consumer widgets
- **List Virtualization**: Efficient rendering of large lists

## Future Enhancements

- [ ] Push notifications for order updates
- [ ] Multiple payment methods integration
- [ ] Live order tracking with maps
- [ ] Restaurant/vendor management
- [ ] Multi-language support
- [ ] Dark mode theme
- [ ] Social media authentication
- [ ] Product reviews and ratings
- [ ] Promocode and discount system
- [ ] Delivery time slot selection

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

Project Link: [https://github.com/yourusername/xurmo](https://github.com/yourusername/xurmo)

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- All open-source contributors

---
