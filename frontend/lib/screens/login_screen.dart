import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../repositories/api/api_auth_repository.dart';
import '../repositories/auth_repository.dart';
import '../services/app_preferences.dart';
import '../services/auth_storage.dart';
import '../utils/route_names.dart';
import '../presentation/widgets/auth_widgets.dart';
import '../presentation/widgets/fade_slide_in.dart';
import '../theme/app_theme.dart';

/// Login — a graph-paper editorial brand band over a left-aligned form, per the
/// auth-flow "mathematical notebook" design handoff.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthRepository _authRepository = ApiAuthRepository();

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token =
          await _authRepository.login(email: email, password: password);
      await AuthStorage.saveToken(token);
      // Pull the student's profile so the home greeting shows their real name
      // instead of the default. Non-fatal: a /auth/me hiccup shouldn't block
      // an otherwise-successful login -- the greeting just falls back.
      await _loadProfileName();
      if (!mounted) return;
      context.go(RouteNames.home);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is AuthException
          ? e.message
          : 'Could not log in. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Fetches the profile and pushes the student's name into [AppPreferences]
  /// so the home greeting picks it up. Best-effort -- any failure is swallowed
  /// so it can never block navigation to home after a valid login.
  Future<void> _loadProfileName() async {
    try {
      final profile = await _authRepository.getProfile();
      AppPreferences.studentName.value = profile.fullName;
    } catch (_) {
      // Leave the greeting on its default name.
    }
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
            const AuthBrandBand(tagline: 'Your step-by-step math tutor.'),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
                children: [
                  FadeSlideIn(
                    child: Text(
                      'Welcome back',
                      style: GoogleFonts.fraunces(
                        color: colors.ink,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 70),
                    child: Text(
                      'Log in to keep growing your math skills.',
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),

                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: AuthField(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 150),
                    child: AuthField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: colors.muted,
                      ),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 4),
                    AuthErrorBanner(message: _error!),
                    const SizedBox(height: 16),
                  ] else
                    const SizedBox(height: 10),

                  AuthPrimaryButton(
                    label: 'Log In',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handleLogin,
                  ),
                  const SizedBox(height: 20),
                  const _DividerOr(),
                  const SizedBox(height: 20),
                  _GoogleButton(onPressed: () => context.go(RouteNames.home)),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'New to Mathiva? ',
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
                        onPressed: () => context.push(RouteNames.register),
                        child: Text(
                          'Sign up',
                          style: TextStyle(
                            color: colors.accent,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Google Button ────────────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _GoogleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.surface,
          foregroundColor: colors.ink,
          side: BorderSide(color: colors.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          elevation: 0,
        ),
        icon: Image.asset(
          'assets/google.png',
          height: 18,
          width: 18,
          fit: BoxFit.contain,
        ),
        label: const Text(
          'Continue with Google',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }
}

// ─── Divider ──────────────────────────────────────────────────────────────────

class _DividerOr extends StatelessWidget {
  const _DividerOr();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Row(
      children: [
        Expanded(
            child: Divider(color: colors.border, height: 1, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(
              color: colors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
            child: Divider(color: colors.border, height: 1, thickness: 1)),
      ],
    );
  }
}
