import 'package:intl/intl.dart';

/// 80000 -> "80 000 so'm". Sums have no decimals.
String formatSum(num amount) {
  final digits = NumberFormat('#,##0').format(amount.round());
  return "${digits.replaceAll(',', ' ')}";
}