# Data Layer Architecture

## 1. Overview

The `data` layer is the architectural foundation of this application. It serves as the **single source of truth** for all information, such as meal details, user profiles, and order history. Its primary responsibility is to abstract the origins of the data (network, local database, etc.) from the rest of the application.

This layer is completely independent of the UI (`presentation` layer). It has no knowledge of how the data will be displayed, which allows for a clean separation of concerns and makes the application more scalable and maintainable.

## 2. Core Architectural Design: The Repository Pattern

This project uses the **Repository Pattern**, a widely adopted architectural design that mediates between the application's domain (business logic) and the data mapping layers.

- **What it is:** A repository acts as a centralized access point for a specific type of data. For example, a `MealRepository` handles all operations related to meals.
- **Why it's used:** When another part of the app (e.g., a provider in the `presentation` layer) needs data, it simply asks the repository. It does not need to know *how* or *from where* the repository gets the data. This decouples the business logic from the data sources, making the system highly flexible. For example, we could swap our local Hive database for an SQLite database with zero changes required in the UI layer.

## 3. Directory Structure

The `data` layer is organized into the following sub-directories:

### `/models`

This directory contains the data structures, or "models," that define the shape of the data used in the application.

- **Purpose:** To create strongly-typed Dart objects that represent real-world entities.
- **Example: `MealModel.dart`**
    - This class defines the structure of a single meal, with properties like `id`, `name`, `price`, `ingredients`, and `imageUrl`.
    - It includes `fromJson()` and `toJson()` methods, which are essential for serializing and deserializing data when communicating with APIs or local storage. The `fromJson` factory constructor, for instance, is responsible for converting raw JSON data into a structured `MealModel` object.

### `/repositories`

This directory contains the concrete implementations of the Repository Pattern. Each repository class is responsible for managing a specific domain of data.

- **Purpose:** To handle the logic of fetching, caching, and storing a particular type of data.
- **Key Repositories:** `MealRepository`, `LocalStorageRepository`, `AuthRepository`, `FavoritesRepository`.

### `/manager`

This directory contains classes that manage complex data states or business logic that may not fit neatly into a single repository.

- **Purpose:** To orchestrate data from multiple sources or to handle specific business rules that span across different data domains.

### `/mock`

This directory holds mock data or mock implementations of data sources.

- **Purpose:** Primarily used for development and testing. Mock data allows the UI to be developed and tested without a dependency on a live backend service. It provides consistent and predictable data, which is essential for writing reliable tests.

## 4. Example Data Flow: Adding an Item to the Cart

To illustrate how the layers work together:

1.  **UI Layer (`ProductDetailPage`):** A user taps the "Add to Basket" button.
2.  **Logic (`Cart` class):** An event handler calls `Cart.instance.add(meal)`.
3.  **Data Layer (`LocalStorageRepository`):** The `Cart` singleton uses the `LocalStorageRepository` to persist the new state.
4.  **Data Source (Hive):** The repository interacts directly with the `hive` package to write the `MealModel` data to the device's local storage.

This clean separation ensures that the UI is only responsible for presenting data and capturing user input, while the data layer handles all the complexities of data management.