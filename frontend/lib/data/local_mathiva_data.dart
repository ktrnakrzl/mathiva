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

  static Concept _concept(
    String id,
    String title,
    String definition,
    String formula,
    String example,
    String question,
    String answer,
    List<String> steps,
  ) =>
      Concept(
        id: id,
        title: title,
        definition: definition,
        formula: formula,
        example: example,
        problem: PracticeProblem(
          question: question,
          answer: answer,
          steps: steps,
        ),
      );

  static MathLesson _lesson(
    String id,
    String title,
    String duration,
    List<Concept> concepts,
  ) =>
      MathLesson(
        id: id,
        title: title,
        duration: duration,
        locked: false,
        concepts: concepts,
      );

  static MathTopic _topic(
    String id,
    String title,
    int progress,
    List<MathLesson> lessons,
  ) =>
      MathTopic(id: id, title: title, progress: progress, lessons: lessons);

  static final List<MathSubject> subjects = [
    MathSubject(
      id: 'general_math',
      title: 'General Mathematics',
      gradeLevel: 'Grade 11',
      iconText: 'GM',
      subjectIcon: Icons.calculate_rounded,
      progress: 57,
      topics: [
        _topic('functions', 'Functions', 64, [
          _lesson('functions_intro', 'Relations and Functions', '10 min', [
            _concept(
              'relations',
              'Relations',
              'A relation is any pairing between elements of two sets.',
              'Relation: subset of A x B',
              'The pairs (1, 2), (2, 4), and (3, 6) form a relation.',
              'Is {(1, 2), (2, 4), (3, 6)} a relation?',
              'Yes',
              [
                'A relation is any set of ordered pairs.',
                'The given set contains ordered pairs.',
                'Therefore, it is a relation.',
              ],
            ),
            _concept(
              'function_definition',
              'What is a Function?',
              'A function is a relation where each input has exactly one output.',
              'f(x) = y',
              'If f(x) = 2x + 1, then f(3) = 7.',
              'If f(x) = 2x + 1, find f(4).',
              'f(4) = 9',
              [
                'Substitute x = 4.',
                'Compute 2(4) + 1.',
                'The value is 9.',
              ],
            ),
            _concept(
              'function_notation',
              'Function Notation',
              'Function notation names an output using the input value.',
              'f(a) means the value of f when x = a',
              'For f(x) = x + 5, f(2) = 7.',
              'If g(x) = 3x - 2, find g(5).',
              'g(5) = 13',
              [
                'Replace x with 5.',
                'Compute 3(5) - 2 = 15 - 2.',
                'So g(5) = 13.',
              ],
            ),
          ]),
          _lesson('function_values_and_domains', 'Values, Domain, and Range',
              '12 min', [
            _concept(
              'domain_and_range',
              'Domain and Range',
              'The domain is the set of possible inputs; the range is the set of possible outputs.',
              'Domain: x-values; Range: y-values',
              'For y = x + 1 with x = 1, 2, 3, the range is 2, 3, 4.',
              'For the pairs (1, 3), (2, 5), (4, 9), what is the domain?',
              '{1, 2, 4}',
              [
                'The domain is the set of first coordinates.',
                'Read the x-values: 1, 2, and 4.',
                'The domain is {1, 2, 4}.',
              ],
            ),
            _concept(
              'evaluating_functions',
              'Evaluating Functions',
              'Evaluating a function means substituting a given input and simplifying.',
              'If f(x) = ax + b, then f(c) = ac + b',
              'For f(x) = 4x - 1, f(3) = 11.',
              'If f(x) = 5x - 4, find f(6).',
              'f(6) = 26',
              [
                'Substitute x = 6.',
                'Compute 5(6) - 4 = 30 - 4.',
                'So f(6) = 26.',
              ],
            ),
          ]),
          _lesson(
              'function_operations', 'Operations and Composition', '12 min', [
            _concept(
              'operations_on_functions',
              'Operations on Functions',
              'Functions can be added, subtracted, multiplied, or divided using their outputs.',
              '(f + g)(x) = f(x) + g(x)',
              'If f(x)=x+2 and g(x)=3x, then (f+g)(x)=4x+2.',
              'If f(x) = x + 4 and g(x) = 2x, find (f + g)(3).',
              '13',
              [
                'Find f(3) = 3 + 4 = 7.',
                'Find g(3) = 2(3) = 6.',
                'Add them: 7 + 6 = 13.',
              ],
            ),
            _concept(
              'composite_functions',
              'Composite Functions',
              'A composite function uses the output of one function as the input of another.',
              '(f o g)(x) = f(g(x))',
              'If f(x)=x+1 and g(x)=2x, then f(g(3))=7.',
              'If f(x) = x + 2 and g(x) = 3x, find (f o g)(4).',
              '14',
              [
                'Find g(4) = 3(4) = 12.',
                'Use that output in f: f(12) = 12 + 2.',
                'So (f o g)(4) = 14.',
              ],
            ),
          ]),
          _lesson('inverse_functions_lesson',
              'One-to-One and Inverse Functions', '10 min', [
            _concept(
              'one_to_one_functions',
              'One-to-One Functions',
              'A one-to-one function pairs different inputs with different outputs.',
              'If a != b, then f(a) != f(b)',
              'f(x) = 2x + 1 is one-to-one because each input gives a unique output.',
              'Is f(x) = 3x - 5 one-to-one?',
              'Yes',
              [
                'A linear function with nonzero slope is one-to-one.',
                'The slope of f(x) = 3x - 5 is 3.',
                'Since the slope is not zero, the function is one-to-one.',
              ],
            ),
            _concept(
              'inverse_functions',
              'Inverse Functions',
              'An inverse function reverses the input and output of a one-to-one function.',
              'f(f^-1(x)) = x',
              'The inverse of f(x)=x+7 is f^-1(x)=x-7.',
              'Find the inverse of f(x) = x + 9.',
              'f^-1(x) = x - 9',
              [
                'Write y = x + 9.',
                'Swap x and y: x = y + 9.',
                'Solve for y: y = x - 9.',
              ],
            ),
          ]),
        ]),
        _topic('quadratic_equations', 'Quadratic Equations', 57, [
          _lesson('quadratic_intro', 'Introduction to Quadratic Equations',
              '8 min', [
            _concept(
              'quadratic_form',
              'What is a Quadratic Equation?',
              'A quadratic equation is a polynomial equation of degree two.',
              'ax^2 + bx + c = 0, where a is not equal to 0',
              '2x^2 + 5x + 3 = 0 has a = 2, b = 5, and c = 3.',
              'In 4x^2 + 7x + 2 = 0, what is a?',
              '4',
              [
                'Compare with ax^2 + bx + c = 0.',
                'The coefficient of x^2 is a.',
                'So a = 4.',
              ],
            ),
            _concept(
              'factoring',
              'Solving by Factoring',
              'Factoring rewrites a quadratic expression as a product of simpler expressions.',
              '(px + q)(rx + s) = 0',
              '(x + 2)(x + 3) = 0 gives x = -2 or x = -3.',
              quadraticProblem.question,
              quadraticProblem.answer,
              quadraticProblem.steps,
            ),
          ]),
        ]),
        _topic('polynomials', 'Polynomials', 56, [
          _lesson('polynomial_basics', 'Polynomial Basics', '7 min', [
            _concept(
              'degree_terms',
              'Degree and Terms',
              'The degree of a polynomial is the highest exponent of its variable.',
              'P(x) = a_nx^n + ... + a_1x + a_0',
              '3x^4 + 2x - 1 has degree 4.',
              'What is the degree of 5x^3 + 2x^2 - 7?',
              '3',
              [
                'Find the highest exponent.',
                'The highest exponent is 3.',
                'The degree is 3.',
              ],
            ),
          ]),
        ]),
        _topic('rational_functions', 'Rational Functions', 0, [
          _lesson(
              'rational_expressions', 'Rational Function Basics', '10 min', [
            _concept(
              'introduction_to_rational_functions',
              'Introduction to Rational Functions',
              'A rational function is a quotient of two polynomial functions.',
              'f(x) = p(x) / q(x), q(x) != 0',
              'f(x)=1/(x-2) is rational and is undefined at x=2.',
              'Is f(x) = (x + 1)/(x - 3) a rational function?',
              'Yes',
              [
                'The numerator x + 1 is a polynomial.',
                'The denominator x - 3 is also a polynomial.',
                'A quotient of polynomials is a rational function.',
              ],
            ),
            _concept(
              'domain_of_rational_functions',
              'Domain of Rational Functions',
              'The domain excludes values that make the denominator equal to zero.',
              'q(x) != 0',
              'For 1/(x-4), the domain excludes x = 4.',
              'Find the excluded value of f(x) = 1/(x - 6).',
              'x = 6',
              [
                'Set the denominator equal to zero: x - 6 = 0.',
                'Solve to get x = 6.',
                'The domain excludes x = 6.',
              ],
            ),
            _concept(
              'simplify_rational',
              'Simplifying Rational Expressions',
              'A rational expression can sometimes be simplified by factoring and canceling common factors.',
              '(x^2 - a^2)/(x - a) = x + a',
              'Cancel common factors only after factoring first.',
              'Simplify (x^2 - 1)/(x - 1).',
              'x + 1',
              [
                'Factor x^2 - 1 as (x - 1)(x + 1).',
                'Cancel x - 1.',
                'The simplified form is x + 1.',
              ],
            ),
          ]),
          _lesson('rational_function_applications',
              'Equations, Graphs, and Applications', '12 min', [
            _concept(
              'graphing_rational_functions',
              'Graphing Rational Functions',
              'Graphs of rational functions often have asymptotes where values are excluded.',
              'Vertical asymptote: denominator = 0',
              'The graph of 1/(x-2) has a vertical asymptote x=2.',
              'Find the vertical asymptote of y = 1/(x + 5).',
              'x = -5',
              [
                'Set the denominator equal to zero: x + 5 = 0.',
                'Solve for x: x = -5.',
                'The vertical asymptote is x = -5.',
              ],
            ),
            _concept(
              'rational_equations',
              'Rational Equations',
              'A rational equation contains at least one rational expression.',
              'Clear denominators after noting restrictions',
              'Solving 1/x = 1/4 gives x = 4.',
              'Solve 2/x = 1/3.',
              'x = 6',
              [
                'Cross multiply: 2(3) = x(1).',
                'Compute 6 = x.',
                'So x = 6.',
              ],
            ),
            _concept(
              'rational_inequalities',
              'Rational Inequalities',
              'A rational inequality compares rational expressions using inequality symbols.',
              'Use critical values from zeros and undefined points',
              'For 1/(x-2) > 0, the solution is x > 2.',
              'For 1/(x - 4) > 0, which interval is the solution?',
              'x > 4',
              [
                'The expression changes sign at x = 4.',
                'Test x = 5: 1/(5 - 4) is positive.',
                'So the solution is x > 4.',
              ],
            ),
            _concept(
              'applications_of_rational_functions',
              'Applications of Rational Functions',
              'Rational functions model quantities involving rates, averages, and inverse variation.',
              'time = work / rate',
              'If rate is 2 pages/min, 10 pages take 5 minutes.',
              'A printer makes 24 pages at 6 pages per minute. How long does it take?',
              '4 minutes',
              [
                'Use time = work / rate.',
                'Substitute 24 / 6.',
                'The time is 4 minutes.',
              ],
            ),
          ]),
        ]),
        _topic('exponential_functions', 'Exponential Functions', 0, [
          _lesson('exponential_rules', 'Laws and Equations', '10 min', [
            _concept(
              'laws_of_exponents',
              'Laws of Exponents',
              'Exponent laws simplify expressions with repeated multiplication.',
              'a^m * a^n = a^(m+n)',
              '2^3 * 2^4 = 2^7.',
              'Simplify 3^2 * 3^4.',
              '3^6',
              [
                'Use a^m * a^n = a^(m+n).',
                'Add the exponents: 2 + 4 = 6.',
                'The simplified form is 3^6.',
              ],
            ),
            _concept(
              'exponential_functions',
              'Exponential Functions',
              'An exponential function has a variable in the exponent.',
              'f(x) = ab^x',
              'f(x)=2^x doubles whenever x increases by 1.',
              'For f(x) = 2^x, find f(5).',
              '32',
              [
                'Substitute x = 5.',
                'Compute 2^5.',
                'The value is 32.',
              ],
            ),
            _concept(
              'exponential_equations',
              'Exponential Equations',
              'Exponential equations can be solved by writing both sides with the same base.',
              'If a^m = a^n, then m = n',
              '2^x = 16 becomes 2^x = 2^4, so x = 4.',
              'Solve 3^x = 81.',
              'x = 4',
              [
                'Write 81 as a power of 3.',
                'Since 81 = 3^4, the equation is 3^x = 3^4.',
                'Therefore x = 4.',
              ],
            ),
          ]),
          _lesson('exponential_models', 'Growth, Decay, and Applications',
              '10 min', [
            _concept(
              'exponential_growth',
              'Exponential Growth',
              'Exponential growth occurs when a quantity increases by a constant percent rate.',
              'A = P(1 + r)^t',
              'At 10% growth, 100 becomes 110 after one period.',
              'Find A for P = 100, r = 10%, and t = 1.',
              '110',
              [
                'Use A = P(1 + r)^t.',
                'Substitute A = 100(1.10)^1.',
                'The amount is 110.',
              ],
            ),
            _concept(
              'exponential_decay',
              'Exponential Decay',
              'Exponential decay occurs when a quantity decreases by a constant percent rate.',
              'A = P(1 - r)^t',
              'At 20% decay, 50 becomes 40 after one period.',
              'Find A for P = 50, r = 20%, and t = 1.',
              '40',
              [
                'Use A = P(1 - r)^t.',
                'Substitute A = 50(0.80)^1.',
                'The amount is 40.',
              ],
            ),
            _concept(
              'applications_of_exponential_functions',
              'Applications of Exponential Functions',
              'Exponential functions model repeated growth or decay such as population, depreciation, and interest.',
              'A = P(1 +/- r)^t',
              'A phone worth 10000 losing 10% becomes 9000 after one year.',
              'A gadget costs 8000 and depreciates 25% in one year. What is its value?',
              '6000',
              [
                'Use A = P(1 - r)^t.',
                'Substitute A = 8000(0.75)^1.',
                'The value is 6000.',
              ],
            ),
          ]),
        ]),
        _topic('logarithmic_functions', 'Logarithmic Functions', 0, [
          _lesson('logarithm_basics', 'Logarithm Basics', '10 min', [
            _concept(
              'introduction_to_logarithms',
              'Introduction to Logarithms',
              'A logarithm answers the question: what exponent produces a given number?',
              'log_b(a) = c means b^c = a',
              'log_2(8) = 3 because 2^3 = 8.',
              'Evaluate log_2(16).',
              '4',
              [
                'Ask what power of 2 equals 16.',
                'Since 2^4 = 16, the exponent is 4.',
                'So log_2(16) = 4.',
              ],
            ),
            _concept(
              'laws_of_logarithms',
              'Laws of Logarithms',
              'Logarithm laws rewrite products, quotients, and powers.',
              'log_b(MN) = log_b M + log_b N',
              'log_2(8*4)=log_2 8 + log_2 4.',
              'Rewrite log_3(9*27) using the product law.',
              'log_3 9 + log_3 27',
              [
                'Use log_b(MN) = log_b M + log_b N.',
                'Here M = 9 and N = 27.',
                'So the expression is log_3 9 + log_3 27.',
              ],
            ),
          ]),
          _lesson('logarithm_functions_and_equations',
              'Functions, Equations, and Applications', '12 min', [
            _concept(
              'logarithmic_functions',
              'Logarithmic Functions',
              'A logarithmic function is the inverse of an exponential function.',
              'f(x) = log_b x, x > 0',
              'f(x)=log_10 x is defined only for positive x.',
              'What is the domain of f(x) = log_5 x?',
              'x > 0',
              [
                'A logarithm is defined only for positive inputs.',
                'The input is x.',
                'Therefore x > 0.',
              ],
            ),
            _concept(
              'logarithmic_equations',
              'Logarithmic Equations',
              'A logarithmic equation can be solved by rewriting it in exponential form.',
              'log_b x = y means x = b^y',
              'log_2 x = 5 gives x = 32.',
              'Solve log_3 x = 4.',
              'x = 81',
              [
                'Rewrite in exponential form.',
                'x = 3^4.',
                'So x = 81.',
              ],
            ),
            _concept(
              'applications_of_logarithms',
              'Applications of Logarithms',
              'Logarithms are used to solve for unknown exponents in growth, decay, and scales.',
              'If a^x = b, then x = log_a b',
              'Solving 2^x = 32 uses x = log_2 32 = 5.',
              'If 10^x = 1000, what is x?',
              'x = 3',
              [
                'Write the equation in logarithmic form.',
                'x = log_10 1000.',
                'Since 10^3 = 1000, x = 3.',
              ],
            ),
          ]),
        ]),
        _topic('financial_mathematics', 'Financial Mathematics', 0, [
          _lesson('interest_and_value', 'Interest and Value', '12 min', [
            _concept(
              'simple_interest',
              'Simple Interest',
              'Simple interest is interest computed only on the original principal.',
              'I = Prt',
              'For P=1000, r=5%, t=2, interest is 100.',
              'Find the simple interest on 5000 at 6% for 2 years.',
              '600',
              [
                'Use I = Prt.',
                'Substitute I = 5000(0.06)(2).',
                'The simple interest is 600.',
              ],
            ),
            _concept(
              'compound_interest',
              'Compound Interest',
              'Compound interest earns interest on both principal and previous interest.',
              'A = P(1 + r)^t',
              '1000 at 10% for 2 years becomes 1210.',
              'Find the amount for 1000 at 10% compounded yearly for 2 years.',
              '1210',
              [
                'Use A = P(1 + r)^t.',
                'Substitute A = 1000(1.10)^2.',
                'The amount is 1210.',
              ],
            ),
            _concept(
              'present_value',
              'Present Value',
              'Present value is the current worth of a future amount.',
              'PV = FV / (1 + r)^t',
              'A future 1100 at 10% for 1 year has present value 1000.',
              'Find the present value of 2200 due in 1 year at 10%.',
              '2000',
              [
                'Use PV = FV / (1 + r)^t.',
                'Substitute PV = 2200 / 1.10.',
                'The present value is 2000.',
              ],
            ),
            _concept(
              'future_value',
              'Future Value',
              'Future value is the amount an investment grows to after interest.',
              'FV = PV(1 + r)^t',
              '2000 at 5% for 1 year becomes 2100.',
              'Find the future value of 3000 at 5% for 1 year.',
              '3150',
              [
                'Use FV = PV(1 + r)^t.',
                'Substitute FV = 3000(1.05).',
                'The future value is 3150.',
              ],
            ),
          ]),
          _lesson(
              'annuities_and_loans', 'Annuities, Funds, and Loans', '12 min', [
            _concept(
              'ordinary_annuities',
              'Ordinary Annuities',
              'An ordinary annuity has equal payments made at the end of each period.',
              'FV = R[((1+i)^n - 1)/i]',
              'Regular savings deposited monthly form an ordinary annuity.',
              'If 1000 is paid at the end of each of 3 periods with no interest, what is the total?',
              '3000',
              [
                'With no interest, add the equal payments.',
                'There are 3 payments of 1000.',
                'The total is 3000.',
              ],
            ),
            _concept(
              'general_annuities',
              'General Annuities',
              'A general annuity has payment intervals different from interest conversion intervals.',
              'Convert rates and periods before applying annuity formulas',
              'Monthly payments with quarterly compounding form a general annuity.',
              'Why must rates be converted in a general annuity?',
              'Payment and compounding periods differ',
              [
                'General annuities use different time intervals.',
                'The interest rate must match the payment period.',
                'Convert first so the formula uses consistent periods.',
              ],
            ),
            _concept(
              'sinking_funds',
              'Sinking Funds',
              'A sinking fund is regular saving set aside to reach a future amount.',
              'FV = R[((1+i)^n - 1)/i]',
              'Saving for equipment replacement can use a sinking fund.',
              'A class saves 500 per month for 4 months with no interest. How much is saved?',
              '2000',
              [
                'With no interest, multiply the deposit by the number of deposits.',
                'Compute 500(4).',
                'The fund has 2000.',
              ],
            ),
            _concept(
              'amortization',
              'Amortization',
              'Amortization pays off a loan through regular payments over time.',
              'Payment covers interest and part of principal',
              'Home and car loans are often amortized.',
              'A 12000 loan is paid in 12 equal payments with no interest. What is each payment?',
              '1000',
              [
                'Divide the loan by the number of payments.',
                'Compute 12000 / 12.',
                'Each payment is 1000.',
              ],
            ),
            _concept(
              'consumer_loans',
              'Consumer Loans',
              'Consumer loans are borrowed funds used for personal purchases.',
              'Total repayment = principal + finance charge',
              'A phone installment plan is a consumer loan.',
              'A loan of 8000 has a finance charge of 1200. What is the total repayment?',
              '9200',
              [
                'Add the principal and finance charge.',
                'Compute 8000 + 1200.',
                'The total repayment is 9200.',
              ],
            ),
          ]),
        ]),
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
        _topic('data_collection', 'Data Collection', 0, [
          _lesson('data_collection_basics',
              'Population, Samples, and Variables', '10 min', [
            _concept(
                'population_and_sample',
                'Population and Sample',
                'A population is the entire group of interest; a sample is a smaller part studied.',
                'sample ⊂ population',
                'All Grade 11 students are a population; 40 selected students are a sample.',
                'A researcher surveys 50 of 500 students. What is the sample?',
                '50 students', [
              'The sample is the group actually surveyed.',
              'The researcher surveyed 50 students.',
              'So the sample is 50 students.'
            ]),
            _concept(
                'variables',
                'Variables',
                'A variable is a characteristic or quantity that can take different values.',
                'Variable: measured characteristic',
                'Height, strand, and test score are variables.',
                'Is test score a variable?',
                'Yes', [
              'A variable changes from one person or item to another.',
              'Test scores can differ among students.',
              'Therefore, test score is a variable.'
            ]),
            _concept(
                'types_of_data',
                'Types of Data',
                'Data may be qualitative or quantitative depending on whether they describe categories or numbers.',
                'Qualitative: category; Quantitative: number',
                'Strand is qualitative; age is quantitative.',
                'Is age qualitative or quantitative?',
                'Quantitative', [
              'Age is measured with numbers.',
              'Numerical measurements are quantitative.',
              'Therefore, age is quantitative.'
            ]),
          ]),
          _lesson('sampling_and_design', 'Sampling and Experimental Design',
              '10 min', [
            _concept(
                'sampling_techniques',
                'Sampling Techniques',
                'Sampling techniques are methods for choosing a representative subset of a population.',
                'Common methods: random, stratified, systematic',
                'Choosing names by lottery is random sampling.',
                'Which sampling method uses a lottery of names?',
                'Random sampling', [
              'A lottery gives each name a chance to be selected.',
              'That matches random sampling.',
              'So the method is random sampling.'
            ]),
            _concept(
                'experimental_design',
                'Experimental Design',
                'Experimental design plans how treatments are assigned and measured fairly.',
                'Use control, randomization, and replication',
                'Testing two study methods with randomly assigned groups is an experiment.',
                'Why is random assignment useful in an experiment?',
                'It reduces bias', [
              'Random assignment balances groups more fairly.',
              'This reduces systematic differences between groups.',
              'Therefore, it helps reduce bias.'
            ]),
          ]),
        ]),
        _topic('data_organization_presentation',
            'Data Organization and Presentation', 0, [
          _lesson(
              'tables_and_basic_graphs', 'Tables and Basic Graphs', '10 min', [
            _concept(
                'frequency_distribution',
                'Frequency Distribution',
                'A frequency distribution organizes data by showing how often values or classes occur.',
                'frequency = count',
                'Scores 80, 80, 90 give frequency 2 for 80.',
                'In 2, 2, 3, 4, 4, 4, what is the frequency of 4?',
                '3', [
              'Count how many times 4 appears.',
              'The value 4 appears three times.',
              'The frequency is 3.'
            ]),
            _concept(
                'histograms',
                'Histograms',
                'A histogram displays numerical data grouped into intervals using adjacent bars.',
                'Bars touch because intervals are continuous',
                'A histogram can show grouped exam scores.',
                'Why do histogram bars usually touch?',
                'The intervals are continuous', [
              'Histograms show continuous numerical intervals.',
              'Adjacent intervals have no gap between them.',
              'Therefore, the bars usually touch.'
            ]),
            _concept(
                'bar_graphs',
                'Bar Graphs',
                'A bar graph compares categories using separated bars.',
                'bar height = category value',
                'A bar graph can compare students in each strand.',
                'Should bars in a bar graph be separated?',
                'Yes', [
              'Bar graphs compare categories.',
              'Categories are distinct from each other.',
              'So the bars are separated.'
            ]),
            _concept(
                'pie_charts',
                'Pie Charts',
                'A pie chart shows parts of a whole as sectors of a circle.',
                'sector percent = part / whole * 100%',
                'A class budget may be shown as a pie chart.',
                'If 25 of 100 students choose STEM, what percent is STEM?',
                '25%', [
              'Use part divided by whole.',
              'Compute 25 / 100 = 0.25.',
              'Convert to percent: 25%.'
            ]),
          ]),
          _lesson('distribution_graphs', 'Distribution Displays', '10 min', [
            _concept(
                'stem_and_leaf_plots',
                'Stem-and-Leaf Plots',
                'A stem-and-leaf plot organizes numerical data while keeping the original values visible.',
                'stem | leaf',
                'For 23, stem is 2 and leaf is 3.',
                'In the value 47, what is the stem if tens are stems?',
                '4', [
              'The tens digit is the stem.',
              'In 47, the tens digit is 4.',
              'So the stem is 4.'
            ]),
            _concept(
                'box_plots',
                'Box Plots',
                'A box plot summarizes data using minimum, quartiles, median, and maximum.',
                'five-number summary',
                'A box plot shows spread and center at a glance.',
                'Which value is at the center line of a box plot?',
                'Median', [
              'The line inside the box marks the median.',
              'The median is the center of the ordered data.',
              'Therefore, the center line is the median.'
            ]),
            _concept(
                'ogives',
                'Ogives',
                'An ogive is a graph of cumulative frequency.',
                'cumulative frequency = running total',
                'An ogive can show how many students scored at or below each class boundary.',
                'If frequencies are 2, 3, and 5, what is the final cumulative frequency?',
                '10', [
              'Add all frequencies for the final cumulative value.',
              'Compute 2 + 3 + 5.',
              'The final cumulative frequency is 10.'
            ]),
          ]),
        ]),
        _topic('measures_center', 'Measures of Central Tendency', 70, [
          _lesson(
              'mean_intro', 'Mean, Median, Mode, and Weighted Mean', '12 min', [
            _concept(
                'mean',
                'Mean',
                'The mean is the sum of values divided by the number of values.',
                'mean = sum of values / number of values',
                'For 2, 4, and 6, the mean is 4.',
                'Find the mean of 3, 5, 7, 9.',
                '6', [
              'Add the values: 3 + 5 + 7 + 9 = 24.',
              'Divide by 4.',
              'The mean is 6.'
            ]),
            _concept(
                'median',
                'Median',
                'The median is the middle value when data are arranged in order.',
                'middle ordered value',
                'The median of 2, 5, 9 is 5.',
                'Find the median of 4, 8, 2, 10, 6.',
                '6', [
              'Order the data: 2, 4, 6, 8, 10.',
              'The middle value is 6.',
              'So the median is 6.'
            ]),
            _concept(
                'mode',
                'Mode',
                'The mode is the value that appears most often.',
                'mode = most frequent value',
                'The mode of 1, 2, 2, 3 is 2.',
                'Find the mode of 5, 7, 7, 9.',
                '7', [
              'Count how often each value appears.',
              'The value 7 appears twice, more than the others.',
              'So the mode is 7.'
            ]),
            _concept(
                'weighted_mean',
                'Weighted Mean',
                'A weighted mean accounts for values that have different importance or frequency.',
                'weighted mean = sum(wx) / sum(w)',
                'Grades with different percentages use weighted mean.',
                'Find the weighted mean of 80 with weight 2 and 90 with weight 1.',
                '83.33', [
              'Multiply each value by its weight: 80(2) + 90(1) = 250.',
              'Add the weights: 2 + 1 = 3.',
              'Divide 250 / 3 = 83.33.'
            ]),
          ]),
        ]),
        _topic('measures_dispersion', 'Measures of Dispersion', 0, [
          _lesson('spread_measures', 'Range, Variance, and Standard Deviation',
              '12 min', [
            _concept(
                'range',
                'Range',
                'The range measures spread by subtracting the smallest value from the largest value.',
                'range = maximum - minimum',
                'For 2, 5, 9, the range is 7.',
                'Find the range of 4, 10, 7, 2.',
                '8', [
              'Identify the maximum: 10.',
              'Identify the minimum: 2.',
              'Subtract 10 - 2 = 8.'
            ]),
            _concept(
                'variance',
                'Variance',
                'Variance measures average squared distance from the mean.',
                'population variance = sum(x - mean)^2 / N',
                'A larger variance means values are more spread out.',
                'For data 2, 4, 6 with mean 4, find the population variance.',
                '8/3', [
              'Find squared deviations: 4, 0, and 4.',
              'Add them: 8.',
              'Divide by 3 to get 8/3.'
            ]),
            _concept(
                'standard_deviation',
                'Standard Deviation',
                'Standard deviation is the square root of variance.',
                'SD = sqrt(variance)',
                'If variance is 9, standard deviation is 3.',
                'If the variance is 16, what is the standard deviation?',
                '4', [
              'Use SD = sqrt(variance).',
              'Compute sqrt(16).',
              'The standard deviation is 4.'
            ]),
            _concept(
                'interquartile_range',
                'Interquartile Range',
                'The interquartile range measures the spread of the middle half of data.',
                'IQR = Q3 - Q1',
                'If Q1=10 and Q3=18, IQR=8.',
                'Find the IQR if Q1 = 12 and Q3 = 20.',
                '8',
                ['Use IQR = Q3 - Q1.', 'Substitute 20 - 12.', 'The IQR is 8.']),
          ]),
        ]),
        _topic('measures_position', 'Measures of Position', 0, [
          _lesson('position_measures',
              'Quartiles, Deciles, Percentiles, and Z-Scores', '12 min', [
            _concept(
                'quartiles',
                'Quartiles',
                'Quartiles divide ordered data into four equal parts.',
                'Q1, Q2, Q3',
                'Q2 is the median.',
                'Which quartile is the median?',
                'Q2', [
              'Quartiles split data into four parts.',
              'The second quartile is the halfway point.',
              'Therefore, Q2 is the median.'
            ]),
            _concept(
                'deciles',
                'Deciles',
                'Deciles divide ordered data into ten equal parts.',
                'D1 through D9',
                'D5 corresponds to the median position.',
                'How many equal parts do deciles create?',
                '10', [
              'The prefix deci refers to ten.',
              'Deciles divide data into ten equal parts.',
              'So the answer is 10.'
            ]),
            _concept(
                'percentiles',
                'Percentiles',
                'Percentiles divide ordered data into one hundred equal parts.',
                'Pk indicates the kth percentile',
                'P90 is the value below which about 90% of data fall.',
                'What percent of data is below the 75th percentile?',
                '75%', [
              'The kth percentile has k percent of data below it.',
              'For the 75th percentile, k = 75.',
              'So about 75% is below it.'
            ]),
            _concept(
                'z_scores',
                'Z-Scores',
                'A z-score tells how many standard deviations a value is from the mean.',
                'z = (x - mean) / sd',
                'If x=85, mean=75, and sd=5, then z=2.',
                'Find z if x = 90, mean = 80, and sd = 5.',
                '2', [
              'Use z = (x - mean) / sd.',
              'Substitute (90 - 80) / 5.',
              'The z-score is 2.'
            ]),
          ]),
        ]),
        _topic('probability_basics', 'Probability', 0, [
          _lesson('prob_intro', 'Sample Spaces, Events, and Rules', '10 min', [
            _concept(
                'sample_spaces',
                'Sample Spaces',
                'A sample space is the set of all possible outcomes.',
                'S = all outcomes',
                'For one coin toss, S = {H, T}.',
                'How many outcomes are in the sample space for one die roll?',
                '6', [
              'A die has faces 1 through 6.',
              'Each face is a possible outcome.',
              'There are 6 outcomes.'
            ]),
            _concept(
                'events',
                'Events',
                'An event is a subset of the sample space.',
                'Event ⊆ S',
                'Rolling an even number is the event {2, 4, 6}.',
                'For one die, how many outcomes are in the event rolling an even number?',
                '3', [
              'The even outcomes are 2, 4, and 6.',
              'Count them.',
              'There are 3 outcomes.'
            ]),
            _concept(
                'probability_formula',
                'Probability Formula',
                'Probability measures how likely an event is to happen.',
                'P(event) = favorable outcomes / total outcomes',
                'Rolling a 6 on a die has probability 1/6.',
                'What is the probability of getting heads when tossing one coin?',
                '1/2', [
              'There is 1 favorable outcome: heads.',
              'There are 2 total outcomes.',
              'The probability is 1/2.'
            ]),
            _concept(
                'basic_probability_rules',
                'Basic Probability Rules',
                'Probability rules include complement and addition rules for events.',
                'P(not A) = 1 - P(A)',
                'If P(A)=0.3, then P(not A)=0.7.',
                'If P(A) = 0.4, find P(not A).',
                '0.6', [
              'Use P(not A) = 1 - P(A).',
              'Compute 1 - 0.4.',
              'The result is 0.6.'
            ]),
          ]),
          _lesson('conditional_probability_lesson',
              'Conditional Probability and Bayes', '12 min', [
            _concept(
                'conditional_probability',
                'Conditional Probability',
                'Conditional probability measures the chance of an event given that another event occurred.',
                'P(A|B) = P(A and B) / P(B)',
                'If 6 students are STEM out of 10 honor students, P(STEM|honor)=6/10.',
                'If P(A and B)=0.2 and P(B)=0.5, find P(A|B).',
                '0.4', [
              'Use P(A|B)=P(A and B)/P(B).',
              'Substitute 0.2 / 0.5.',
              'The conditional probability is 0.4.'
            ]),
            _concept(
                'independent_and_dependent_events',
                'Independent and Dependent Events',
                'Independent events do not affect each other; dependent events do.',
                'Independent: P(A and B)=P(A)P(B)',
                'Two coin tosses are independent.',
                'If P(A)=1/2 and P(B)=1/3 are independent, find P(A and B).',
                '1/6', [
              'Multiply the probabilities for independent events.',
              'Compute 1/2 * 1/3.',
              'The result is 1/6.'
            ]),
            _concept(
                'bayes_theorem',
                'Bayes Theorem',
                'Bayes theorem updates probability using new evidence.',
                'P(A|B)=P(B|A)P(A)/P(B)',
                'It can revise the probability of a cause after observing an effect.',
                'If P(B|A)=0.8, P(A)=0.5, and P(B)=0.4, find P(A|B).',
                '1', [
              'Use Bayes theorem.',
              'Compute 0.8(0.5)/0.4 = 0.4/0.4.',
              'The result is 1.'
            ]),
          ]),
        ]),
        _topic('counting_techniques', 'Counting Techniques', 0, [
          _lesson('counting_methods',
              'Counting, Permutations, and Combinations', '10 min', [
            _concept(
                'fundamental_counting_principle',
                'Fundamental Counting Principle',
                'If choices are made in stages, multiply the number of choices per stage.',
                'total = m * n',
                '3 shirts and 2 pants make 6 outfits.',
                'A meal has 4 viands and 3 drinks. How many combinations are possible?',
                '12', [
              'Multiply the choices.',
              'Compute 4 * 3.',
              'There are 12 possible meals.'
            ]),
            _concept(
                'permutations',
                'Permutations',
                'A permutation is an arrangement where order matters.',
                'nPr = n! / (n-r)!',
                'Arranging 3 students in a line uses permutations.',
                'How many ways can 3 students be arranged in a line?',
                '6', [
              'Use 3! for arranging all 3 students.',
              'Compute 3 * 2 * 1.',
              'There are 6 arrangements.'
            ]),
            _concept(
                'combinations',
                'Combinations',
                'A combination is a selection where order does not matter.',
                'nCr = n! / [r!(n-r)!]',
                'Choosing 2 officers from 5 students uses combinations.',
                'How many ways can 2 students be chosen from 4?',
                '6', [
              'Use 4C2 = 4!/(2!2!).',
              'Compute 24 / 4.',
              'There are 6 ways.'
            ]),
          ]),
        ]),
        _topic('probability_distributions', 'Probability Distributions', 0, [
          _lesson('distribution_basics', 'Random Variables and Distributions',
              '12 min', [
            _concept(
                'random_variables',
                'Random Variables',
                'A random variable assigns a numerical value to each outcome of a random process.',
                'X = numerical outcome',
                'X can be the number of heads in two coin tosses.',
                'If X is the number of heads in one coin toss, what values can X take?',
                '0 or 1', [
              'One toss can have no heads or one head.',
              'So X may be 0 or 1.',
              'The possible values are 0 or 1.'
            ]),
            _concept(
                'discrete_probability_distributions',
                'Discrete Probability Distributions',
                'A discrete probability distribution lists possible values and their probabilities.',
                'sum P(X=x) = 1',
                'For one coin, P(X=0)=1/2 and P(X=1)=1/2.',
                'If P(X=1)=0.3 and P(X=2)=0.7, what is the total probability?',
                '1', [
              'Add the probabilities.',
              'Compute 0.3 + 0.7.',
              'The total probability is 1.'
            ]),
            _concept(
                'binomial_distribution',
                'Binomial Distribution',
                'A binomial distribution counts successes in fixed independent trials.',
                'P(X=k)=nCk p^k(1-p)^(n-k)',
                'The number of heads in 5 coin tosses can be binomial.',
                'For 3 fair coin tosses, what is P(exactly 3 heads)?',
                '1/8', [
              'There is one all-heads outcome.',
              'There are 2^3 = 8 equally likely outcomes.',
              'The probability is 1/8.'
            ]),
            _concept(
                'normal_distribution',
                'Normal Distribution',
                'A normal distribution is a symmetric bell-shaped distribution described by its mean and standard deviation.',
                'z = (x - mean) / sd',
                'Many test score distributions are approximately normal.',
                'In a normal curve, what line is at the center?',
                'Mean', [
              'The normal curve is symmetric.',
              'Its center is the mean.',
              'Therefore, the center line is the mean.'
            ]),
          ]),
        ]),
        _topic('inferential_statistics', 'Inferential Statistics', 0, [
          _lesson(
              'inference_basics', 'Sampling, Intervals, and Tests', '12 min', [
            _concept(
                'sampling_distributions',
                'Sampling Distributions',
                'A sampling distribution describes a statistic over many possible samples.',
                'mean of sample means = population mean',
                'Repeated sample means form a sampling distribution.',
                'What statistic is averaged in a sampling distribution of the sample mean?',
                'Sample means', [
              'The distribution is built from many samples.',
              'Each sample gives a sample mean.',
              'So it studies sample means.'
            ]),
            _concept(
                'confidence_intervals',
                'Confidence Intervals',
                'A confidence interval gives a range of plausible values for a population parameter.',
                'estimate +/- margin of error',
                '50 +/- 5 gives the interval 45 to 55.',
                'Construct the interval for mean 80 with margin of error 4.',
                '76 to 84', [
              'Subtract the margin: 80 - 4 = 76.',
              'Add the margin: 80 + 4 = 84.',
              'The interval is 76 to 84.'
            ]),
            _concept(
                'hypothesis_testing',
                'Hypothesis Testing',
                'Hypothesis testing uses sample data to decide whether evidence supports a claim.',
                'Compare p-value with alpha',
                'If p-value < alpha, reject the null hypothesis.',
                'If p-value = 0.03 and alpha = 0.05, what is the decision?',
                'Reject the null hypothesis', [
              'Compare 0.03 with 0.05.',
              'Since 0.03 is smaller, the result is significant.',
              'Reject the null hypothesis.'
            ]),
          ]),
          _lesson('relationships_between_variables',
              'Correlation and Regression', '10 min', [
            _concept(
                'correlation',
                'Correlation',
                'Correlation measures the strength and direction of a linear relationship.',
                '-1 <= r <= 1',
                'r = 0.9 indicates a strong positive relationship.',
                'What does r = -0.8 indicate?',
                'Strong negative correlation', [
              'The sign is negative, so the direction is negative.',
              'The value is close to -1, so it is strong.',
              'It indicates strong negative correlation.'
            ]),
            _concept(
                'simple_linear_regression',
                'Simple Linear Regression',
                'Simple linear regression models a straight-line relationship between two variables.',
                'y = mx + b',
                'If y=2x+5, then x=3 gives y=11.',
                'Using y = 3x + 2, find y when x = 4.',
                '14', [
              'Substitute x = 4.',
              'Compute 3(4) + 2 = 12 + 2.',
              'So y = 14.'
            ]),
          ]),
        ]),
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
        _topic('precalculus_functions', 'Functions', 0, [
          _lesson('families_of_functions', 'Families of Functions', '12 min', [
            _concept(
                'polynomial_functions',
                'Polynomial Functions',
                'Polynomial functions are sums of terms with nonnegative integer exponents.',
                'P(x)=a_nx^n+...+a_0',
                'f(x)=x^2+3x+2 is polynomial.',
                'What is the degree of f(x)=2x^4+x-1?',
                '4', [
              'Find the highest exponent.',
              'The highest exponent is 4.',
              'The degree is 4.'
            ]),
            _concept(
                'precalculus_rational_functions',
                'Rational Functions',
                'A rational function is a quotient of polynomial functions.',
                'f(x)=p(x)/q(x)',
                'f(x)=1/(x+1) is rational.',
                'What value is excluded from f(x)=1/(x+2)?',
                'x = -2', [
              'Set the denominator equal to zero.',
              'x + 2 = 0 gives x = -2.',
              'Exclude x = -2.'
            ]),
            _concept(
                'radical_functions',
                'Radical Functions',
                'A radical function contains a variable inside a root.',
                'f(x)=sqrt(x)',
                'sqrt(x-1) is defined for x >= 1.',
                'What is the smallest allowed x for sqrt(x - 5)?',
                '5', [
              'The radicand must be nonnegative.',
              'Set x - 5 >= 0.',
              'So x >= 5.'
            ]),
            _concept(
                'absolute_value_functions',
                'Absolute Value Functions',
                'An absolute value function measures distance from zero or a reference point.',
                'f(x)=|x|',
                '|-6| = 6.',
                'Evaluate |-9|.',
                '9', [
              'Absolute value is distance from zero.',
              'Distance is never negative.',
              'Therefore |-9| = 9.'
            ]),
            _concept(
                'piecewise_functions',
                'Piecewise Functions',
                'A piecewise function uses different rules for different parts of the domain.',
                'f(x) = rule by interval',
                'Use one rule for x<0 and another for x>=0.',
                'If f(x)=x+1 for x>=0, find f(4).',
                '5', [
              'Since 4 >= 0, use f(x)=x+1.',
              'Substitute 4 + 1.',
              'The value is 5.'
            ]),
          ]),
        ]),
        _topic('trigonometry', 'Trigonometry', 45, [
          _lesson('angle_measure', 'Angles and Measurement', '10 min', [
            _concept(
                'angles',
                'Angles',
                'An angle is formed by two rays with a common endpoint.',
                'full turn = 360 degrees',
                'A right angle measures 90 degrees.',
                'How many degrees are in a right angle?',
                '90 degrees', [
              'A right angle is one-fourth of a full turn.',
              'A full turn is 360 degrees.',
              'One-fourth of 360 is 90 degrees.'
            ]),
            _concept(
                'degree_measure',
                'Degree Measure',
                'Degree measure divides a full rotation into 360 equal parts.',
                '1 full turn = 360 degrees',
                'A straight angle is 180 degrees.',
                'How many degrees are in a straight angle?',
                '180 degrees', [
              'A straight angle forms a line.',
              'A line is half of a full turn.',
              'Half of 360 degrees is 180 degrees.'
            ]),
            _concept(
                'radian_measure',
                'Radian Measure',
                'Radian measure relates an angle to arc length on a circle.',
                '180 degrees = pi radians',
                '90 degrees = pi/2 radians.',
                'Convert 180 degrees to radians.',
                'pi radians', [
              'Use 180 degrees = pi radians.',
              'The angle is exactly 180 degrees.',
              'So it equals pi radians.'
            ]),
            _concept(
                'unit_circle',
                'Unit Circle',
                'The unit circle is a circle with radius 1 centered at the origin.',
                'x^2 + y^2 = 1',
                'The point (1,0) corresponds to 0 degrees.',
                'What is the radius of the unit circle?',
                '1', [
              'By definition, the unit circle has radius 1.',
              'It is centered at the origin.',
              'So the radius is 1.'
            ]),
          ]),
          _lesson('trig_ratios', 'Trigonometric Functions', '12 min', [
            _concept(
                'sine_cosine',
                'Sine, Cosine, and Tangent',
                'Trigonometric ratios compare sides of a right triangle.',
                'sin theta = opposite / hypotenuse',
                'If opposite = 3 and hypotenuse = 5, sin theta = 3/5.',
                'Find sin theta if opposite = 6 and hypotenuse = 10.',
                '3/5', [
              'Use sin theta = opposite / hypotenuse.',
              'Substitute 6/10.',
              'Simplify to 3/5.'
            ]),
            _concept(
                'six_trigonometric_functions',
                'Six Trigonometric Functions',
                'The six trigonometric functions are sine, cosine, tangent, cosecant, secant, and cotangent.',
                'csc=1/sin, sec=1/cos, cot=1/tan',
                'If sin theta=1/2, then csc theta=2.',
                'If sin theta = 1/4, find csc theta.',
                '4', [
              'Cosecant is the reciprocal of sine.',
              'Compute 1 / (1/4).',
              'The value is 4.'
            ]),
            _concept(
                'graphs_of_trigonometric_functions',
                'Graphs of Trigonometric Functions',
                'Trigonometric graphs show periodic patterns that repeat over intervals.',
                'period of sin x = 2pi',
                'The sine graph repeats every 2pi radians.',
                'What is the period of y = sin x?',
                '2pi', [
              'The basic sine function repeats every full cycle.',
              'One full cycle is 2pi radians.',
              'So the period is 2pi.'
            ]),
            _concept(
                'trigonometric_identities',
                'Trigonometric Identities',
                'Trigonometric identities are equations true for all allowed angle values.',
                'sin^2 x + cos^2 x = 1',
                'If sin x=3/5 and cos x=4/5, the squares add to 1.',
                'If sin x = 3/5 and cos x = 4/5, verify sin^2 x + cos^2 x.',
                '1', [
              'Square each value: 9/25 and 16/25.',
              'Add them: 25/25.',
              'The result is 1.'
            ]),
          ]),
          _lesson('advanced_trigonometry', 'Equations and Triangle Laws',
              '12 min', [
            _concept(
                'inverse_trigonometric_functions',
                'Inverse Trigonometric Functions',
                'Inverse trigonometric functions find an angle from a trigonometric ratio.',
                'theta = sin^-1(ratio)',
                'sin^-1(1/2)=30 degrees for the principal angle.',
                'What principal angle has sin theta = 1/2?',
                '30 degrees', [
              'Recall the special angle values.',
              'sin 30 degrees = 1/2.',
              'The principal angle is 30 degrees.'
            ]),
            _concept(
                'trigonometric_equations',
                'Trigonometric Equations',
                'A trigonometric equation contains a trigonometric function of an unknown angle.',
                'Solve over a stated interval',
                'sin x = 0 has solutions 0 and 180 degrees from 0 to 180 degrees.',
                'Solve sin x = 1 for 0 to 180 degrees.',
                '90 degrees', [
              'Sine reaches 1 at the top of the unit circle.',
              'That angle is 90 degrees.',
              'So x = 90 degrees.'
            ]),
            _concept(
                'law_of_sines',
                'Law of Sines',
                'The Law of Sines relates sides and opposite angles in any triangle.',
                'a/sin A = b/sin B',
                'It is useful when an angle-side opposite pair is known.',
                'If a/sin A = 10 and sin B = 1/2, find b.',
                '5',
                ['Use b/sin B = 10.', 'Substitute b/(1/2) = 10.', 'So b = 5.']),
            _concept(
                'law_of_cosines',
                'Law of Cosines',
                'The Law of Cosines relates three sides and the included angle of a triangle.',
                'c^2 = a^2 + b^2 - 2ab cos C',
                'It extends the Pythagorean theorem to non-right triangles.',
                'If a=3, b=4, and C=90 degrees, find c.',
                '5', [
              'Use cos 90 degrees = 0.',
              'Then c^2 = 3^2 + 4^2.',
              'So c^2 = 25 and c = 5.'
            ]),
          ]),
        ]),
        _topic('analytic_geometry', 'Analytic Geometry', 0, [
          _lesson('coordinate_geometry', 'Coordinates, Distance, and Slope',
              '12 min', [
            _concept(
                'coordinate_plane',
                'Coordinate Plane',
                'The coordinate plane locates points using ordered pairs.',
                '(x, y)',
                'The point (3, 2) is 3 units right and 2 units up.',
                'In (5, -2), what is the x-coordinate?',
                '5', [
              'The x-coordinate is the first number.',
              'In (5, -2), the first number is 5.',
              'So x = 5.'
            ]),
            _concept(
                'distance_formula',
                'Distance Formula',
                'The distance formula finds the length between two points.',
                'd = sqrt((x2-x1)^2 + (y2-y1)^2)',
                'The distance from (0,0) to (3,4) is 5.',
                'Find the distance from (0,0) to (6,8).',
                '10', [
              'Use the distance formula.',
              'Compute sqrt(6^2 + 8^2) = sqrt(100).',
              'The distance is 10.'
            ]),
            _concept(
                'midpoint_formula',
                'Midpoint Formula',
                'The midpoint formula finds the point halfway between two points.',
                'M=((x1+x2)/2,(y1+y2)/2)',
                'The midpoint of (0,0) and (4,6) is (2,3).',
                'Find the midpoint of (2,4) and (6,8).',
                '(4, 6)', [
              'Average the x-coordinates: (2 + 6)/2 = 4.',
              'Average the y-coordinates: (4 + 8)/2 = 6.',
              'The midpoint is (4, 6).'
            ]),
            _concept(
                'slope',
                'Slope',
                'Slope measures the steepness of a line.',
                'm = (y2-y1)/(x2-x1)',
                'The slope through (1,2) and (3,6) is 2.',
                'Find the slope through (1,2) and (4,8).',
                '2', [
              'Use m = (8 - 2)/(4 - 1).',
              'Compute 6/3.',
              'The slope is 2.'
            ]),
          ]),
          _lesson('lines_in_the_plane', 'Lines in the Plane', '10 min', [
            _concept(
                'equation_of_a_line',
                'Equation of a Line',
                'A line can be represented by an equation relating x and y.',
                'y = mx + b',
                'In y=2x+3, slope is 2 and y-intercept is 3.',
                'What is the slope of y = 5x - 1?',
                '5', [
              'Compare with y = mx + b.',
              'The coefficient of x is m.',
              'So the slope is 5.'
            ]),
            _concept(
                'parallel_and_perpendicular_lines',
                'Parallel and Perpendicular Lines',
                'Parallel lines have equal slopes; perpendicular lines have slopes whose product is -1.',
                'parallel: m1=m2; perpendicular: m1*m2=-1',
                'A line perpendicular to slope 2 has slope -1/2.',
                'What slope is parallel to m = 3?',
                '3', [
              'Parallel lines have the same slope.',
              'The given slope is 3.',
              'So a parallel line also has slope 3.'
            ]),
          ]),
        ]),
        _topic('conic_sections', 'Conic Sections', 28, [
          _lesson('circle_equation',
              'Circles, Parabolas, Ellipses, and Hyperbolas', '12 min', [
            _concept(
                'circle_standard',
                'Standard Form of a Circle',
                'A circle is the set of points with the same distance from its center.',
                '(x - h)^2 + (y - k)^2 = r^2',
                '(x - 2)^2 + (y + 1)^2 = 9 has center (2, -1) and radius 3.',
                'Find the radius of (x - 1)^2 + (y - 2)^2 = 16.',
                '4',
                ['Compare with standard form.', 'r^2 = 16.', 'r = 4.']),
            _concept(
                'circles',
                'Circles',
                'A circle is the set of all points equidistant from a fixed center.',
                '(x-h)^2+(y-k)^2=r^2',
                'Center (0,0) and radius 5 gives x^2+y^2=25.',
                'What is the radius of x^2 + y^2 = 49?',
                '7', [
              'Compare x^2 + y^2 = 49 with x^2 + y^2 = r^2.',
              'So r^2 = 49.',
              'Thus r = 7.'
            ]),
            _concept(
                'parabolas',
                'Parabolas',
                'A parabola is the set of points equidistant from a focus and a directrix.',
                'y = a(x-h)^2 + k',
                'The graph y=x^2 is a parabola opening upward.',
                'Does y = x^2 open upward or downward?',
                'Upward', [
              'The coefficient of x^2 is positive.',
              'A positive coefficient opens upward.',
              'So the parabola opens upward.'
            ]),
            _concept(
                'ellipses',
                'Ellipses',
                'An ellipse is the set of points whose distances from two foci have a constant sum.',
                '(x-h)^2/a^2 + (y-k)^2/b^2 = 1',
                'Planetary orbits are modeled by ellipses.',
                'Identify the conic: x^2/9 + y^2/4 = 1.',
                'Ellipse', [
              'Both squared terms are added.',
              'The denominators are positive and unequal.',
              'This is an ellipse.'
            ]),
            _concept(
                'hyperbolas',
                'Hyperbolas',
                'A hyperbola is the set of points whose distances from two foci have a constant difference.',
                '(x-h)^2/a^2 - (y-k)^2/b^2 = 1',
                'A hyperbola has two branches.',
                'Identify the conic: x^2/4 - y^2/9 = 1.',
                'Hyperbola', [
              'One squared term is subtracted from another.',
              'That sign pattern identifies a hyperbola.',
              'So the conic is a hyperbola.'
            ]),
          ]),
          _lesson('conic_equations_and_graphs',
              'Equations, Graphs, and Applications', '10 min', [
            _concept(
                'standard_equations_of_conic_sections',
                'Standard Equations of Conic Sections',
                'Standard equations reveal the type and key features of a conic.',
                'circle, parabola, ellipse, hyperbola forms',
                'x^2+y^2=16 is a circle in standard form.',
                'Which conic has standard form x^2 + y^2 = r^2?',
                'Circle', [
              'The equation has x^2 and y^2 added with equal coefficients.',
              'That is the standard circle form.',
              'So the conic is a circle.'
            ]),
            _concept(
                'graphing_conic_sections',
                'Graphing Conic Sections',
                'Graphing conics uses centers, vertices, radii, and asymptotes from standard form.',
                'Read features from standard form',
                'A circle graph uses its center and radius.',
                'To graph a circle, what two features are most important?',
                'Center and radius', [
              'A circle is located by its center.',
              'Its size is determined by its radius.',
              'So use center and radius.'
            ]),
            _concept(
                'applications_of_conic_sections',
                'Applications of Conic Sections',
                'Conic sections model paths and shapes such as mirrors, orbits, and cables.',
                'Choose model by shape and property',
                'Satellite dishes use parabolic reflection.',
                'Which conic is commonly used to model satellite dish reflection?',
                'Parabola', [
              'Satellite dishes focus incoming signals.',
              'Parabolas have a focus property.',
              'Therefore the model is a parabola.'
            ]),
          ]),
        ]),
        _topic('sequences_and_series', 'Sequences and Series', 0, [
          _lesson('arithmetic_and_geometric_sequences',
              'Arithmetic and Geometric Patterns', '12 min', [
            _concept(
                'arithmetic_sequences',
                'Arithmetic Sequences',
                'An arithmetic sequence has a constant difference between consecutive terms.',
                'a_n = a_1 + (n-1)d',
                '2, 5, 8, 11 has common difference 3.',
                'Find the 5th term if a1 = 2 and d = 3.',
                '14', [
              'Use a_n = a_1 + (n-1)d.',
              'Compute a_5 = 2 + 4(3).',
              'The 5th term is 14.'
            ]),
            _concept(
                'arithmetic_series',
                'Arithmetic Series',
                'An arithmetic series is the sum of terms of an arithmetic sequence.',
                'S_n = n/2(a_1 + a_n)',
                '2 + 4 + 6 = 12.',
                'Find the sum of 2 + 4 + 6 + 8.',
                '20', [
              'Add the terms directly.',
              '2 + 4 + 6 + 8 = 20.',
              'The sum is 20.'
            ]),
            _concept(
                'geometric_sequences',
                'Geometric Sequences',
                'A geometric sequence has a constant ratio between consecutive terms.',
                'a_n = a_1 r^(n-1)',
                '3, 6, 12 has common ratio 2.',
                'Find the 4th term if a1 = 3 and r = 2.',
                '24', [
              'Use a_n = a_1 r^(n-1).',
              'Compute a_4 = 3(2^3).',
              'The 4th term is 24.'
            ]),
            _concept(
                'geometric_series',
                'Geometric Series',
                'A geometric series is the sum of terms of a geometric sequence.',
                'S_n = a_1(1-r^n)/(1-r), r != 1',
                '2 + 4 + 8 = 14.',
                'Find the sum of 2 + 4 + 8 + 16.',
                '30', [
              'Add the terms directly.',
              '2 + 4 + 8 + 16 = 30.',
              'The sum is 30.'
            ]),
          ]),
          _lesson('other_sequence_tools', 'Other Sequence Tools', '8 min', [
            _concept(
                'harmonic_sequences',
                'Harmonic Sequences',
                'A harmonic sequence has reciprocals that form an arithmetic sequence.',
                'terms are reciprocals of arithmetic terms',
                '1/2, 1/4, 1/6 is harmonic because 2, 4, 6 is arithmetic.',
                'Is 1/3, 1/6, 1/9 harmonic?',
                'Yes', [
              'Take reciprocals: 3, 6, 9.',
              'These have common difference 3.',
              'Therefore the original sequence is harmonic.'
            ]),
            _concept(
                'sigma_notation',
                'Sigma Notation',
                'Sigma notation is a compact way to write a sum.',
                'Σ a_i',
                'Σ from i=1 to 3 of i means 1+2+3.',
                'Evaluate Σ from i=1 to 4 of i.',
                '10', [
              'Expand the sum: 1 + 2 + 3 + 4.',
              'Add the terms.',
              'The value is 10.'
            ]),
          ]),
        ]),
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
        _topic('limits', 'Limits and Continuity', 0, [
          _lesson('limits_intro', 'Introduction and Evaluation of Limits',
              '12 min', [
            _concept(
                'limit_meaning',
                'Meaning of a Limit',
                'A limit describes the value a function approaches as x gets close to a number.',
                'lim x->a f(x) = L',
                'As x approaches 2, f(x) = x + 1 approaches 3.',
                'Evaluate lim x->2 (x + 1).',
                '3',
                ['Substitute x = 2.', 'Compute 2 + 1.', 'The limit is 3.']),
            _concept(
                'introduction_to_limits',
                'Introduction to Limits',
                'A limit focuses on nearby behavior rather than only the value at a point.',
                'lim x->a f(x)',
                'Even if f(a) is missing, the limit may exist.',
                'If f(x)=x+2, what value is approached as x approaches 3?',
                '5', [
              'Use the expression x + 2.',
              'Substitute a nearby value approaching 3.',
              'The approached value is 3 + 2 = 5.'
            ]),
            _concept(
                'evaluating_limits',
                'Evaluating Limits',
                'Many basic limits can be evaluated by direct substitution.',
                'lim x->a f(x)=f(a), when continuous',
                'lim x->4 (2x+1)=9.',
                'Evaluate lim x->5 (2x - 3).',
                '7',
                ['Substitute x = 5.', 'Compute 2(5) - 3.', 'The limit is 7.']),
            _concept(
                'one_sided_limits',
                'One-Sided Limits',
                'One-sided limits describe behavior from the left or from the right of a point.',
                'lim x->a- f(x), lim x->a+ f(x)',
                'A jump graph can have different left and right limits.',
                'If the left-hand limit is 2 and right-hand limit is 5, does the two-sided limit exist?',
                'No', [
              'A two-sided limit exists only when both one-sided limits match.',
              'Here 2 and 5 are not equal.',
              'Therefore the two-sided limit does not exist.'
            ]),
          ]),
          _lesson('special_limits_and_continuity',
              'Special Limits and Continuity', '10 min', [
            _concept(
                'infinite_limits',
                'Infinite Limits',
                'An infinite limit occurs when function values grow without bound near a point.',
                'lim f(x)=infinity or -infinity',
                '1/(x-2)^2 grows without bound near x=2.',
                'What happens to 1/(x-3)^2 as x approaches 3?',
                'It grows without bound', [
              'The denominator approaches zero.',
              'The square keeps values positive.',
              'The function grows without bound.'
            ]),
            _concept(
                'limits_at_infinity',
                'Limits at Infinity',
                'A limit at infinity describes end behavior as x becomes very large or very small.',
                'lim x->infinity f(x)',
                'lim x->infinity 1/x = 0.',
                'Evaluate lim x->infinity 1/x.',
                '0', [
              'As x grows larger, 1/x gets closer to zero.',
              'It never needs to become negative.',
              'The limit is 0.'
            ]),
            _concept(
                'continuity',
                'Continuity',
                'A function is continuous at a point if its graph has no break there.',
                'lim x->a f(x) = f(a)',
                'A polynomial is continuous for all real x.',
                'Is f(x)=x^2 continuous at x=1?',
                'Yes', [
              'Polynomials are continuous for all real numbers.',
              'x=1 is a real number.',
              'So f(x)=x^2 is continuous at x=1.'
            ]),
          ]),
        ]),
        _topic('derivatives', 'Derivatives and Differentiation Rules', 22, [
          _lesson('power_rule', 'Definition and Basic Rules', '12 min', [
            _concept(
                'definition_of_a_derivative',
                'Definition of a Derivative',
                'A derivative measures instantaneous rate of change or slope of a tangent line.',
                'f\'(x)=lim h->0 [f(x+h)-f(x)]/h',
                'For position, derivative gives velocity.',
                'What does the derivative represent graphically?',
                'Slope of the tangent line', [
              'The derivative measures instantaneous change.',
              'On a graph, instantaneous change is tangent slope.',
              'So it represents the slope of the tangent line.'
            ]),
            _concept(
                'basic_power_rule',
                'Using the Power Rule',
                'The power rule is used to find derivatives of power functions.',
                'd/dx x^n = nx^(n-1)',
                'The derivative of x^3 is 3x^2.',
                'Find the derivative of x^4.',
                '4x^3', [
              'Use d/dx x^n = nx^(n-1).',
              'Let n = 4.',
              'The derivative is 4x^3.'
            ]),
            _concept(
                'sum_and_difference_rule',
                'Sum and Difference Rule',
                'The derivative of a sum or difference is the sum or difference of the derivatives.',
                'd(f +/- g)=f\' +/- g\'',
                'd/dx(x^2+x)=2x+1.',
                'Differentiate x^2 + x.',
                '2x + 1', [
              'Differentiate x^2 to get 2x.',
              'Differentiate x to get 1.',
              'Add them to get 2x + 1.'
            ]),
          ]),
          _lesson('product_quotient_chain_rules',
              'Product, Quotient, and Chain Rules', '12 min', [
            _concept(
                'product_rule',
                'Product Rule',
                'The product rule differentiates a product of two functions.',
                '(fg)\' = f\'g + fg\'',
                'd/dx[x(x+1)] = 1(x+1)+x(1).',
                'Using product rule, differentiate x(x+2).',
                '2x + 2', [
              'Let f=x and g=x+2.',
              'Use f\'g + fg\' = 1(x+2)+x(1).',
              'Simplify to 2x + 2.'
            ]),
            _concept(
                'quotient_rule',
                'Quotient Rule',
                'The quotient rule differentiates a quotient of two functions.',
                '(f/g)\' = (f\'g - fg\')/g^2',
                'Use it when a variable expression is divided by another.',
                'For f(x)=x/2, what is f\'(x)?',
                '1/2', [
              'The denominator is constant 2.',
              'x/2 = (1/2)x.',
              'The derivative is 1/2.'
            ]),
            _concept(
                'chain_rule',
                'Chain Rule',
                'The chain rule differentiates a composite function.',
                'd/dx f(g(x)) = f\'(g(x))g\'(x)',
                'd/dx (x+1)^2 = 2(x+1).',
                'Differentiate (x + 3)^2.',
                '2x + 6', [
              'Use the chain rule: 2(x + 3)(1).',
              'Distribute 2.',
              'The derivative is 2x + 6.'
            ]),
          ]),
          _lesson('advanced_differentiation', 'Advanced Differentiation',
              '10 min', [
            _concept(
                'implicit_differentiation',
                'Implicit Differentiation',
                'Implicit differentiation finds derivatives when x and y are mixed in one equation.',
                'Differentiate both sides with respect to x',
                'For x^2+y^2=25, differentiate both sides.',
                'Differentiate x^2 + y^2 = 25 with respect to x.',
                '2x + 2y dy/dx = 0', [
              'Differentiate x^2 to get 2x.',
              'Differentiate y^2 using chain rule to get 2y dy/dx.',
              'The derivative of 25 is 0.'
            ]),
            _concept(
                'higher_order_derivatives',
                'Higher-Order Derivatives',
                'Higher-order derivatives are derivatives taken repeatedly.',
                'f\'\', f\'\'\', ...',
                'If f(x)=x^3, then f\'(x)=3x^2 and f\'\'(x)=6x.',
                'Find the second derivative of x^3.',
                '6x', [
              'First derivative: 3x^2.',
              'Differentiate again.',
              'The second derivative is 6x.'
            ]),
          ]),
        ]),
        _topic(
            'applications_of_derivatives', 'Applications of Derivatives', 0, [
          _lesson(
              'tangent_and_rates', 'Tangents, Normals, and Rates', '12 min', [
            _concept(
                'tangent_lines',
                'Tangent Lines',
                'A tangent line touches a curve at a point and has slope equal to the derivative there.',
                'y - y1 = m(x - x1)',
                'If f\'(2)=3, the tangent slope at x=2 is 3.',
                'If f\'(1)=4, what is the tangent slope at x=1?',
                '4', [
              'The derivative gives tangent slope.',
              'At x=1, f\'(1)=4.',
              'So the tangent slope is 4.'
            ]),
            _concept(
                'normal_lines',
                'Normal Lines',
                'A normal line is perpendicular to the tangent line at a point.',
                'm_normal = -1 / m_tangent',
                'If tangent slope is 2, normal slope is -1/2.',
                'If tangent slope is 5, what is the normal slope?',
                '-1/5', [
              'Normal lines are perpendicular to tangents.',
              'Use the negative reciprocal.',
              'The normal slope is -1/5.'
            ]),
            _concept(
                'related_rates',
                'Related Rates',
                'Related rates problems connect changing quantities using derivatives.',
                'Differentiate related equation with respect to time',
                'If area depends on radius, dA/dt depends on dr/dt.',
                'If y = 3x and dx/dt = 2, find dy/dt.',
                '6', [
              'Differentiate y = 3x with respect to time.',
              'dy/dt = 3 dx/dt.',
              'Substitute dx/dt = 2 to get 6.'
            ]),
          ]),
          _lesson('increasing_extrema_concavity',
              'Increasing, Extrema, and Concavity', '12 min', [
            _concept(
                'increasing_and_decreasing_functions',
                'Increasing and Decreasing Functions',
                'A function increases where its derivative is positive and decreases where it is negative.',
                'f\'(x)>0 increasing; f\'(x)<0 decreasing',
                'If f\'(x)=2 on an interval, f is increasing there.',
                'If f\'(x) = -3 on an interval, is f increasing or decreasing?',
                'Decreasing', [
              'A negative derivative means the function moves downward as x increases.',
              'Here f\'(x) = -3 is negative.',
              'So the function is decreasing.'
            ]),
            _concept(
                'local_maximum_and_minimum',
                'Local Maximum and Minimum',
                'Local extrema are high or low points compared with nearby values.',
                'critical point: f\'(x)=0 or undefined',
                'The vertex of y=x^2 is a local minimum.',
                'Does y = x^2 have a local maximum or minimum at x=0?',
                'Local minimum', [
              'The parabola y=x^2 opens upward.',
              'Its vertex is the lowest nearby point.',
              'So it has a local minimum.'
            ]),
            _concept(
                'first_derivative_test',
                'First Derivative Test',
                'The first derivative test classifies critical points by sign changes of f\'.',
                '+ to - means local maximum; - to + means local minimum',
                'If f\' changes from negative to positive, there is a local minimum.',
                'If f\' changes from positive to negative, what occurs?',
                'Local maximum', [
              'Positive derivative means increasing.',
              'Negative derivative means decreasing.',
              'Changing from increasing to decreasing gives a local maximum.'
            ]),
            _concept(
                'second_derivative_test',
                'Second Derivative Test',
                'The second derivative test uses concavity to classify critical points.',
                'f\'\'(c)>0 min; f\'\'(c)<0 max',
                'If f\'(c)=0 and f\'\'(c)>0, there is a local minimum.',
                'If f\'(c)=0 and f\'\'(c)<0, what occurs?',
                'Local maximum', [
              'A negative second derivative means concave down.',
              'At a critical point, concave down forms a peak.',
              'So there is a local maximum.'
            ]),
            _concept(
                'concavity',
                'Concavity',
                'Concavity describes whether a graph bends upward or downward.',
                'f\'\'(x)>0 concave up; f\'\'(x)<0 concave down',
                'y=x^2 is concave up.',
                'If f\'\'(x)>0, what is the concavity?',
                'Concave up', [
              'Positive second derivative means slopes are increasing.',
              'That shape bends upward.',
              'So the graph is concave up.'
            ]),
          ]),
          _lesson('optimization_and_graphing',
              'Optimization and Curve Sketching', '10 min', [
            _concept(
                'optimization',
                'Optimization',
                'Optimization uses derivatives to find maximum or minimum values.',
                'Set f\'(x)=0 and test candidates',
                'Finding the largest area for a fixed perimeter is optimization.',
                'To optimize a differentiable function, what equation is often solved first?',
                'f\'(x) = 0', [
              'Extrema often occur at critical points.',
              'For differentiable functions, critical points satisfy f\'(x)=0.',
              'So solve f\'(x)=0 first.'
            ]),
            _concept(
                'curve_sketching',
                'Curve Sketching',
                'Curve sketching uses intercepts, derivatives, and concavity to describe a graph.',
                'Use f, f\', and f\'\' information',
                'Derivative signs show increasing and decreasing intervals.',
                'Which derivative helps determine concavity?',
                'Second derivative', [
              'Concavity depends on how slopes change.',
              'The second derivative measures that change.',
              'So use the second derivative.'
            ]),
          ]),
        ]),
        _topic('integration', 'Integration', 0, [
          _lesson(
              'integral_basics', 'Antiderivatives and Integrals', '12 min', [
            _concept(
                'antiderivatives',
                'Antiderivatives',
                'An antiderivative reverses differentiation.',
                'If F\'(x)=f(x), then F is an antiderivative of f',
                'An antiderivative of 2x is x^2 + C.',
                'Find an antiderivative of 3x^2.',
                'x^3 + C', [
              'Use the reverse power rule.',
              'Increase the exponent to 3 and divide by 3.',
              'An antiderivative is x^3 + C.'
            ]),
            _concept(
                'indefinite_integrals',
                'Indefinite Integrals',
                'An indefinite integral represents a family of antiderivatives.',
                '∫ f(x) dx = F(x) + C',
                '∫ 2x dx = x^2 + C.',
                'Find ∫ 4x dx.',
                '2x^2 + C', [
              'Use the power rule for integration.',
              '4 * x^2/2 = 2x^2.',
              'Add C to get 2x^2 + C.'
            ]),
            _concept(
                'definite_integrals',
                'Definite Integrals',
                'A definite integral gives net accumulation over an interval.',
                '∫_a^b f(x) dx = F(b)-F(a)',
                '∫_0^2 x dx = 2.',
                'Evaluate ∫ from 0 to 3 of 2 dx.',
                '6', [
              'The function 2 is constant.',
              'Area is height times width: 2 * 3.',
              'The definite integral is 6.'
            ]),
            _concept(
                'fundamental_theorem_of_calculus',
                'Fundamental Theorem of Calculus',
                'The Fundamental Theorem connects derivatives and definite integrals.',
                '∫_a^b f(x)dx = F(b)-F(a)',
                'If F\'=f, use F(b)-F(a) to evaluate the integral.',
                'If F(x)=x^2, find F(3)-F(1).',
                '8',
                ['Compute F(3)=9.', 'Compute F(1)=1.', 'Subtract 9 - 1 = 8.']),
          ]),
          _lesson(
              'areas_and_substitution', 'Areas and Substitution', '10 min', [
            _concept(
                'area_under_a_curve',
                'Area Under a Curve',
                'A definite integral can represent area under a curve above the x-axis.',
                'Area = ∫_a^b f(x) dx',
                'Area under y=2 from 0 to 3 is 6.',
                'Find the area under y = 4 from x = 0 to x = 5.',
                '20', [
              'The graph is a rectangle.',
              'Area = height times width = 4 * 5.',
              'The area is 20.'
            ]),
            _concept(
                'area_between_curves',
                'Area Between Curves',
                'Area between curves is found by integrating top function minus bottom function.',
                'Area = ∫(top - bottom) dx',
                'Between y=5 and y=2 from 0 to 4, area is 12.',
                'Find the area between y=6 and y=2 from x=0 to x=3.',
                '12', [
              'Subtract top minus bottom: 6 - 2 = 4.',
              'Multiply by the interval width 3.',
              'The area is 12.'
            ]),
            _concept(
                'basic_substitution',
                'Basic Substitution',
                'Substitution rewrites an integral using a simpler inner expression.',
                'Let u = inner expression',
                'For ∫2x(x^2+1) dx, let u=x^2+1.',
                'For ∫3(x+1)^2 dx, what substitution is natural?',
                'u = x + 1', [
              'Look for the inner expression.',
              'The repeated inner expression is x + 1.',
              'Use u = x + 1.'
            ]),
          ]),
        ]),
      ],
    ),
  ];
}
