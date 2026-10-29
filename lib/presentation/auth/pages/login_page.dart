import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/data/models/auth_method.dart';
import 'package:xurmo/data/repositories/auth_repository.dart';
import 'package:xurmo/presentation/auth/provider/auth_provider.dart';
import 'package:xurmo/presentation/auth/widgets/auth_fields.dart';
import 'package:xurmo/presentation/auth/widgets/auth_notice.dart';
import 'package:xurmo/presentation/auth/widgets/auth_method_toggle.dart';
import 'package:xurmo/core/utils/haptics.dart';

class LoginPage extends StatefulWidget {
  /// When true (the default) a successful login replaces this page with the
  /// home route. Set it to false when the page is embedded inside another
  /// screen, such as the profile tab, which rebuilds itself on login.
  final bool navigateOnSuccess;

  const LoginPage({super.key, this.navigateOnSuccess = true});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  AuthMethod _method = AuthMethod.email;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  /// Confirmation for an action that otherwise leaves no trace on screen,
  /// currently only the password reset email.
  String? _noticeMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchMethod(AuthMethod method) {
    if (method == _method) return;
    setState(() {
      _method = method;
      _errorMessage = null;
      _noticeMessage = null;
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      Haptics.warning();
      return;
    }
    Haptics.tap();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _noticeMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      switch (_method) {
        case AuthMethod.email:
          await auth.signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
        case AuthMethod.phone:
          await auth.signInWithPhone(
            phone: _phoneController.text,
            password: _passwordController.text,
          );
      }

      if (mounted && widget.navigateOnSuccess) {
        // Return to the existing home screen rather than pushing a second one.
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.popUntil((route) => route.isFirst);
        } else {
          navigator.pushReplacementNamed('/home');
        }
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    // The link is hidden on the Phone tab; this only catches a stray call.
    if (_method == AuthMethod.phone) return;

    final email = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ForgotPasswordSheet(initialEmail: _emailController.text),
    );
    if (email == null || !mounted) return;

    setState(() {
      _errorMessage = null;
      _noticeMessage = null;
    });

    try {
      await context.read<AuthProvider>().sendPasswordReset(email: email);
      if (mounted) {
        setState(() {
          _noticeMessage =
              'Reset link sent to $email. Check your inbox, and your spam '
              'folder if it is not there.';
        });
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Embedded in the profile tab, this sits inside MainPage's Scaffold,
      // which has already shrunk its body to make room for the keyboard.
      // Resizing here as well subtracts the keyboard height a second time and
      // squeezes the form into a strip a few dozen pixels tall, so the field
      // you tapped scrolls out of reach and the page looks frozen.
      resizeToAvoidBottomInset: widget.navigateOnSuccess,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          // Let a drag put the keyboard away, so a form taller than the
          // remaining space can still be read.
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            // Errors appear as the field is corrected rather than only on
            // submit.
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.iconPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to your account to continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),
                if (_errorMessage != null) ...[
                  AuthNotice(
                    message: _errorMessage!,
                    tone: AuthNoticeTone.error,
                  ),
                  const SizedBox(height: 16),
                ],
                if (_noticeMessage != null) ...[
                  AuthNotice(
                    message: _noticeMessage!,
                    tone: AuthNoticeTone.success,
                  ),
                  const SizedBox(height: 16),
                ],
                AuthMethodToggle(
                  value: _method,
                  onChanged: _switchMethod,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 20),
                authFieldLabel(_method == AuthMethod.email ? 'Email' : 'Phone Number'),
                const SizedBox(height: 8),
                if (_method == AuthMethod.email)
                  EmailField(
                    controller: _emailController,
                    enabled: !_isLoading,
                  )
                else
                  PhoneField(
                    controller: _phoneController,
                    enabled: !_isLoading,
                  ),
                const SizedBox(height: 20),
                Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.iconPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _isLoading ? null : _login(),
                  validator: validatePassword,
                ),
                // Phone accounts sign in through a synthetic address with no
                // inbox behind it, so there is nothing to send a reset to.
                if (_method == AuthMethod.email) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _forgotPassword,
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else
                  const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.onPrimary,
                        ),
                      ),
                    )
                        : const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/signup');
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
/// Asks for the email to send a reset link to and pops with it, or with null
/// when dismissed.
class _ForgotPasswordSheet extends StatefulWidget {
  final String initialEmail;

  const _ForgotPasswordSheet({required this.initialEmail});

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialEmail.trim());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset your password',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.iconPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Enter your email and we'll send you a link to set a new password.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Enter your email',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) return 'Email is required';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!.trim())) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Send Reset Link',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
