import 'package:flutter/material.dart';

import '../services/app_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/route_names.dart';
import '../widgets/app_header.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/mathiva_bottom_nav.dart';
import '../widgets/section_card.dart';

class ImageSolverScreen extends StatefulWidget {
  const ImageSolverScreen({super.key});

  @override
  State<ImageSolverScreen> createState() => _ImageSolverScreenState();
}

class _ImageSolverScreenState extends State<ImageSolverScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      body: GradientBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(
              title: 'Image Solver',
              subtitle:
                  'Take or upload a math problem and preview the solution',
            ),

            const SizedBox(height: 18),

            SectionCard(
              child: Column(
                children: [
                  _ScannerPreview(animation: _scanController),

                  const SizedBox(height: 16),

                  GradientButton(
                    label: 'Take / Upload Image',
                    icon: Icons.camera_alt_rounded,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Camera or gallery picker is ready for integration.',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Recognized Problem',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Edit'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppPreferences.palette.value.secondary
                              .withOpacity(.12),
                          AppPreferences.palette.value.background.last,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white),
                    ),
                    child: const Text(
                      'Solve for x: 2x² + 5x + 3 = 0',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            GradientButton(
              label: 'Solve This Problem',
              onPressed: () =>
                  Navigator.pushNamed(context, RouteNames.solution),
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),

      bottomNavigationBar: const MathivaBottomNav(
        selected: MathivaTab.scan,
      ),
    );
  }
}

class _ScannerPreview extends StatelessWidget {
  final Animation<double> animation;

  const _ScannerPreview({
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppPreferences.palette.value.background,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            const Positioned(
              top: 24,
              left: 24,
              child: _Corner(alignment: Alignment.topLeft),
            ),

            const Positioned(
              top: 24,
              right: 24,
              child: _Corner(alignment: Alignment.topRight),
            ),

            const Positioned(
              bottom: 24,
              left: 24,
              child: _Corner(alignment: Alignment.bottomLeft),
            ),

            const Positioned(
              bottom: 24,
              right: 24,
              child: _Corner(alignment: Alignment.bottomRight),
            ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_rounded,
                    size: 44,
                    color: AppPreferences.palette.value.primary,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Upload a clear image of your problem',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'JPG, PNG, WEBP',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                return Positioned(
                  left: 28,
                  right: 28,
                  top: 36 + (animation.value * 116),
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: LinearGradient(
                        colors: [
                          AppPreferences.palette.value.primary
                              .withOpacity(0),
                          AppPreferences.palette.value.primary,
                          AppPreferences.palette.value.primary
                              .withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final Alignment alignment;

  const _Corner({
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final bool left =
        alignment == Alignment.topLeft ||
        alignment == Alignment.bottomLeft;

    final bool top =
        alignment == Alignment.topLeft ||
        alignment == Alignment.topRight;

    return SizedBox(
      width: 28,
      height: 28,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: top
                ? BorderSide(
                    color: AppPreferences.palette.value.primary,
                    width: 3,
                  )
                : BorderSide.none,
            bottom: top
                ? BorderSide.none
                : BorderSide(
                    color: AppPreferences.palette.value.primary,
                    width: 3,
                  ),
            left: left
                ? BorderSide(
                    color: AppPreferences.palette.value.primary,
                    width: 3,
                  )
                : BorderSide.none,
            right: left
                ? BorderSide.none
                : BorderSide(
                    color: AppPreferences.palette.value.primary,
                    width: 3,
                  ),
          ),
        ),
      ),
    );
  }
}