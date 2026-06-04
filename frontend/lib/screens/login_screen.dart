import 'package:flutter/material.dart';
import '../services/app_preferences.dart';

import '../theme/app_theme.dart';
import '../utils/route_names.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/mathiva_logo.dart';
import '../widgets/section_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool rememberMe = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            const SizedBox(height: 34),
            const MathivaLogo(),
            const SizedBox(height: 34),
            SectionCard(
              child: Column(
                children: [
                  const TextField(decoration: InputDecoration(prefixIcon: Icon(Icons.email_rounded, size: 18), hintText: 'Email')),
                  const SizedBox(height: 12),
                  const TextField(obscureText: true, decoration: InputDecoration(prefixIcon: Icon(Icons.lock_rounded, size: 18), hintText: 'Password')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(value: rememberMe, onChanged: (value) => setState(() => rememberMe = value ?? true), activeColor: Theme.of(context).colorScheme.primary),
                      const Text('Remember me', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      const Spacer(),
                      TextButton(onPressed: () {}, child: const Text('Forgot password?', style: TextStyle(fontSize: 12))),
                    ],
                  ),
                  GradientButton(
                    label: 'Login',
                    onPressed: () => Navigator.pushReplacementNamed(context, RouteNames.home),
                  ),
                  const SizedBox(height: 16),
                  const Text('or continue with', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushReplacementNamed(context, RouteNames.home),
                    icon: Text('G', style: TextStyle(fontWeight: FontWeight.w900, color: AppPreferences.palette.value.secondary)),
                    label: const Text('Google'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account yet?", style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      TextButton(onPressed: () => Navigator.pushNamed(context, RouteNames.register), child: const Text('Sign up now', style: TextStyle(fontSize: 12))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
