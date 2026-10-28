/// Pricing rules shared by the basket, checkout, and order screens.
///
/// Keep every fee here so the numbers shown to the customer and the numbers
/// written to Firestore always agree.
class AppPricing {
  AppPricing._();

  /// Flat delivery fee added to every non-empty order.
  static const double deliveryFee = 15000;
  static const double promoThreshold = 200000; // the "Free item over" banner
  /// Estimated delivery window shown in the basket.
  static const String deliveryTime = '25-30 min';
}
