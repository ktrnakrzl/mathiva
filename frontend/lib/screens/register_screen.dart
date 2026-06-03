import 'package:flutter/material.dart';

import '../utils/route_names.dart';
import '../widgets/app_header.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/mathiva_logo.dart';
import '../widgets/section_card.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            const AppHeader(title: 'Create Account', subtitle: 'Start your Mathivia review journey'),
            const SizedBox(height: 18),
            const MathivaLogo(size: 70),
            const SizedBox(height: 24),
            SectionCard(
              child: Column(
                children: [
                  const TextField(decoration: InputDecoration(prefixIcon: Icon(Icons.person_rounded), hintText: 'Username')),
                  const SizedBox(height: 12),
                  const TextField(decoration: InputDecoration(prefixIcon: Icon(Icons.email_rounded), hintText: 'Email')),
                  const SizedBox(height: 12),
                  const TextField(obscureText: true, decoration: InputDecoration(prefixIcon: Icon(Icons.lock_rounded), hintText: 'Password')),
                  const SizedBox(height: 12),
                  const TextField(obscureText: true, decoration: InputDecoration(prefixIcon: Icon(Icons.verified_user_rounded), hintText: 'Confirm Password')),
                  const SizedBox(height: 18),
                  GradientButton(label: 'Create Account', onPressed: () => Navigator.pushReplacementNamed(context, RouteNames.home)),
                  const SizedBox(height: 10),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Already have an account? Login')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
