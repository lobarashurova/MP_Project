
# Xurmo - Food Delivery App

A modern, feature-rich food delivery mobile application built with Flutter and Firebase. Xurmo provides a seamless experience for browsing meals, managing favorites, interactive location selection, shopping cart management, and order tracking.

---

## Team Handover & Closure Documentation

This project contains all necessary deliverables, decision logs, and metrics required for team handover and project closure.

### 1. Final Source Files and Deliverables
* **Source Repository**: Complete production-ready Flutter codebase (`lib/`, `test/`, `pubspec.yaml`, `firestore.rules`).
* **Platform Support**: Configuration and build metadata for Android (`android/`), iOS (`ios/`), Web (`web/`), macOS (`macos/`), Linux (`linux/`), and Windows (`windows/`).
* **Environment Setup Templates**: `firebase_options.dart` and placeholder setup instructions for `google-services.json` / `GoogleService-Info.plist`.

### 2. Decision Logs (ADRs)
* **ADR-01: Feature-First Clean Architecture**: Organized into `core/`, `data/`, and `presentation/` to isolate business logic, UI components, and API/persistence integration.
* **ADR-02: State Management with Provider**: Selected `Provider` for low boilerplate, clean separation of UI and state (`AuthProvider`, `HomeProvider`, `FavoritesProvider`, `ThemeProvider`), and direct integration with Flutter widget trees.
* **ADR-03: Offline Caching & Local Storage**: Utilized **Hive** for fast object persistence (meals and cart items) and **SharedPreferences** (`local_storage_repo.dart`) for simple user key-value preferences.
* **ADR-04: Network Client**: Chose **Dio** over `http` to leverage request interceptors, standard error wrapping, and timeout handling in `network_module.dart`.
* **ADR-05: Location & Geocoding**: Integrated geocoding capabilities (`geocoding_repository.dart`) and interactive map picker (`location_picker_page.dart`) to capture delivery locations.
* **ADR-06: Currency System**: Standardized on Uzbek Som (`soʻm`) using a dedicated `money.dart` utility across all prices, cart totals, and checkout summaries.

### 3. Documentation & Reports
* **Database Schema**: Firestore structure (`users/`, `orders/`, `products/`) detailed in this README.
* **Testing Report**: Unit, widget, and integration coverage across 18 test files in `test/`.
* **Known Technical Debt**:
  * Manual Hive adapter generation required when modifying `meal_model.dart`.
  * External map API keys need to be injected into `map_config.dart` before production deployment.

### 4. User Stories & Demos
* **User Story 1 (Auth)**: As a customer, I can register and log in via Firebase Auth so that my preferences and order history are persisted.
* **User Story 2 (Discovery)**: As a customer, I can search, filter by category, and view detailed product info without unexpected network latency.
* **User Story 3 (Location & Cart)**: As a customer, I can select my delivery location on a map, add items to my cart, adjust quantities, and see total prices in soʻm.
* **User Story 4 (Theme Preferences)**: As a user, I can toggle between Light and Dark modes (`ThemeProvider`) to suit my viewing preference.
* **Demo Walkthrough**: See repository `test/` integration files (`add_to_cart_integration_test.dart`, `product_detail_page_test.dart`) for verified UI flows.

### 5. Supporting Data and Metrics
* **Total Project Scope**: 84 directories, 156 files.
* **Automated Test Coverage**: 18 comprehensive test suites in `test/` covering authentication, navigation, cart operations, design system components, and geocoding.
* **Mock Datasets**: Pre-configured mock data in `lib/data/mock/mock_products.dart` for immediate offline testing and UI verification.

---

## Features

### Core Features
- **Browse Menu**: Explore a wide variety of meals with responsive UI and smooth scrolling.
- **Category Filtering**: Smart category-based filtering with auto-scrolling category navigation.
- **Search Functionality**: Instantly search loaded meals by name, ingredient, category, or description.
- **Location Selector**: Interactive map picker and reverse geocoding via `location_picker_page.dart`.
- **Uzbek Som Pricing**: Standardized currency formatting (`soʻm`) across all products, cart totals, and receipts.
- **Shopping Cart**: Add, remove, and manage items with custom quantity controls (`quantity_stepper.dart`).
- **Favorites Management**: Save favorite meals locally with real-time UI state synchronization.
- **Order Tracking**: Complete checkout flow with order placement, confirmation screens, and historical tracking.
- **User Authentication**: Email/password authentication managed via Firebase Auth.
- **User Profile**: Personal info management, account statistics, and session management.
- **Theme Support**: Seamless Light and Dark mode switching via `ThemeProvider`.

