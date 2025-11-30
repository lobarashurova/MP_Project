# Project Test Suite

This directory contains the automated tests for the application. Writing tests is a crucial step in software development to ensure the code is reliable, bug-free, and easy to maintain over time.

## How to Run Tests

To run all the tests in the project, open a terminal in the project's root directory and execute the following command:

```bash
flutter test
```

## Test Architecture

This project utilizes a multi-layered testing strategy, which is a professional standard for ensuring quality. The suite includes:

1.  **Unit Tests:** To verify individual functions or classes in isolation.
2.  **Widget Tests:** To verify the UI and interactivity of individual screens and components.
3.  **Integration Tests:** To verify a complete user-flow across multiple screens.

---

## Test Descriptions

### Unit Tests

#### `meal_model_test.dart`
-   **Purpose:** Tests the `MealModel` data class.
-   **What it covers:** Verifies that a `MealModel` object can be correctly created from JSON data (simulating an API response) and that computed properties like `price` are calculated correctly.

#### `local_storage_repository_test.dart`
-   **Purpose:** Tests the `LocalStorageRepository`, which handles saving data to the device's local storage.
-   **What it covers:** Ensures that adding, retrieving, and deleting data for favorites, the shopping cart, and orders works as expected.

---

### Widget Tests

#### `product_detail_page_test.dart`
-   **Purpose:** Tests the product detail screen.
-   **What it covers:** Verifies that all UI elements for a given meal (name, price, description) are displayed correctly and that user interactions, like tapping the "Add to Basket" button, trigger the appropriate response (e.g., a SnackBar).

#### `cart_item_card_test.dart`
-   **Purpose:** Tests the reusable `CartItemCard` widget.
-   **What it covers:** Verifies that the card correctly displays a meal's name, price, and quantity. It also tests that tapping the "+" and "-" buttons correctly updates the item quantity in the cart.

---

### Integration Test

#### `add_to_cart_integration_test.dart`
-   **Purpose:** Tests the complete "add to cart" user journey from start to finish.
-   **What it covers:** This test simulates a real user's actions. It starts on the product detail page, taps the "Add to Basket" button, navigates to the basket screen, and verifies that the item is correctly displayed in the basket. This test is critical as it proves that multiple screens (`ProductDetailPage`, `BasketPage`) and the underlying business logic (`Cart`) all work together seamlessly.
