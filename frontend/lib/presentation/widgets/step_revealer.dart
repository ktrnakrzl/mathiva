import 'package:flutter/material.dart';
import 'package:mathiva/core/utils/math_renderer.dart';

class StepRevealer extends StatefulWidget {
  final List<String> steps;
  const StepRevealer({super.key, required this.steps});

  @override
  State<StepRevealer> createState() => _StepRevealerState();
}

class _StepRevealerState extends State<StepRevealer> {
  int _visibleCount = 1;

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...widget.steps.take(_visibleCount).toList().asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Step ${entry.key + 1}: ',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: MathRenderer(text: entry.value)),
                  ],
                ),
              ),
            ),
        if (_visibleCount < widget.steps.length)
          TextButton(
            onPressed: () => setState(() => _visibleCount++),
            child: const Text('Show next step'),
          ),
      ],
    );
  }
}
