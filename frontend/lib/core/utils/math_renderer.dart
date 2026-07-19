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
    // Render as a single flowing paragraph (Text.rich) rather than a Wrap of
    // separate widgets: plain text wraps and keeps its line breaks normally
    // (left-aligned), and each inline equation is a baseline-aligned WidgetSpan
    // so it sits on the line with the text instead of floating vertically
    // centered. The old Wrap(center) made mixed text+math look ragged.
    return Text.rich(
      TextSpan(
        style: textStyle,
        children: parts.map<InlineSpan>((part) {
          if (part.isMath) {
            return WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              baseline: TextBaseline.alphabetic,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: MathDisplay(
                  latex: part.value,
                  fontSize: mathFontSize,
                  color: textStyle?.color,
                ),
              ),
            );
          }
          return TextSpan(text: part.value);
        }).toList(),
      ),
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
