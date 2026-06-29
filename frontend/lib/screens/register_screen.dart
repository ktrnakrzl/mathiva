import 'package:flutter/material.dart';
import '../presentation/widgets/animated_background.dart';
import '../presentation/widgets/fade_slide_in.dart';
import '../presentation/widgets/glass_card.dart';
import '../repositories/api/api_auth_repository.dart';
import '../repositories/auth_repository.dart';
import '../services/app_preferences.dart';
import '../services/auth_storage.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_app_bar.dart';

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthRepository _authRepository = ApiAuthRepository();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _sectionController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Per-field validation (required fields, email format, password length
    // and match) runs first -- the backend re-validates the same rules, but
    // catching it here means the user sees exactly which field is wrong
    // immediately instead of a generic toast after a round trip.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final section = _sectionController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);
    try {
      await _authRepository.register(
        email: email,
        password: password,
        fullName: name,
        section: section.isEmpty ? null : section,
      );
      // The register endpoint doesn't return a token (per the spec), so log
      // in immediately with the same credentials to get the app's session.
      final token =
          await _authRepository.login(email: email, password: password);
      await AuthStorage.saveToken(token);
      if (!mounted) return;
      context.go(RouteNames.home);
    } catch (e) {
      if (!mounted) return;
      _showError(e is AuthException
          ? e.message
          : 'Could not create your account. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    final colors = AppTheme.colorsOf(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: colors.pageBg)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.ink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;
    final colors = AppTheme.colorsOf(context);

    return Scaffold(
      backgroundColor: colors.pageBg,
      appBar: MathivaAppBar(
        title: 'Create Account',
        subtitle: 'Join Mathivia today',
        icon: Icons.person_add_rounded,
        showBack: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/login'),
      ),
      body: AnimatedBackground(
        vivid: true,
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              physics: const BouncingScrollPhysics(),
              children: [
                FadeSlideIn(
                  child: Text(
                    'Join Mathivia',
                    style: TextStyle(
                      // Same brand-indigo used for the "Mathivia" wordmark on
                      // the login screen and every MathivaAppBar title, so
                      // this primary heading reads consistently with the
                      // rest of the app rather than as generic body text.
                      color: colors.titleColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: Text(
                    'Create your learner profile and start practicing.',
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Form card ──
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: GlassCard(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Field(
                          controller: _nameController,
                          hint: 'Full name',
                          icon: Icons.person_outline_rounded,
                          primary: primary,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Please enter your full name'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          controller: _emailController,
                          hint: 'Email',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          primary: primary,
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!_emailPattern.hasMatch(trimmed)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          controller: _sectionController,
                          hint: 'Section (optional)',
                          icon: Icons.class_outlined,
                          textInputAction: TextInputAction.next,
                          primary: primary,
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          controller: _passwordController,
                          hint: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          primary: primary,
                          suffixIcon: _PasswordVisibilityToggle(
                            obscured: _obscurePassword,
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          controller: _confirmPasswordController,
                          hint: 'Confirm password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          primary: primary,
                          suffixIcon: _PasswordVisibilityToggle(
                            obscured: _obscureConfirmPassword,
                            onPressed: () => setState(() =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword),
                          ),
                          onFieldSubmitted: (_) => _handleRegister(),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        _PrimaryButton(
                          label: 'Create Account',
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _handleRegister,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                FadeSlideIn(
                  delay: const Duration(milliseconds: 170),
                  child: Center(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => context.go(RouteNames.login),
                      child: Text(
                        'Already have an account? Log in',
                        style: TextStyle(
                          color: primary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Field ────────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Color primary;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final ValueChanged<String>? onFieldSubmitted;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.primary,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.suffixIcon,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscure,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: TextStyle(
        color: colors.ink,
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: colors.muted,
          fontSize: 14.5,
          fontWeight: FontWeight.w400,
        ),
        errorStyle: const TextStyle(fontSize: 12),
        prefixIcon: Icon(icon, color: colors.muted, size: 19),
        suffixIcon: suffixIcon,
        // Translucent, not solid -- so the field reads as part of the glass
        // card rather than a disconnected opaque box sitting on top of it.
        filled: true,
        fillColor: colors.glassChipFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: colors.glassBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: colors.glassBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
    );
  }
}

// ─── Password visibility toggle ────────────────────────────────────────────────

class _PasswordVisibilityToggle extends StatelessWidget {
  final bool obscured;
  final VoidCallback onPressed;

  const _PasswordVisibilityToggle({
    required this.obscured,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppTheme.colorsOf(context).muted,
        size: 19,
      ),
      onPressed: onPressed,
      tooltip: obscured ? 'Show password' : 'Hide password',
    );
  }
}

// ─── Primary Button ───────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: primary),
              )
            : Text(
                label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
              ),
      ),
    );
  }
}
