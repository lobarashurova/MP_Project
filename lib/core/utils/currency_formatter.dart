import 'package:intl/intl.dart';

final NumberFormat _somNumberFormat = NumberFormat.decimalPattern('en_US');

String formatSom(num amount) {
  final formattedAmount =
      _somNumberFormat.format(amount.round()).replaceAll(',', ' ');
  return '$formattedAmount soʻm';
}

double normalizeLegacySomAmount(num amount) {
  final value = amount.toDouble();
  return value > 0 && value < 1000 ? value * 1000 : value;
}
