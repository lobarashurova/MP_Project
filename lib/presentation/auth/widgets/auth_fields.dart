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

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Email is required';
  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Enter a valid email';
  return null;
}

String? validatePhone(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Phone number is required';
  if (normalizePhone(v) == null) return 'Enter a valid phone number';
  return null;
}

class EmailField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const EmailField({super.key, required this.controller, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.emailAddress,
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

  const PhoneField({super.key, required this.controller, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      autofillHints: const [AutofillHints.telephoneNumber],
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-\+\(\)]')),
      ],
      decoration: authInputDecoration(
        hint: '90 123 45 67',
        icon: Icons.phone_outlined,
        prefixText: '+$defaultCountryCode ',
      ),
      validator: validatePhone,
    );
  }
}
