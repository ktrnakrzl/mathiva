import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// Hand-built "mathematical notebook / blueprint" art used only by the pre-auth
/// flow (onboarding, login, sign-up): a faint graph-paper background, three
/// custom vector math diagrams, and the decorative plotted curve on the
/// login/sign-up brand band. All drawn natively (CustomPainter) rather than with
/// stock illustrations or emoji, per the design handoff.

// ─── Graph paper ─────────────────────────────────────────────────────────────

/// A very faint two-line grid (one line every [pitch] px) used behind hero
/// panels and the auth brand band. Colour is a barely-there version of the
/// border token so it reads as notebook paper, not a table.
class GraphPaperPainter extends CustomPainter {
  final Color line;
  final double pitch;

  const GraphPaperPainter({required this.line, this.pitch = 21});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = line
      ..strokeWidth = 1
      ..isAntiAlias = false;

    for (double x = 0; x <= size.width; x += pitch) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += pitch) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GraphPaperPainter old) =>
      old.line != line || old.pitch != pitch;
}

/// The grid colour for the current brightness (`#E9E9EC` light /
/// `rgba(255,255,255,0.06)` dark, per the handoff).
Color graphPaperColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.06)
        : const Color(0xFFE9E9EC);

// ─── Small caps figure caption ("fig. 1") ────────────────────────────────────

