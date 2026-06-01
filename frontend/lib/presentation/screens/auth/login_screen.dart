import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mathiva/presentation/notifiers/auth_notifier.dart';
import 'package:mathiva/presentation/widgets/loading_overlay.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'student@mathiva.ph');
  final _passwordController = TextEditingController(text: 'password');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (previous, next) {
      next.whenOrNull(data: (user) {
        if (user != null) context.go('/home');
      });
    });

    final authState = ref.watch(authNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mathiva Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: authState.when(
          data: (_) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Welcome to Mathiva', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => ref.read(authNotifierProvider.notifier).login(_emailController.text, _passwordController.text),
                child: const Text('Login'),
              ),
            ],
          ),
          loading: () => const LoadingOverlay(),
          error: (error, _) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(authNotifierProvider.notifier).login(_emailController.text, _passwordController.text),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
