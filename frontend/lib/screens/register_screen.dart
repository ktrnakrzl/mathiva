import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../repositories/api/api_auth_repository.dart';
import '../repositories/auth_repository.dart';
import '../services/app_preferences.dart';
import '../services/auth_storage.dart';
import '../presentation/widgets/auth_widgets.dart';
import '../presentation/widgets/fade_slide_in.dart';
import '../theme/app_theme.dart';
import '../utils/route_names.dart';

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Sign up — the graph-paper brand band over a left-aligned form with live
/// password validation pills, per the auth-flow design handoff.
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
  // Recomputed live on every keystroke to drive the validation pills.
  String _password = '';
  String _confirm = '';

  bool get _hasMinLength => _password.length >= 8;
  bool get _passwordsMatch => _confirm.isNotEmpty && _confirm == _password;

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
    // Per-field validation (required fields, email format, password length and
    // match) runs first; the backend re-validates the same rules, but catching
    // it here shows exactly which field is wrong immediately.
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
      // The register endpoint doesn't return a token (per the spec), so log in
      // immediately with the same credentials to get the app's session.
      final token =
          await _authRepository.login(email: email, password: password);
      await AuthStorage.saveToken(token);
      // We already have the name from the form (identical to what the server
      // stored), so set the home greeting directly -- no /auth/me round-trip
      // needed here, unlike the login path.
      AppPreferences.studentName.value = name;
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
    final colors = AppTheme.colorsOf(context);

    return Scaffold(
      backgroundColor: colors.pageBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                const AuthBrandBand(tagline: 'Start learning the smart way.'),
                Positioned(
                  top: 4,
                  left: 6,
                  child: IconButton(
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/login'),
                    icon: Icon(Icons.arrow_back_rounded, color: colors.ink),
                    tooltip: 'Back',
                  ),
                ),
              ],
            ),
            Expanded(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                  children: [
                    FadeSlideIn(
                      child: Text(
                        'Create your account',
                        style: AppTheme.serif(
                          color: colors.ink,
                          fontSize: 28,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 70),
                      child: Text(
                        'Set up your learner profile and start practicing.',
                        style: TextStyle(
                          color: colors.muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    AuthField(
                      controller: _nameController,
                      hint: 'Full name',
                      icon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter your full name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    AuthField(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return 'Please enter your email';
                        if (!_emailPattern.hasMatch(t)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    AuthField(
                      controller: _sectionController,
                      hint: 'Section (optional)',
                      icon: Icons.class_outlined,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    AuthField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      textInputAction: TextInputAction.next,
                      onChanged: (v) => setState(() => _password = v),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (v.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    AuthField(
                      controller: _confirmPasswordController,
                      hint: 'Confirm password',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      onChanged: (v) => setState(() => _confirm = v),
                      onFieldSubmitted: (_) => _handleRegister(),
                      validator: (v) => v != _passwordController.text
                          ? 'Passwords do not match'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Live validation pills.
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _CheckPill(label: '8+ characters', ok: _hasMinLength),
                        _CheckPill(
                            label: 'Passwords match', ok: _passwordsMatch),
                      ],
                    ),
                    const SizedBox(height: 22),

                    AuthPrimaryButton(
                      label: 'Create Account',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _handleRegister,
                    ),
                    const SizedBox(height: 20),

                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: colors.muted,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => context.go(RouteNames.login),
                            child: Text(
                              'Log in',
                              style: TextStyle(
                                color: colors.accent,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Live validation pill ────────────────────────────────────────────────────

/// A requirement pill that fills accent + shows a check once [ok] is satisfied,
/// and reads neutral (muted, bordered) until then.
class _CheckPill extends StatelessWidget {
  final String label;
  final bool ok;
  const _CheckPill({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: ok ? colors.accent : colors.pillBg,
        borderRadius: BorderRadius.circular(999),
        border: ok ? null : Border.all(color: colors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_rounded : Icons.circle_outlined,
            size: 13,
            color: ok ? colors.onAccent : colors.subtleMuted,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: ok ? colors.onAccent : colors.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
