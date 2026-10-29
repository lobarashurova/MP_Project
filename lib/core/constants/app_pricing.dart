/// Pricing rules shared by the basket, checkout, and order screens.
///
/// Keep every fee here so the numbers shown to the customer and the numbers
/// written to Firestore always agree.
class AppPricing {
  AppPricing._();

  /// Flat delivery fee in sums.
  static const double deliveryFee = 15000;

  /// "Free item over ..." banner amount in sums.
  static const double promoThreshold = 200000;

  /// Shown in the "Delivery Time" banner.
  static const String deliveryTime = '25-30 min';

  /// Discount advertised on the home banner and applied to the basket.
  static const int promoDiscountPercent = 30;
}