### Technical Features
- **Offline Support**: Fast local caching powered by Hive database.
- **State Management**: Clean Provider pattern for state isolation.
- **Responsive Design**: Custom widgets adapted for mobile, tablet, and web viewports.
- **Real-time Sync**: Cloud Firestore for live data synchronization.

---

## Tech Stack

### Frontend
- **Framework**: Flutter (Dart SDK >=3.7.2)
- **Design System**: Material Design & Cupertino Components

### Backend & Services
- **Firebase Auth**: User identity management
- **Cloud Firestore**: Real-time NoSQL database
- **Firebase Core**: Base SDK integration

### State Management & Local Storage
- **Provider**: App state management
- **Hive**: High-performance local object database
- **SharedPreferences**: Key-value settings storage

### Networking & Data
- **Dio**: HTTP client with interceptors and error handling
- **Scrollable Positioned List**: Synchronized list scrolling

---

## Project Structure

```
lib/
├── core/                               # Core shared utilities, constants, and design system
│   ├── constants/
│   │   ├── app_colors.dart             # Color scheme and palette
│   │   ├── app_pricing.dart            # Delivery pricing and fee constants
│   │   ├── app_text_styles.dart        # Typography styles
│   │   └── map_config.dart             # Map API keys and default coordinates
│   ├── errors/
│   │   └── app_exception.dart          # Custom error types and exception handling
│   ├── localization/
│   │   └── app_strings.dart            # Localized UI text strings
│   ├── network/
│   │   └── network_module.dart         # HTTP client & API network configuration
│   ├── session/
│   │   └── install_guard.dart          # First-launch setup & session verification
│   ├── theme/
│   │   ├── app_theme.dart              # Flutter ThemeData setup
│   │   └── theme_provider.dart         # Dark/Light mode state management
│   ├── utils/
│   │   ├── auth_error_messages.dart    # Firebase/Auth error message mappers
│   │   ├── haptics.dart                # Tactile/vaptic feedback utilities
│   │   ├── money.dart                  # Currency formatting helpers
│   │   └── phone_number.dart           # Phone number formatting & validation
│   └── widgets/
│       ├── app_card.dart               # Standardized custom card component
│       ├── quantity_stepper.dart       # Item count (+/-) control widget
│       └── state_view.dart             # Universal loading, empty, & error view
├── data/                               # Data layer (models, repositories, state managers)
│   ├── manager/
│   │   └── favorites_manager.dart      # Local favorites sync & state manager
│   ├── mock/
│   │   └── mock_products.dart          # Mock product data for testing/offline mode
│   ├── models/
│   │   ├── auth_method.dart            # Auth provider enum/model
│   │   ├── delivery_location.dart      # Address & location coordinates model
│   │   ├── meal_model.dart             # Meal item schema & data model
│   │   ├── meal_model.g.dart           # Hive generated adapter
│   │   ├── order_status.dart           # Order lifecycle state enum
│   │   └── user_role.dart              # User roles and permissions model
│   └── repositories/
│       ├── auth_repository.dart        # Authentication data source handler
│       ├── favorites_repository.dart   # Favorites persistence repository
│       ├── geocoding_repository.dart   # Location search & reverse-geocoding API
│       ├── local_storage_repo.dart     # SharedPreferences / local storage wrapper
│       ├── meal_repository.dart        # Meal catalog data fetching
│       ├── order_repository.dart       # Order creation & history management
│       └── product_repository.dart     # General product retrieval repository
├── presentation/                       # Presentation layer (UI screens & feature modules)
│   ├── auth/                           # Authentication feature module
│   │   ├── pages/                      # Login & signup screens
│   │   ├── provider/                   # Auth state management
│   │   └── widgets/                    # Custom input fields & auth buttons
│   ├── basket/                         # Cart feature module
│   │   ├── basket_page.dart            # Shopping cart overview screen
│   │   └── cart.dart                   # Cart item state & singleton manager
│   ├── categories/                     # Category browsing feature
│   │   └── categories_page.dart        # Categories grid view
│   ├── dashbboard/                     # Shell navigation feature
│   │   ├── main_page.dart              # Bottom navigation host page
│   │   └── widgets/                    # Navigation bar components
│   ├── favorites/                      # Saved items feature module
│   │   ├── favorites_page.dart         # Bookmarked items list screen
│   │   └── provider/                   # Favorites state provider
│   ├── home/                           # Main catalog feature module
│   │   ├── category_page.dart          # Filtered category items page
│   │   ├── home_page.dart              # Main home screen & feed
│   │   ├── product_detail_page.dart    # Detailed product view & add-to-cart
│   │   ├── providers/                  # Home feed state management
│   │   └── widgets/                    # Banners, search bar, & item cards
│   ├── location/                       # Location selection feature
│   │   └── location_picker_page.dart   # Map picker & delivery location selector
│   ├── orders/                         # Checkout & Order management
│   │   ├── checkout_page.dart          # Order placement & checkout screen
│   │   ├── order_confirm_page.dart     # Order confirmation screen
│   │   ├── order_detail_page.dart      # Detailed order summary & tracking
│   │   ├── order_page.dart             # User order history list
│   │   └── widgets/                    # Order status badges & list tiles
│   ├── profile/                        # Account management feature
│   │   ├── about_page.dart             # App details & version info screen
│   │   ├── personal_info_page.dart     # User profile editor screen
│   │   ├── profile_page.dart           # User profile & settings dashboard
│   │   └── settings_provider.dart      # Preferences & app settings state
│   └── search/                         # Search feature module
│       └── search_page.dart            # Product & meal search page
├── firebase_options.dart               # Generated Firebase initialization setup
└── main.dart                           # Flutter app entry point

```

