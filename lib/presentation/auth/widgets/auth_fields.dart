import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/utils/phone_number.dart';

/// Form fields shared by the login and signup screens so both validate and
/// look the same.

InputDecoration authInputDecoration({
  required String hint,
  required IconData icon,
  Widget? suffixIcon,
  String? prefixText,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: AppColors.textSecondary),
    prefixIcon: Icon(icon),
    prefixText: prefixText,
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}

Widget authFieldLabel(String text) {
  return Text(
    text,
    style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.iconPrimary,
    ),
  );
}

/// Deliberately permissive: the only authority on whether an address exists
/// is the mail that gets sent to it. This rejects what is obviously not an
/// address, and nothing more.
final _emailPattern = RegExp(r"^[\w.!#$%&'*+/=?^`{|}~-]+@[\w-]+(\.[\w-]+)+$");

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Email is required';
  if (v.length > 254) return 'That email is too long';
  if (v.contains(' ')) return 'An email cannot contain spaces';
  if (!_emailPattern.hasMatch(v)) return 'Enter a valid email, like you@example.com';
  if (isSyntheticEmail(v)) {
    // Phone accounts are stored behind an address on a reserved domain. It is
    // not a real inbox, so nobody should be typing one in.
    return 'Use the Phone tab to sign in with a phone number';
  }
  return null;
}

/// Firebase rejects anything under six characters, so catching it here keeps
/// the round trip and the generic error message away from the user.
String? validatePassword(String? value) {
  final v = value ?? '';
  if (v.isEmpty) return 'Password is required';
  if (v.length < 6) return 'Password must be at least 6 characters';
  if (v.trimLeft() != v || v.trimRight() != v) {
    // A pasted password with stray whitespace fails at sign-in with an error
    // that gives no hint why.
    return 'Password cannot start or end with a space';
  }
  return null;
}

String? validateConfirmPassword(String? value, String password) {
  if ((value ?? '').isEmpty) return 'Confirm your password';
  if (value != password) return 'Passwords do not match';
  return null;
}

String? validateName(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Name is required';
  if (v.length < 2) return 'Enter your full name';
  if (v.length > 60) return 'That name is too long';
  return null;
}

String? validatePhone(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Phone number is required';
  if (normalizePhone(v) == null) {
    return 'Enter a valid number, like 90 123 45 67';
  }
  return null;
}

class EmailField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;

  const EmailField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction,
      onFieldSubmitted: (_) => onSubmitted?.call(),
      autocorrect: false,
      // An address typed with a capitalised first letter still has to match,
      // so the keyboard should not offer one.
      textCapitalization: TextCapitalization.none,
      autofillHints: const [AutofillHints.email],
      decoration: authInputDecoration(
        hint: 'Enter your email',
        icon: Icons.email_outlined,
      ),
      validator: validateEmail,
    );
  }
}

/// Phone entry with the +998 prefix shown. Typing the 9 local digits is
/// enough, but a full number with the country code is accepted too.
class PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;

  const PhoneField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      onFieldSubmitted: (_) => onSubmitted?.call(),
      autofillHints: const [AutofillHints.telephoneNumber],
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-\+\(\)]')),
      ],
      // prefixText is only painted when the field has focus or content, so
      // the country code vanished on an empty field. A prefixIcon is always
      // visible, so the icon and the code live there together.
      decoration: authInputDecoration(
        hint: '90 123 45 67',
        icon: Icons.phone_outlined,
      ).copyWith(
        prefixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 12),
            Icon(Icons.phone_outlined, color: AppColors.iconSecondary),
            const SizedBox(width: 6),
            Text(
              '+$defaultCountryCode',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
      validator: validatePhone,
    );
  }
}