class FigCaption extends StatelessWidget {
  final String text;
  const FigCaption(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Text(
      text,
      style: GoogleFonts.fraunces(
        color: colors.subtleMuted,
        fontSize: 12,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ─── Onboarding diagrams ─────────────────────────────────────────────────────
//
// Each diagram is authored against a fixed 230×200 "viewBox" and scaled to the
// available box, so the composition holds at any panel size. Structural lines
// use the ink/muted tokens; curves and highlights use the app accent.

/// Slide 1 — a coordinate plane with an upward parabola (y = x²), plotted
/// points, and small "scan bracket" corners framing the vertex.
class ParabolaDiagram extends StatelessWidget {
  const ParabolaDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return _DiagramBox(
      painter: _ParabolaPainter(accent: colors.accent, structure: colors.muted),
      labels: [
        _DiagramLabel(
          x: 0.52,
          y: 0.06,
          child: _EqLabel('y = x²', color: colors.ink),
        ),
      ],
    );
  }
}

class _ParabolaPainter extends CustomPainter {
  final Color accent;
  final Color structure;
  const _ParabolaPainter({required this.accent, required this.structure});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 230, sy = size.height / 200;
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    final axis = Paint()
      ..color = structure
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Axes.
    canvas.drawLine(p(28, 150), p(206, 150), axis); // x
    canvas.drawLine(p(40, 176), p(40, 26), axis); // y
    // Arrowheads.
    _arrow(canvas, p(206, 150), const Offset(1, 0), structure);
    _arrow(canvas, p(40, 26), const Offset(0, -1), structure);

    // Parabola y = x² (opening up), via a quadratic bezier.
    final curve = Paint()
      ..color = accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(p(60, 46).dx, p(60, 46).dy)
      ..quadraticBezierTo(
          p(115, 214).dx, p(115, 214).dy, p(170, 46).dx, p(170, 46).dy);
    canvas.drawPath(path, curve);

    // Plotted points on the curve.
    final dot = Paint()..color = accent;
    for (final o in [p(82, 100), p(115, 130), p(148, 100)]) {
      canvas.drawCircle(o, 4, dot);
    }

    // Scan-bracket corners framing the vertex.
    final bracket = Paint()
      ..color = accent
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    _bracket(canvas, p(84, 118), -1, 1, bracket); // top-left
    _bracket(canvas, p(146, 118), 1, 1, bracket); // top-right
  }

  void _bracket(Canvas c, Offset o, double dx, double dy, Paint paint) {
    const len = 11.0;
    c.drawLine(o, o + Offset(dx * len, 0), paint);
    c.drawLine(o, o + Offset(0, dy * len), paint);
  }

  @override
  bool shouldRepaint(_ParabolaPainter o) =>
      o.accent != accent || o.structure != structure;
}

/// Slide 2 — a Pythagorean right triangle (a² + b² = c²).
class TriangleDiagram extends StatelessWidget {
  const TriangleDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return _DiagramBox(
      painter: _TrianglePainter(
        accent: colors.accent,
        structure: colors.ink,
        fill: colors.accent.withOpacity(0.08),
      ),
      labels: [
        _DiagramLabel(
          x: 0.5,
          y: 0.02,
          child: _EqLabel('a² + b² = c²', color: colors.muted, size: 15),
        ),
        _DiagramLabel(
            x: 0.1, y: 0.45, child: _EqLabel('a', color: colors.ink)),
        _DiagramLabel(
            x: 0.46, y: 0.82, child: _EqLabel('b', color: colors.ink)),
        _DiagramLabel(
            x: 0.62, y: 0.4, child: _EqLabel('c', color: colors.accent)),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color accent;
  final Color structure;
  final Color fill;
  const _TrianglePainter(
      {required this.accent, required this.structure, required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 230, sy = size.height / 200;
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    final right = p(58, 150); // right-angle vertex (bottom-left)
    final bottom = p(178, 150); // bottom-right
    final top = p(58, 58); // top

    // Faint accent fill.
    final tri = Path()
      ..moveTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(top.dx, top.dy)
      ..close();
    canvas.drawPath(tri, Paint()..color = fill);

    // Legs (solid, structural).
    final leg = Paint()
      ..color = structure
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(right, top, leg); // a
    canvas.drawLine(right, bottom, leg); // b

    // Hypotenuse (accent).
    final hyp = Paint()
      ..color = accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(bottom, top, hyp); // c

    // Right-angle mark at the right vertex.
    final mark = Paint()
      ..color = structure
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    const m = 14.0;
    canvas.drawRect(
        Rect.fromLTWH(right.dx, right.dy - m, m, m), mark);

    // Angle arc at the far (bottom-right) vertex.
    canvas.drawArc(
      Rect.fromCircle(center: bottom, radius: 22),
      3.6, // start angle (pointing up-left)
      0.7,
      false,
      mark,
    );

    // Tick marks on the two legs.
    final tick = Paint()
      ..color = structure
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    // vertical leg tick
    final vMid = Offset(right.dx, (right.dy + top.dy) / 2);
    canvas.drawLine(vMid + const Offset(-4, 0), vMid + const Offset(4, 0), tick);
    // horizontal leg tick
    final hMid = Offset((right.dx + bottom.dx) / 2, right.dy);
    canvas.drawLine(hMid + const Offset(0, -4), hMid + const Offset(0, 4), tick);
  }

  @override
  bool shouldRepaint(_TrianglePainter o) =>
      o.accent != accent || o.structure != structure || o.fill != fill;
}

/// Slide 3 — an ascending growth curve with a soft gradient fill and a star
/// marking the peak.
class GrowthDiagram extends StatelessWidget {
  const GrowthDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return _DiagramBox(
      painter: _GrowthPainter(accent: colors.accent, structure: colors.muted),
    );
  }
}

class _GrowthPainter extends CustomPainter {
  final Color accent;
  final Color structure;
  const _GrowthPainter({required this.accent, required this.structure});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 230, sy = size.height / 200;
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    // Baseline.
    final axis = Paint()
      ..color = structure
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p(30, 160), p(206, 160), axis);
    canvas.drawLine(p(38, 168), p(38, 30), axis);
    _arrow(canvas, p(206, 160), const Offset(1, 0), structure);
    _arrow(canvas, p(38, 30), const Offset(0, -1), structure);

    // Ascending curve.
    final curvePath = Path()
      ..moveTo(p(48, 150).dx, p(48, 150).dy)
      ..cubicTo(p(95, 150).dx, p(95, 150).dy, p(120, 90).dx, p(120, 90).dy,
          p(185, 46).dx, p(185, 46).dy);

    // Gradient fill under the curve.
    final fillPath = Path.from(curvePath)
      ..lineTo(p(185, 160).dx, p(185, 160).dy)
      ..lineTo(p(48, 160).dx, p(48, 160).dy)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accent.withOpacity(0.28), accent.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final curve = Paint()
      ..color = accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(curvePath, curve);

    // Plotted dots.
    final dot = Paint()..color = accent;
    for (final o in [p(78, 141), p(120, 90), p(160, 62)]) {
      canvas.drawCircle(o, 4, dot);
    }

    // Star at the peak.
    _star(canvas, p(185, 46), 9, accent);
  }

  @override
  bool shouldRepaint(_GrowthPainter o) =>
      o.accent != accent || o.structure != structure;
}

// ─── Brand band plotted curve (login / sign-up header) ───────────────────────

/// A thin decorative "plotted" curve drawn across the auth brand band, with two
/// accent dots marking points on the line.
class BrandBandCurvePainter extends CustomPainter {
  final Color accent;
  const BrandBandCurvePainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(0, h * 0.72)
      ..cubicTo(w * 0.25, h * 0.5, w * 0.4, h * 0.9, w * 0.6, h * 0.55)
      ..cubicTo(w * 0.78, h * 0.28, w * 0.9, h * 0.42, w, h * 0.2);
    canvas.drawPath(
      path,
      Paint()
        ..color = accent.withOpacity(0.55)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    final dot = Paint()..color = accent;
    canvas.drawCircle(Offset(w * 0.6, h * 0.55), 3.5, dot);
    canvas.drawCircle(Offset(w * 0.9, h * 0.29), 3.5, dot);
  }

  @override
  bool shouldRepaint(BrandBandCurvePainter o) => o.accent != accent;
}

// ─── Shared helpers ──────────────────────────────────────────────────────────

/// A diagram: the vector [painter] filling a 230×200 aspect box, with optional
/// serif equation [labels] positioned over it (fractional coordinates).
class _DiagramBox extends StatelessWidget {
  final CustomPainter painter;
  final List<_DiagramLabel> labels;
  const _DiagramBox({required this.painter, this.labels = const []});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 230 / 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: painter),
          for (final l in labels)
            Align(
              alignment: Alignment(l.x * 2 - 1, l.y * 2 - 1),
              child: l.child,
            ),
        ],
      ),
    );
  }
}