---

## Getting Started

### Prerequisites

* **Flutter SDK**: `>=3.7.2`
* **Dart SDK**: `>=3.7.2`
* **Firebase Account**
* iOS Simulator / Android Emulator or Physical Device

### Installation Steps

1. **Clone the repository**:
```bash
git clone [https://github.com/lobarashurova/MP_Project.git](https://github.com/lobarashurova/MP_Project.git)
cd MP_Project

```


2. **Install dependencies**:
```bash
flutter pub get

```


3. **Firebase Setup**:
* Create a Firebase project at the [Firebase Console](https://console.firebase.google.com/).
* Register your iOS and Android apps.
* Place configuration files into their respective directories:
* Android: `android/app/google-services.json`
* iOS: `ios/Runner/GoogleService-Info.plist`


* Enable Email/Password authentication and initialize Cloud Firestore.


4. **Generate Data Model Adapters**:
```bash
dart run build_runner build --delete-conflicting-outputs

```


5. **Run the Application**:
```bash
flutter run

```



---

## Firebase Configuration

### Firestore Collections Structure

#### `users/`

```json
{
  "name": "string",
  "email": "string",
  "createdAt": "timestamp"
}

```

#### `orders/`

```json
{
  "userId": "string",
  "items": "array",
  "totalAmount": "number",
  "status": "string",
  "deliveryAddress": "string",
  "createdAt": "timestamp"
}

```

#### `products/`

```json
{
  "name": "string",
  "description": "string",
  "price": "number",
  "category": "string",
  "imageUrl": "string",
  "rating": "number"
}

```

---

## Building for Production

### Android
Generate a release APK or Android App Bundle for deployment:


### Build standalone APK
flutter build apk --release

### Build App Bundle for Google Play Store upload
flutter build appbundle --release

## App Architecture

### State Management

The project strictly implements the **Provider** pattern:

* `AuthProvider`: Manages user authentication, sign-up, and session destruction.
* `HomeProvider`: Controls catalog data retrieval, loading states, and active category filters.
* `FavoritesProvider`: Syncs saved items with local database storage.
* `ThemeProvider`: Handles dynamic switching between Light and Dark themes.
* `Cart`: A singleton state container managing shopping basket state and price totals.

### Data Flow

1. **Remote Tier**: Cloud Firestore / Dio Network Client $\rightarrow$ Repository Layer $\rightarrow$ Provider $\rightarrow$ UI Widgets
2. **Local Tier**: Hive Cache / SharedPreferences $\rightarrow$ Repository Layer $\rightarrow$ UI State

---

## Testing

Run the full automated test suite containing unit, widget, and integration test specs:

```bash
flutter test


### Key Test Suites (`test/`)

* `add_to_cart_integration_test.dart`: Complete cart addition integration test.
* `product_detail_page_test.dart`: Product detailed rendering and user actions.
* `geocoding_repository_test.dart`: Location lookup validation.
* `theme_provider_test.dart`: Theme state verification.

---

## Troubleshooting

1. **Firebase Configuration Errors**:
Verify that `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) match your Firebase project package name and bundle ID.
2. **Hive / Model Build Errors**:
If modifying annotated models, re-run code generation:
```bash
dart run build_runner build --delete-conflicting-outputs

```


3. **Build Cache Clean**:
```bash
flutter clean && flutter pub get

```



---

## Future Enhancements

* [ ] Push notifications for real-time order status changes
* [ ] Integration of local Uzbek payment gateways (Click, Payme)
* [ ] Live courier location tracking via map WebSocket stream
* [ ] Restaurant and vendor management module

---

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

* **Repository**: [https://github.com/lobarashurova/MP_Project](https://github.com/lobarashurova/MP_Project)

```
