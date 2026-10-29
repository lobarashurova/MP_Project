import 'package:intl/intl.dart';

/// 80000 -> "80 000 soʻm". Sums have no decimals.
///
/// The unit is part of the formatted string so no screen can forget it; every
/// price in the app goes through here.
String formatSum(num amount) {
  final digits = NumberFormat('#,##0').format(amount.round());
  return "${digits.replaceAll(',', ' ')} soʻm";
}

/// Upgrades prices stored before the move to sums.
///
/// Cached meals and Firestore documents can still hold the old dollar-scale
/// figures (a 56 that meant $56). Anything under 1000 is far below any real
/// sum price, so it is read as a legacy value and scaled up.
double normalizeLegacySum(num amount) {
  final value = amount.toDouble();
  return value > 0 && value < 1000 ? value * 1000 : value;
}
