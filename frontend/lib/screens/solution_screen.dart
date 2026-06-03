import 'package:flutter/material.dart';
import '../services/app_preferences.dart';

import '../data/local_mathiva_data.dart';
import '../theme/app_theme.dart';
import '../utils/route_names.dart';
import '../widgets/app_header.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/section_card.dart';

class SolutionScreen extends StatelessWidget {
  const SolutionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const problem = LocalMathivaData.quadraticProblem;
    return Scaffold(
      body: GradientBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(title: 'Solution', subtitle: 'Step-by-step answer'),
            const SizedBox(height: 18),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recognized Problem',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Solve for x: 2x^2 + 5x + 3 = 0',
                    style: TextStyle(
                      color: AppPreferences.palette.value.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Topic: Quadratic Equations',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This problem is in standard quadratic form ax^2 + bx + c = 0.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Step-by-Step Solution',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  ...problem.steps.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: AppPreferences.palette.value.primary.withOpacity( .12),
                            child: Text(
                              '${entry.key + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppPreferences.palette.value.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Final Answer',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    problem.answer,
                    style: TextStyle(
                      color: AppPreferences.palette.value.secondary,
                      fontWeight: FontWeight.w900,
                      fontSize: 19,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: 'Practice This Formula Now',
              onPressed: () => Navigator.pushNamed(
                context,
                RouteNames.practice,
                arguments: {
                  'subjectId': 'general_math',
                  'topicId': 'quadratic_equations',
                  'lessonId': 'quadratic_intro',
                  'conceptId': 'quadratic_form',
                  'difficulty': 'Easy',
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
