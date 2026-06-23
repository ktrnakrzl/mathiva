import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class MathRenderer extends StatelessWidget {
  final String latex;
  final double fontSize;
  final Color color;
  final TextAlign textAlign;

  const MathRenderer({
    Key? key,
    required this.latex,
    this.fontSize = 16.0,
    this.color = const Color(0xFF1F2937),
    this.textAlign = TextAlign.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Math.tex(
      latex,
      textStyle: TextStyle(
        fontSize: fontSize,
        color: color,
      ),
      mathStyle: MathStyle.display,
      onErrorFallback: (dynamic error) {
        return Text(
          latex,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.red,
            fontFamily: 'monospace',
          ),
        );
      },
    );
  }
}

class InlineMath extends StatelessWidget {
  final String latex;
  final double fontSize;
  final Color color;

  const InlineMath({
    Key? key,
    required this.latex,
    this.fontSize = 14.0,
    this.color = const Color(0xFF1F2937),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Math.tex(
      latex,
      textStyle: TextStyle(
        fontSize: fontSize,
        color: color,
      ),
      mathStyle: MathStyle.text,
      onErrorFallback: (dynamic error) {
        return Text(
          latex,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.red,
            fontFamily: 'monospace',
          ),
        );
      },
    );
  }
}
