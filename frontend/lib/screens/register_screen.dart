import 'package:flutter/material.dart';
import '../presentation/widgets/atmosphere_background.dart';
import '../presentation/widgets/fade_slide_in.dart';
import '../presentation/widgets/primary_button.dart';
import '../services/app_preferences.dart';
import 'package:go_router/go_router.dart';

import '../utils/route_names.dart';
import '../widgets/mathiva_app_bar.dart';

// Shared tokens — identical values to HomeScreen's palette, so this screen
// reads as the same surface system rather than its own design.
const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);
const _surface = Color(0xFFFFFFFF);
const _pageBg = Color(0xFFF8F9FB);

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: MathivaAppBar(
        title: 'Create Account',
        subtitle: 'Join Mathivia today',
        icon: Icons.person_add_rounded,
        showBack: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/login'),
      ),
      body: AtmosphereBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            physics: const BouncingScrollPhysics(),
            children: [
              FadeSlideIn(
                child: Text(
                  'Join Mathivia',
                  style: const TextStyle(
                    color: _ink,
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
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Form card ──
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _border, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Field(
                        hint: 'Full name',
                        icon: Icons.person_outline_rounded,
                        primary: primary,
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        hint: 'Email',
                        icon: Icons.mail_outline_rounded,
                        primary: primary,
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        hint: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscure: true,
                        primary: primary,
                      ),
                      const SizedBox(height: 18),
                      PrimaryButton(
                        label: 'Create Account',
                        onPressed: () => context.go(RouteNames.home),
                        height: 50,
                        borderRadius: 13,
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
    );
  }
}

// ─── Field ────────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String hint;
  final IconData icon;
  final bool obscure;
  final Color primary;

  const _Field({
    required this.hint,
    required this.icon,
    required this.primary,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscure,
      style: const TextStyle(
        color: _ink,
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: _muted,
          fontSize: 14.5,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(icon, color: _muted, size: 19),
        filled: true,
        fillColor: _pageBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
    );
  }
}