import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../presentation/widgets/auth_widgets.dart';
import '../repositories/api/api_auth_repository.dart';
import '../repositories/auth_repository.dart';
import '../theme/app_theme.dart';
import '../utils/route_names.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final AuthRepository _authRepository = ApiAuthRepository();

  bool _isLoading = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (widget.token.isEmpty) {
      setState(() => _error = 'This reset link is missing its token.');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authRepository.resetPassword(
        token: widget.token,
        newPassword: password,
      );
      if (!mounted) return;
      setState(() => _done = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is AuthException
          ? e.message
          : 'Could not reset your password. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            const AuthBrandBand(tagline: 'Choose a new secure password.'),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
                children: [
                  Text(
                    _done ? 'Password updated' : 'Create new password',
                    style: GoogleFonts.fraunces(
                      color: colors.ink,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _done
                        ? 'You can now log in with your new password.'
                        : 'Use at least 8 characters.',
                    style: TextStyle(color: colors.muted, fontSize: 14),
                  ),
                  const SizedBox(height: 26),
                  if (_done) ...[
                    AuthPrimaryButton(
                      label: 'Back to Login',
                      onPressed: () => context.go(RouteNames.login),
                    ),
                  ] else ...[
                    AuthField(
                      controller: _passwordController,
                      hint: 'New password',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    AuthField(
                      controller: _confirmController,
                      hint: 'Confirm new password',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _resetPassword(),
                    ),
                    const SizedBox(height: 16),
                    if (_error != null) ...[
                      AuthErrorBanner(message: _error!),
                      const SizedBox(height: 16),
                    ],
                    AuthPrimaryButton(
                      label: 'Reset Password',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _resetPassword,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go(RouteNames.login),
                        child: Text(
                          'Back to login',
                          style: TextStyle(
                            color: colors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
