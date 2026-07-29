import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../presentation/widgets/auth_widgets.dart';
import '../repositories/api/api_auth_repository.dart';
import '../repositories/auth_repository.dart';
import '../theme/app_theme.dart';
import '../utils/route_names.dart';

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AuthRepository _authRepository = ApiAuthRepository();

  bool _isLoading = false;
  String? _error;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_emailPattern.hasMatch(email)) {
      setState(() {
        _error = 'Enter the email address on your account.';
        _message = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _message = null;
    });

    try {
      final message = await _authRepository.requestPasswordReset(email);
      if (!mounted) return;
      setState(() => _message = message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is AuthException
          ? e.message
          : 'Could not send a reset link. Please try again.');
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
            Stack(
              children: [
                const AuthBrandBand(tagline: 'Recover your account safely.'),
                Positioned(
                  top: 4,
                  left: 6,
                  child: IconButton(
                    onPressed: () => context.go(RouteNames.login),
                    icon: Icon(Icons.arrow_back_rounded, color: colors.ink),
                    tooltip: 'Back',
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
                children: [
                  Text(
                    'Reset your password',
                    style: GoogleFonts.fraunces(
                      color: colors.ink,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your email and we will send a reset link.',
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 26),
                  AuthField(
                    controller: _emailController,
                    hint: 'Email',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _requestReset(),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    AuthErrorBanner(message: _error!),
                    const SizedBox(height: 16),
                  ],
                  if (_message != null) ...[
                    _AuthSuccessBanner(message: _message!),
                    const SizedBox(height: 16),
                  ],
                  AuthPrimaryButton(
                    label: 'Send Reset Link',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _requestReset,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthSuccessBanner extends StatelessWidget {
  final String message;
  const _AuthSuccessBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF16A34A);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: green.withOpacity(0.32), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: green, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: green,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
