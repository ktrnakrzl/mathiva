import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Premium animated background with subtle floating math symbols and particles.
/// Opacity: 2-6%, very slow movement, soft blur - nearly invisible but alive.
class AnimatedMathBackground extends StatefulWidget {
  final Widget child;

  const AnimatedMathBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AnimatedMathBackground> createState() => _AnimatedMathBackgroundState();
}

class _AnimatedMathBackgroundState extends State<AnimatedMathBackground>
    with TickerProviderStateMixin {
  late final AnimationController _controller1;
  late final AnimationController _controller2;

  @override
  void initState() {
    super.initState();
    // 15 second loop for subtle, slow animation
    _controller1 = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _controller2 = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // White background
        Container(
          color: Colors.white,
        ),

        // Subtle animated particles
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller1,
            builder: (context, child) {
              return CustomPaint(
                painter: _MathBackgroundPainter(
                  animation1: _controller1.value,
                  animation2: _controller2.value,
                ),
              );
            },
          ),
        ),

        // Content
        widget.child,
      ],
    );
  }
}

class _MathBackgroundPainter extends CustomPainter {
  final double animation1;
  final double animation2;

  _MathBackgroundPainter({
    required this.animation1,
    required this.animation2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // Consistent seed

    // Draw subtle floating symbols
    for (int i = 0; i < 5; i++) {
      final x = (size.width * (0.1 + i * 0.2)) +
          math.sin((animation1 + i) * 2 * math.pi) * 15;
      final y = (size.height * (0.2 + random.nextDouble() * 0.6)) +
          math.cos((animation2 + i) * 2 * math.pi) * 15;

      // Draw soft circles (representing particles/symbols)
      canvas.drawCircle(
        Offset(x, y),
        3 + random.nextDouble() * 2,
        paint,
      );
    }

    // Additional soft blurred effect
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withValues(alpha: 0.01),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.01),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      gradientPaint,
    );
  }

  @override
  bool shouldRepaint(_MathBackgroundPainter oldDelegate) {
    return oldDelegate.animation1 != animation1 ||
        oldDelegate.animation2 != animation2;
  }
}
