import 'package:flutter/material.dart';

class PointsBar extends StatelessWidget {
  final int points;
  final int streakDays;
  const PointsBar({super.key, required this.points, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Points: $points',
                style: Theme.of(context).textTheme.titleMedium),
            Text('Streak: $streakDays days',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
