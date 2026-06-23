import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mathiva/presentation/notifiers/auth_notifier.dart';
import 'package:mathiva/presentation/widgets/loading_overlay.dart';
import 'package:mathiva/presentation/widgets/animated_background.dart';
import 'package:mathiva/presentation/widgets/fade_slide_in.dart';
import 'package:mathiva/services/app_preferences.dart';

const _ink = Color(0xFF242033);
const _muted = Color(0xFF8C879A);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'student@mathiva.ph');
  final _passwordController = TextEditingController(text: 'password');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (previous, next) {
      next.whenOrNull(data: (user) {
        if (user != null) context.go('/home');
      });
    });

    final authState = ref.watch(authNotifierProvider);
    final palette = AppPreferences.palette.value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
              physics: const BouncingScrollPhysics(),
              child: authState.when(
                data: (_) => Column(children: [
                  FadeSlideIn(
                    child: ColorFiltered(
                      colorFilter:
                          ColorFilter.mode(palette.primary, BlendMode.srcIn),
                      child: Image.asset('assets/mathiva_logo.png', height: 96),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [palette.primary, palette.secondary],
                      ).createShader(bounds),
                      child: const Text('Mathiva',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 130),
                    child: const Text(
                        'Log in and keep growing your math skills.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: _muted, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 34),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 180),
                    child: _AuthField(
                        controller: _emailController,
                        hintText: 'Email',
                        icon: Icons.mail_outline_rounded),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 220),
                    child: _AuthField(
                        controller: _passwordController,
                        hintText: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: true),
                  ),
                  const SizedBox(height: 22),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 260),
                    child: _GradientButton(
                        label: 'Log In',
                        onPressed: () => ref
                            .read(authNotifierProvider.notifier)
                            .login(_emailController.text,
                                _passwordController.text)),
                  ),
                  const SizedBox(height: 24),
                  const _DividerOr(),
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 300),
                    child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                            onPressed: () => context.go('/home'),
                            style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFFF7F9FC),
                                foregroundColor: _ink,
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14))),
                            icon: const Icon(Icons.g_mobiledata_rounded,
                                size: 30),
                            label: const Text('Continue with Google',
                                style:
                                    TextStyle(fontWeight: FontWeight.w800)))),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                      onPressed: () {},
                      child: Text('Sign up',
                          style: TextStyle(
                              color: palette.primary,
                              fontWeight: FontWeight.w900))),
                ]),
                loading: () => const LoadingOverlay(),
                error: (error, _) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $error', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      _GradientButton(
                          label: 'Try again',
                          onPressed: () => ref
                              .read(authNotifierProvider.notifier)
                              .login(_emailController.text,
                                  _passwordController.text))
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  const _AuthField(
      {required this.controller,
      required this.hintText,
      required this.icon,
      this.obscureText = false});

  @override
  Widget build(BuildContext context) {
    final palette = AppPreferences.palette.value;
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: palette.primary),
        filled: true,
        fillColor: const Color(0xFFF7F9FC),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: palette.primary, width: 1.6)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _GradientButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final palette = AppPreferences.palette.value;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
            gradient:
                LinearGradient(colors: [palette.primary, palette.secondary]),
            borderRadius: BorderRadius.circular(14)),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: const Color(0xFFF7F9FC),
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14))),
          child: Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ),
      ),
    );
  }
}

class _DividerOr extends StatelessWidget {
  const _DividerOr();
  @override
  Widget build(BuildContext context) => Row(children: const [
        Expanded(child: Divider(color: Color(0xFFE5E0F5))),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text('or', style: TextStyle(color: _muted))),
        Expanded(child: Divider(color: Color(0xFFE5E0F5)))
      ]);
}
