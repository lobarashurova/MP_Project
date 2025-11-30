
# Core Module

The `core` directory contains the fundamental building blocks that the rest of the project depends on. It provides shared resources such as design constants and the network layer used across features.

## Structure

```
core/
 ├── constants/
 │    ├── app_colors.dart
 │    └── app_text_styles.dart
 └── network/
      └── network_module.dart
```

## constants/

This folder stores values that define the visual identity of the app.
It keeps styling consistent and makes it easier to maintain or update the UI.

* **app_colors.dart**
  Contains all color values used throughout the app. They are grouped and named clearly so widgets can reuse them instead of hard-coding colors.

* **app_text_styles.dart**
  Defines reusable text styles. Fonts, weights, and sizes stay centralized instead of being duplicated in different screens.

## network/

This folder handles external communication with the public API used for meal information.

* **network_module.dart**
  Contains functions and setup related to making requests, parsing responses, and handling basic API behavior. Other features import this module when they need meal data or any network-related utilities.

