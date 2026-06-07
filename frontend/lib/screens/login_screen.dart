import 'package:flutter/material.dart';

import '../services/app_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/route_names.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool rememberMe = false;
  bool obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final palette = AppPreferences.palette.value;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _PurpleAtmospherePainter(palette)),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactHeight = constraints.maxHeight < 720;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(26, 18, 26, 28),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight - 46),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _BackButton(
                            onTap: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                        SizedBox(height: compactHeight ? 26 : 42),
                        const _BrandLockup(),
                        SizedBox(height: compactHeight ? 34 : 48),
                        const Text(
                          'Welcome back!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 30,
                            height: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Log in to continue your learning',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: compactHeight ? 34 : 54),
                        _LoginCard(
                          palette: palette,
                          rememberMe: rememberMe,
                          obscurePassword: obscurePassword,
                          onRememberChanged: (value) =>
                              setState(() => rememberMe = value ?? false),
                          onPasswordVisibilityChanged: () => setState(
                            () => obscurePassword = !obscurePassword,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/mathiva_logo.png',
          height: 88,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(height: 10),
        const Text(
          'mathiva',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 35,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  final MathiviaPalette palette;
  final bool rememberMe;
  final bool obscurePassword;
  final ValueChanged<bool?> onRememberChanged;
  final VoidCallback onPasswordVisibilityChanged;

  const _LoginCard({
    required this.palette,
    required this.rememberMe,
    required this.obscurePassword,
    required this.onRememberChanged,
    required this.onPasswordVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: Colors.white.withValues(alpha: .95),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: .14),
            blurRadius: 54,
            offset: const Offset(0, 26),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _LoginTextField(
            icon: Icons.mail_outline_rounded,
            hintText: 'Email or username',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          _LoginTextField(
            icon: Icons.lock_outline_rounded,
            hintText: 'Password',
            obscureText: obscurePassword,
            suffixIcon: obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            onSuffixPressed: onPasswordVisibilityChanged,
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              SizedBox(
                height: 28,
                width: 28,
                child: Checkbox(
                  value: rememberMe,
                  onChanged: onRememberChanged,
                  activeColor: palette.primary,
                  side: BorderSide(
                    color: AppColors.muted.withValues(alpha: .52),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Remember me',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: palette.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _PrimaryLoginButton(
            palette: palette,
            onPressed: () =>
                Navigator.pushReplacementNamed(context, RouteNames.home),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: palette.primary.withValues(alpha: .14),
                  thickness: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 22),
                child: Text(
                  'or',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: palette.primary.withValues(alpha: .14),
                  thickness: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Navigator.pushReplacementNamed(
              context,
              RouteNames.home,
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 62),
              foregroundColor: AppColors.ink,
              side: BorderSide(color: palette.primary.withValues(alpha: .14)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GoogleGlyph(),
                SizedBox(width: 18),
                Flexible(child: Text('Continue with Google')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              const Text(
                "Don't have an account?",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  RouteNames.register,
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 34),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Sign up',
                  style: TextStyle(
                    color: palette.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoginTextField extends StatelessWidget {
  final IconData icon;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixPressed;

  const _LoginTextField({
    required this.icon,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.onSuffixPressed,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPreferences.palette.value;

    return TextField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.muted,
          fontSize: 17,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: palette.primary, size: 28),
        suffixIcon: suffixIcon == null
            ? null
            : IconButton(
                onPressed: onSuffixPressed,
                icon: Icon(suffixIcon, color: AppColors.muted, size: 27),
              ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 23),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: palette.primary.withValues(alpha: .12),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: palette.primary.withValues(alpha: .42),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _PrimaryLoginButton extends StatelessWidget {
  final MathiviaPalette palette;
  final VoidCallback onPressed;

  const _PrimaryLoginButton({required this.palette, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Ink(
          height: 66,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                palette.primary,
                palette.secondary,
                const Color(0xFFC02BDD),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: palette.primary.withValues(alpha: .26),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Log In',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        color: Color(0xFF4285F4),
        fontSize: 24,
        fontWeight: FontWeight.w800,
        fontFamily: 'Inter',
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          height: 44,
          width: 44,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.ink,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _PurpleAtmospherePainter extends CustomPainter {
  final MathiviaPalette palette;

  const _PurpleAtmospherePainter(this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFBF9FF), Color(0xFFF3ECFF), Color(0xFFFFFDFF)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    final topWash = Paint()
      ..color = palette.secondary.withValues(alpha: .24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 92);
    canvas.drawOval(Rect.fromLTWH(-50, 40, size.width * 1.1, 260), topWash);

    final rightWash = Paint()
      ..color = palette.primary.withValues(alpha: .2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 96);
    canvas.drawOval(
      Rect.fromLTWH(size.width * .5, 118, size.width * .76, 300),
      rightWash,
    );

    final lowerWash = Paint()
      ..color = const Color(0xFFC7B6FF).withValues(alpha: .2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90);
    canvas.drawOval(
      Rect.fromLTWH(-90, size.height * .62, size.width * 1.04, 260),
      lowerWash,
    );

    _drawOrb(
      canvas,
      center: Offset(size.width * .1, size.height * .28),
      radius: 32,
      color: palette.secondary,
    );
    _drawOrb(
      canvas,
      center: Offset(size.width * .88, size.height * .14),
      radius: 34,
      color: const Color(0xFFC5A5FF),
    );
  }

  void _drawOrb(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final orb = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.35, -.55),
        radius: .95,
        colors: [
          Colors.white.withValues(alpha: .96),
          color.withValues(alpha: .5),
          palette.primary.withValues(alpha: .2),
        ],
        stops: const [.02, .48, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final shadow = Paint()
      ..color = palette.primary.withValues(alpha: .12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(center.translate(0, 10), radius * .95, shadow);
    canvas.drawCircle(center, radius, orb);
  }

  @override
  bool shouldRepaint(covariant _PurpleAtmospherePainter oldDelegate) {
    return oldDelegate.palette != palette;
  }
}
