import 'package:flutter/material.dart';
import 'package:mathiva/presentation/widgets/math_display.dart';

class MathRenderer extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final double mathFontSize;

  const MathRenderer(
      {super.key, required this.text, this.textStyle, this.mathFontSize = 16});

  @override
  Widget build(BuildContext context) {
    final parts = _splitMixedMath(text);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: parts.map((part) {
        if (part.isMath) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: MathDisplay(latex: part.value, fontSize: mathFontSize),
          );
        }
        return Text(part.value, style: textStyle);
      }).toList(),
    );
  }

  List<_MathPart> _splitMixedMath(String value) {
    final regex = RegExp(r'(\\\((.*?)\\\)|\$\$(.*?)\$\$)');
    final parts = <_MathPart>[];
    var cursor = 0;
    for (final match in regex.allMatches(value)) {
      if (match.start > cursor) {
        parts.add(_MathPart(value.substring(cursor, match.start), false));
      }
      parts.add(_MathPart(match.group(2) ?? match.group(3) ?? '', true));
      cursor = match.end;
    }
    if (cursor < value.length) {
      parts.add(_MathPart(value.substring(cursor), false));
    }
    return parts;
  }
}

class _MathPart {
  final String value;
  final bool isMath;
  const _MathPart(this.value, this.isMath);
}
