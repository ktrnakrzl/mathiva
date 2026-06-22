import 'package:flutter/material.dart';

class DifficultyBadge extends StatelessWidget {
  final String difficulty;
  const DifficultyBadge({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(difficulty), visualDensity: VisualDensity.compact);
  }
}
