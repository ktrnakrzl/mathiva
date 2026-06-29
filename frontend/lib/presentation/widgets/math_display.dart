import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class MathDisplay extends StatelessWidget {
  final String latex;
  final double fontSize;
  final Color? color;

  const MathDisplay({
    super.key,
    required this.latex,
    this.fontSize = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Math.tex(
      latex,
      textStyle: TextStyle(fontSize: fontSize, color: color),
      onErrorFallback: (error) => Text(latex, style: TextStyle(color: color)),
    );
  }
}
