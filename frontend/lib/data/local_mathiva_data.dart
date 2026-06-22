import 'package:flutter/material.dart';
import '../models/mathiva_models.dart';

class LocalMathivaData {
  static const PracticeProblem quadraticProblem = PracticeProblem(
    question: 'Solve for x: 2x^2 + 5x + 3 = 0',
    answer: 'x = -1 and x = -3/2',
    steps: [
      'Identify the coefficients: a = 2, b = 5, c = 3.',
      'Factor the expression: 2x^2 + 5x + 3 = (2x + 3)(x + 1).',
      'Set each factor equal to zero: 2x + 3 = 0 or x + 1 = 0.',
      'Solve each equation to get x = -3/2 and x = -1.',
    ],
  );

  static const List<MathSubject> subjects = [
    MathSubject(
      id: 'general_math',
      title: 'General Mathematics',
      gradeLevel: 'Grade 11',
      iconText: 'GM',
      subjectIcon: Icons.calculate_rounded,
      progress: 57,
      topics: [
        MathTopic(
          id: 'functions',
          title: 'Functions',
          progress: 64,
          lessons: [
            MathLesson(
              id: 'functions_intro',
              title: 'Introduction to Functions',
              duration: '8 min',
              locked: false,
              concepts: [
                Concept(
                  id: 'function_definition',
                  title: 'What is a Function?',
                  definition: 'A function is a relation where each input has exactly one output.',
                  formula: 'f(x) = y',
                  example: 'If f(x) = 2x + 1, then f(3) = 7.',
                  problem: PracticeProblem(
                    question: 'If f(x) = 2x + 1, find f(4).',
                    answer: 'f(4) = 9',
                    steps: ['Substitute x = 4.', 'Compute 2(4) + 1.', 'The value is 9.'],
                  ),
                ),
              ],
            ),
          ],
        ),
        MathTopic(
          id: 'quadratic_equations',
          title: 'Quadratic Equations',
          progress: 57,
          lessons: [
            MathLesson(
              id: 'quadratic_intro',
              title: 'Introduction to Quadratic Equations',
              duration: '8 min',
              locked: false,
              concepts: [
                Concept(
                  id: 'quadratic_form',
                  title: 'What is a Quadratic Equation?',
                  definition: 'A quadratic equation is a polynomial equation of degree two.',
                  formula: 'ax^2 + bx + c = 0, where a is not equal to 0',
                  example: '2x^2 + 5x + 3 = 0 has a = 2, b = 5, and c = 3.',
                  problem: quadraticProblem,
                ),
                Concept(
                  id: 'factoring',
                  title: 'Solving by Factoring',
                  definition: 'Factoring rewrites a quadratic expression as a product of simpler expressions.',
                  formula: '(px + q)(rx + s) = 0',
                  example: '(x + 2)(x + 3) = 0 gives x = -2 or x = -3.',
                  problem: quadraticProblem,
                ),
              ],
            ),
            MathLesson(
              id: 'rational_expressions',
              title: 'Rational Algebraic Expressions',
              duration: '10 min',
              locked: false,
              concepts: [
                Concept(
                  id: 'simplify_rational',
                  title: 'Simplifying Rational Expressions',
                  definition: 'A rational expression is a ratio of two polynomials.',
                  formula: '(x^2 - 1)/(x - 1) = x + 1, x != 1',
                  example: 'Cancel common factors after factoring first.',
                  problem: PracticeProblem(
                    question: 'Simplify (x^2 - 1)/(x - 1).',
                    answer: 'x + 1',
                    steps: ['Factor x^2 - 1 as (x - 1)(x + 1).', 'Cancel x - 1.', 'The simplified form is x + 1.'],
                  ),
                ),
              ],
            ),
          ],
        ),
        MathTopic(
          id: 'polynomials',
          title: 'Polynomials',
          progress: 56,
          lessons: [
            MathLesson(
              id: 'polynomial_basics',
              title: 'Polynomial Basics',
              duration: '7 min',
              locked: false,
              concepts: [
                Concept(
                  id: 'degree_terms',
                  title: 'Degree and Terms',
                  definition: 'The degree of a polynomial is the highest exponent of its variable.',
                  formula: 'P(x) = a_nx^n + ... + a_1x + a_0',
                  example: '3x^4 + 2x - 1 has degree 4.',
                  problem: PracticeProblem(
                    question: 'What is the degree of 5x^3 + 2x^2 - 7?',
                    answer: '3',
                    steps: ['Find the highest exponent.', 'The highest exponent is 3.', 'The degree is 3.'],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    MathSubject(
      id: 'statistics_probability',
      title: 'Statistics and Probability',
      gradeLevel: 'Grade 11',
      iconText: 'SP',
      subjectIcon: Icons.bar_chart_rounded,
      progress: 42,
      topics: [
        MathTopic(
          id: 'measures_center',
          title: 'Mean, Median, and Mode',
          progress: 70,
          lessons: [
            MathLesson(
              id: 'mean_intro',
              title: 'Measures of Central Tendency',
              duration: '9 min',
              locked: false,
              concepts: [
                Concept(
                  id: 'mean',
                  title: 'Mean',
                  definition: 'The mean is the sum of values divided by the number of values.',
                  formula: 'mean = sum of values / number of values',
                  example: 'For 2, 4, and 6, the mean is 4.',
                  problem: PracticeProblem(
                    question: 'Find the mean of 3, 5, 7, 9.',
                    answer: '6',
                    steps: ['Add the values: 3 + 5 + 7 + 9 = 24.', 'Divide by 4.', 'The mean is 6.'],
                  ),
                ),
              ],
            ),
          ],
        ),
        MathTopic(
          id: 'probability_basics',
          title: 'Basic Probability',
          progress: 35,
          lessons: [
            MathLesson(
              id: 'prob_intro',
              title: 'Introduction to Probability',
              duration: '8 min',
              locked: false,
              concepts: [
                Concept(
                  id: 'probability_formula',
                  title: 'Probability Formula',
                  definition: 'Probability measures how likely an event is to happen.',
                  formula: 'P(event) = favorable outcomes / total outcomes',
                  example: 'Rolling a 6 on a die has probability 1/6.',
                  problem: PracticeProblem(
                    question: 'What is the probability of getting heads when tossing one coin?',
                    answer: '1/2',
                    steps: ['There is 1 favorable outcome: heads.', 'There are 2 total outcomes.', 'The probability is 1/2.'],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    MathSubject(
      id: 'pre_calculus',
      title: 'Pre-Calculus',
      gradeLevel: 'Grade 12',
      iconText: 'PC',
      subjectIcon: Icons.show_chart_rounded,
      progress: 38,
      topics: [
        MathTopic(
          id: 'trigonometry',
          title: 'Trigonometry',
          progress: 45,
          lessons: [
            MathLesson(
              id: 'trig_ratios',
              title: 'Trigonometric Ratios',
              duration: '10 min',
              locked: false,
              concepts: [
                Concept(
                  id: 'sine_cosine',
                  title: 'Sine, Cosine, and Tangent',
                  definition: 'Trigonometric ratios compare sides of a right triangle.',
                  formula: 'sin theta = opposite / hypotenuse',
                  example: 'If opposite = 3 and hypotenuse = 5, sin theta = 3/5.',
                  problem: PracticeProblem(
                    question: 'Find sin theta if opposite = 6 and hypotenuse = 10.',
                    answer: '3/5',
                    steps: ['Use sin theta = opposite / hypotenuse.', 'Substitute 6/10.', 'Simplify to 3/5.'],
                  ),
                ),
              ],
            ),
          ],
        ),
        MathTopic(
          id: 'conic_sections',
          title: 'Conic Sections',
          progress: 28,
          lessons: [
            MathLesson(
              id: 'circle_equation',
              title: 'Equation of a Circle',
              duration: '9 min',
              locked: false,
              concepts: [
                Concept(
                  id: 'circle_standard',
                  title: 'Standard Form of a Circle',
                  definition: 'A circle is the set of points with the same distance from its center.',
                  formula: '(x - h)^2 + (y - k)^2 = r^2',
                  example: '(x - 2)^2 + (y + 1)^2 = 9 has center (2, -1) and radius 3.',
                  problem: PracticeProblem(
                    question: 'Find the radius of (x - 1)^2 + (y - 2)^2 = 16.',
                    answer: '4',
                    steps: ['Compare with standard form.', 'r^2 = 16.', 'r = 4.'],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    MathSubject(
      id: 'basic_calculus',
      title: 'Basic Calculus',
      gradeLevel: 'Grade 12',
      iconText: 'BC',
      subjectIcon: Icons.functions_rounded,
      progress: 31,
      topics: [
        MathTopic(
          id: 'limits',
          title: 'Limits',
          progress: 50,
          lessons: [
            MathLesson(
              id: 'limits_intro',
              title: 'Introduction to Limits',
              duration: '10 min',
              locked: false,
              concepts: [
                Concept(
                  id: 'limit_meaning',
                  title: 'Meaning of a Limit',
                  definition: 'A limit describes the value a function approaches as x gets close to a number.',
                  formula: 'lim x->a f(x) = L',
                  example: 'As x approaches 2, f(x) = x + 1 approaches 3.',
                  problem: PracticeProblem(
                    question: 'Evaluate lim x->2 (x + 1).',
                    answer: '3',
                    steps: ['Substitute x = 2.', 'Compute 2 + 1.', 'The limit is 3.'],
                  ),
                ),
              ],
            ),
          ],
        ),
        MathTopic(
          id: 'derivatives',
          title: 'Derivatives',
          progress: 22,
          lessons: [
            MathLesson(
              id: 'power_rule',
              title: 'Power Rule',
              duration: '8 min',
              locked: false,
              concepts: [
                Concept(
                  id: 'basic_power_rule',
                  title: 'Using the Power Rule',
                  definition: 'The power rule is used to find derivatives of power functions.',
                  formula: 'd/dx x^n = nx^(n-1)',
                  example: 'The derivative of x^3 is 3x^2.',
                  problem: PracticeProblem(
                    question: 'Find the derivative of x^4.',
                    answer: '4x^3',
                    steps: ['Use d/dx x^n = nx^(n-1).', 'Let n = 4.', 'The derivative is 4x^3.'],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ];
}
