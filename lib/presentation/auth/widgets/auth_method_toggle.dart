import 'package:flutter/material.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/data/models/auth_method.dart';

/// Email / Phone switch shown at the top of the login and signup forms.
class AuthMethodToggle extends StatelessWidget {
  final AuthMethod value;
  final ValueChanged<AuthMethod> onChanged;
  final bool enabled;

  const AuthMethodToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<AuthMethod>(
        segments: const [
          ButtonSegment(
            value: AuthMethod.email,
            label: Text('Email'),
            icon: Icon(Icons.email_outlined),
          ),
          ButtonSegment(
            value: AuthMethod.phone,
            label: Text('Phone'),
            icon: Icon(Icons.phone_outlined),
          ),
        ],
        selected: {value},
        onSelectionChanged: enabled ? (set) => onChanged(set.first) : null,
        showSelectedIcon: false,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? Colors.white
                : AppColors.textSecondary;
          }),
          side: WidgetStateProperty.all(BorderSide(color: AppColors.border)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