class _DiagramLabel {
  final double x; // 0..1 across the box
  final double y; // 0..1 down the box
  final Widget child;
  const _DiagramLabel({required this.x, required this.y, required this.child});
}

/// An italic serif equation label used inside the diagrams.
class _EqLabel extends StatelessWidget {
  final String text;
  final Color color;
  final double size;
  const _EqLabel(this.text, {required this.color, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.fraunces(
        color: color,
        fontSize: size,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

void _arrow(Canvas c, Offset tip, Offset dir, Color color) {
  final paint = Paint()
    ..color = color
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round;
  // Perpendicular for the two barbs.
  final perp = Offset(-dir.dy, dir.dx);
  const len = 7.0;
  final base = tip - dir * len;
  c.drawLine(tip, base + perp * (len * 0.6), paint);
  c.drawLine(tip, base - perp * (len * 0.6), paint);
}

void _star(Canvas c, Offset center, double r, Color color) {
  final path = Path();
  const points = 5;
  for (int i = 0; i < points * 2; i++) {
    final radius = i.isEven ? r : r * 0.44;
    final angle = -math.pi / 2 + i * math.pi / points;
    final o = center + Offset(radius * math.cos(angle), radius * math.sin(angle));
    if (i == 0) {
      path.moveTo(o.dx, o.dy);
    } else {
      path.lineTo(o.dx, o.dy);
    }
  }
  path.close();
  c.drawPath(path, Paint()..color = color);
}
