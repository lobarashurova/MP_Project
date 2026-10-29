/// Phone number helpers for password-based phone accounts.
///
/// Xurmo lets people register with a phone number and a password, without
/// SMS verification. Firebase Auth only supports passwords on email accounts,
/// so a phone account is stored as an email account whose address is derived
/// from the number: "+998901234567" becomes "998901234567@phone.xurmo.app".
/// Nothing is ever sent to that address. It exists only as a stable, unique
/// identifier.
library;

/// Reserved domain for synthetic phone-account emails. Never send mail here.
const String phoneEmailDomain = 'phone.xurmo.app';

/// Uzbekistan's country code, assumed when a number is typed without one.
const String defaultCountryCode = '998';

/// Normalizes user input to E.164 form ("+998901234567"), or returns null
/// when the input cannot be a valid phone number.
///
/// Accepts spaces, dashes, and parentheses. A 9-digit local Uzbek number gets
/// the +998 prefix. A number already carrying a country code, with or without
/// the leading "+", is kept as typed.
String? normalizePhone(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;

  final hasPlus = trimmed.startsWith('+');
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;

  if (hasPlus) {
    return _isValidLength(digits) ? '+$digits' : null;
  }

  // Local Uzbek number without a country code.
  if (digits.length == 9) {
    return '+$defaultCountryCode$digits';
  }

  // Uzbek number typed with the country code but without "+".
  if (digits.length == 12 && digits.startsWith(defaultCountryCode)) {
    return '+$digits';
  }

  // Any other international number typed without "+".
  return _isValidLength(digits) && digits.length >= 11 ? '+$digits' : null;
}

bool _isValidLength(String digits) => digits.length >= 10 && digits.length <= 15;

/// Builds the synthetic email for a normalized E.164 phone number.
String phoneToSyntheticEmail(String e164Phone) {
  final digits = e164Phone.replaceAll(RegExp(r'\D'), '');
  return '$digits@$phoneEmailDomain';
}

/// True when [email] is a synthetic phone-account address.
bool isSyntheticEmail(String? email) {
  return email != null && email.toLowerCase().endsWith('@$phoneEmailDomain');
}

/// Recovers the E.164 phone number from a synthetic email, or null if the
/// email is not synthetic.
String? phoneFromSyntheticEmail(String? email) {
  if (!isSyntheticEmail(email)) return null;
  return '+${email!.split('@').first}';
}

/// Formats an E.164 number for display. Uzbek numbers are grouped the way
/// people write them locally: "+998 90 123 45 67". Others are returned as-is.
String formatPhoneForDisplay(String e164Phone) {
  final digits = e164Phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 12 && digits.startsWith(defaultCountryCode)) {
    final local = digits.substring(3);
    return '+$defaultCountryCode ${local.substring(0, 2)} ${local.substring(2, 5)} '
        '${local.substring(5, 7)} ${local.substring(7, 9)}';
  }
  return e164Phone.startsWith('+') ? e164Phone : '+$e164Phone';
}
