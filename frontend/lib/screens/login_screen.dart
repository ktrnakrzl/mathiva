import 'package:flutter/material.dart';
import '../services/app_preferences.dart';

import '../theme/app_theme.dart';
import '../utils/route_names.dart';
import '../widgets/gradient_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool rememberMe = true;

  @override
  Widget build(BuildContext context) {
    final palette = AppPreferences.palette.value;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
              child: CustomPaint(painter: _PurpleAtmospherePainter(palette))),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight - 46),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _CircleIconButton(
                                icon: Icons.menu_rounded, onTap: () {}),
                            const SizedBox(width: 12),
                            const Text(
                              'Mathiva',
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            _CircleIconButton(
                                icon: Icons.auto_awesome_rounded, onTap: () {}),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _LoginHeroPanel(
                            palette: palette,
                            compact: constraints.maxWidth < 360),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .9),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: .95),
                                width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: palette.primary.withValues(alpha: .22),
                                blurRadius: 42,
                                offset: const Offset(0, 24),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    height: 54,
                                    width: 54,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(colors: [
                                        palette.secondary,
                                        palette.primary
                                      ]),
                                    ),
                                    child: const Icon(Icons.functions_rounded,
                                        color: Colors.white, size: 28),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Welcome back',
                                          style: TextStyle(
                                            color: AppColors.ink,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          'Continue your lesson flow',
                                          style: TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              const TextField(
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  prefixIcon:
                                      Icon(Icons.email_rounded, size: 19),
                                  hintText: 'Email',
                                ),
                              ),
                              const SizedBox(height: 12),
                              const TextField(
                                obscureText: true,
                                decoration: InputDecoration(
                                  prefixIcon:
                                      Icon(Icons.lock_rounded, size: 19),
                                  hintText: 'Password',
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Transform.scale(
                                    scale: .92,
                                    child: Checkbox(
                                      value: rememberMe,
                                      onChanged: (value) => setState(
                                          () => rememberMe = value ?? true),
                                      activeColor:
                                          Theme.of(context).colorScheme.primary,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                    ),
                                  ),
                                  const Text('Remember me',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.muted)),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () {},
                                    child: const Text('Forgot password?',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              GradientButton(
                                label: 'Login',
                                icon: Icons.arrow_forward_rounded,
                                onPressed: () => Navigator.pushReplacementNamed(
                                    context, RouteNames.home),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                      child: Divider(
                                          color: palette.primary
                                              .withValues(alpha: .14))),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('or continue with',
                                        style: TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12)),
                                  ),
                                  Expanded(
                                      child: Divider(
                                          color: palette.primary
                                              .withValues(alpha: .14))),
                                ],
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: () => Navigator.pushReplacementNamed(
                                    context, RouteNames.home),
                                icon: Text('G',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: palette.secondary)),
                                label: const Text('Google'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  foregroundColor: AppColors.ink,
                                  side: BorderSide(
                                      color: palette.primary
                                          .withValues(alpha: .16)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18)),
                                  textStyle: const TextStyle(
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Flexible(
                              child: Text(
                                "Don't have an account yet?",
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.muted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(
                                  context, RouteNames.register),
                              child: const Text('Sign up now',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
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

class _LoginHeroPanel extends StatelessWidget {
  final MathiviaPalette palette;
  final bool compact;

  const _LoginHeroPanel({required this.palette, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 188 : 210,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.secondary.withValues(alpha: .96),
            palette.primary,
            const Color(0xFF6B3DEB),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: .35),
            blurRadius: 46,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Container(
              height: 112,
              width: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: .22), width: 18),
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 2,
            child: Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .16),
              ),
              child: const Icon(Icons.psychology_alt_rounded,
                  color: Colors.white, size: 38),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'AI Math Tutor',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800),
                ),
              ),
              const Spacer(),
              Text(
                'Learn Math\nwith AI.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 31 : 36,
                  height: 1.02,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(
                width: 230,
                child: Text(
                  'Practice, solve, and review lessons in one soft purple workspace.',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
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
        colors: [Color(0xFFF8F5FF), Color(0xFFEDE5FF), Color(0xFFFFFFFF)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    final topWash = Paint()
      ..color = palette.secondary.withValues(alpha: .34)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 72);
    canvas.drawOval(Rect.fromLTWH(-70, 48, size.width * .95, 220), topWash);

    final rightWash = Paint()
      ..color = palette.primary.withValues(alpha: .28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 86);
    canvas.drawOval(
        Rect.fromLTWH(size.width * .45, 120, size.width * .82, 300), rightWash);

    final lowerWash = Paint()
      ..color = const Color(0xFFC7B6FF).withValues(alpha: .24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90);
    canvas.drawOval(
        Rect.fromLTWH(-90, size.height * .58, size.width * .92, 260),
        lowerWash);
  }

  @override
  bool shouldRepaint(covariant _PurpleAtmospherePainter oldDelegate) {
    return oldDelegate.palette != palette;
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .82),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          width: 44,
          child: Icon(icon, color: AppColors.ink, size: 22),
        ),
      ),
    );
  }
}
