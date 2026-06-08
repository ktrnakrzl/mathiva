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
    final logoStageHeight = compactHeight ? 96.0 : 120.0;
    final logoSize = compactHeight ? 146.0 : 182.0;
    final cubeSize = compactHeight ? 180.0 : 200.0;

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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 24, 30, 28),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxHeight = constraints.maxHeight;
                  final compactHeight = maxHeight < 720;
                  final logoStageHeight = (maxHeight * (compactHeight ? 0.18 : 0.22)).clamp(120.0, 170.0);
                  final logoSize = (maxHeight * (compactHeight ? 0.14 : 0.18)).clamp(96.0, 160.0);
                  final cubeSize = (maxHeight * (compactHeight ? 0.18 : 0.22)).clamp(150.0, 220.0);
                  final spacingXs = compactHeight ? 10.0 : 14.0;
                  final spacingSm = compactHeight ? 14.0 : 18.0;
                  final spacingMd = compactHeight ? 18.0 : 24.0;
                  final titleFontSize = compactHeight ? 38.0 : 48.0;
                  final subtitleFontSize = compactHeight ? 20.0 : 28.0;
                  final bodyFontSize = compactHeight ? 14.0 : 16.0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                              horizontal: 18,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: spacingSm),

                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
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

                            SizedBox(height: spacingXs),

                            Text(
                              'mathiva',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: const Color(0xFF15112A),
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            SizedBox(height: spacingXs),

                            SizedBox(
                              height: cubeSize,
                              child: Image.asset(
                                'assets/math_cube.png',
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),

                            SizedBox(height: spacingMd),

                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: const Color(0xFF15112A),
                                  fontSize: subtitleFontSize,
                                  height: 1.12,
                                  fontWeight: FontWeight.w600,
                                ),
                                children: const [
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

                            SizedBox(height: spacingXs),

                            Text(
                              'Scan. Solve. Master.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: const Color(0xFF81799E),
                                fontSize: bodyFontSize + 2,
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            const Spacer(),

                            SizedBox(
                              width: double.infinity,
                              height: 54,
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
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Get Started',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: spacingSm),

                            Text(
                              'Join thousands of learners improving\n'
                              'their math skills every day.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: const Color(0xFF81799E),
                                fontSize: bodyFontSize,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
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
