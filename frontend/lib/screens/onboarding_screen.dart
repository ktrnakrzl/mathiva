import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/route_names.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final compactHeight = screenHeight < 720;
    final logoStageHeight = compactHeight ? 142.0 : 164.0;
    final logoSize = compactHeight ? 146.0 : 182.0;
    final cubeSize = compactHeight ? 218.0 : 246.0;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8F6FF),
                  Color(0xFFEFE8FF),
                  Color(0xFFFBFAFF),
                ],
              ),
            ),
          ),

          // Large top-right glow
          Positioned(
            top: -120,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 100,
                sigmaY: 100,
              ),
              child: Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ),
          ),

          // Bottom-left glow
          Positioned(
            bottom: -120,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 90,
                sigmaY: 90,
              ),
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFC084FC),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30, 24, 30, 28),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          RouteNames.login,
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.65),
                          foregroundColor: AppColors.purple,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: compactHeight ? 16 : 22),

                    // Hero Image with Glow
                    SizedBox(
                      height: logoStageHeight,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: 60,
                              sigmaY: 60,
                            ),
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          ),
                          Image.asset(
                            'assets/mathiva_logo.png',
                            height: logoSize,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'mathiva',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF15112A),
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Image.asset(
                      'assets/math_cube.png',
                      height: cubeSize,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),

                    const SizedBox(height: 18),

                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Color(0xFF15112A),
                          fontSize: 28,
                          height: 1.12,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(text: 'Learn Math '),
                          TextSpan(
                            text: 'Smarter',
                            style: TextStyle(
                              color: AppColors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Scan. Solve. Master.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF81799E),
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _IndicatorDot(active: true),
                        _IndicatorDot(active: false),
                        _IndicatorDot(active: false),
                      ],
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          RouteNames.login,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 6,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get Started',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 12),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Join thousands of learners improving\n'
                      'their math skills every day.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF81799E),
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicatorDot extends StatelessWidget {
  final bool active;

  const _IndicatorDot({
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            active ? AppColors.purple : AppColors.purple.withValues(alpha: 0.2),
      ),
    );
  }
}
