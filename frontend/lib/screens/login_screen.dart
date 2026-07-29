import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants/api_constants.dart';
import '../repositories/api/api_auth_repository.dart';
import '../repositories/auth_repository.dart';
import '../services/app_preferences.dart';
import '../services/auth_storage.dart';
import '../services/google_sign_in_web_button.dart'
    if (dart.library.js_util) '../services/google_sign_in_web_button_web.dart';
import '../utils/route_names.dart';
import '../presentation/widgets/auth_widgets.dart';
import '../presentation/widgets/fade_slide_in.dart';
import '../theme/app_theme.dart';

/// Login — a graph-paper editorial brand band over a left-aligned form, per the
/// auth-flow "mathematical notebook" design handoff.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static Future<void>? _googleInitialization;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthRepository _authRepository = ApiAuthRepository();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _googleReady = false;
  String? _error;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleSub;

  @override
  void initState() {
    super.initState();
    unawaited(_initGoogleSignIn());
  }

  @override
  void dispose() {
    _googleSub?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token =
          await _authRepository.login(email: email, password: password);
      await AuthStorage.saveToken(token);
      // Pull the student's profile so the home greeting shows their real name
      // instead of the default. Non-fatal: a /auth/me hiccup shouldn't block
      // an otherwise-successful login -- the greeting just falls back.
      await _loadProfileName();
      if (!mounted) return;
      context.go(RouteNames.home);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is AuthException
          ? e.message
          : 'Could not log in. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _initGoogleSignIn() async {
    if (kGoogleClientId.isEmpty) return;

    final signIn = GoogleSignIn.instance;
    try {
      _googleInitialization ??= signIn.initialize(
          clientId: kIsWeb ? kGoogleClientId : null,
          serverClientId: kGoogleServerClientId.isNotEmpty
              ? kGoogleServerClientId
              : kGoogleClientId);
      await _googleInitialization;
      _googleSub = signIn.authenticationEvents
          .listen(_handleGoogleAuthEvent, onError: _handleGoogleAuthError);
      signIn.attemptLightweightAuthentication();
      if (mounted) setState(() => _googleReady = true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _googleReady = false;
          _error = 'Google sign-in is not available right now.';
        });
      }
    }
  }

  Future<void> _handleGoogleAuthEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn():
        await _finishGoogleLogin(event.user);
      case GoogleSignInAuthenticationEventSignOut():
        break;
    }
  }

  void _handleGoogleAuthError(Object error) {
    if (!mounted) return;
    setState(() {
      _isGoogleLoading = false;
      _error = error is GoogleSignInException
          ? _googleMessageFor(error)
          : 'Could not sign in with Google.';
    });
  }

  Future<void> _handleGoogleSignInPressed() async {
    if (!_googleReady || _isLoading || _isGoogleLoading) return;

    setState(() {
      _isGoogleLoading = true;
      _error = null;
    });

    try {
      final account = await GoogleSignIn.instance.authenticate();
      await _finishGoogleLogin(account);
    } on GoogleSignInException catch (e) {
      if (!mounted) return;
      setState(() {
        _isGoogleLoading = false;
        _error = _googleMessageFor(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isGoogleLoading = false;
        _error = 'Could not sign in with Google.';
      });
    }
  }

  Future<void> _finishGoogleLogin(GoogleSignInAccount account) async {
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isGoogleLoading = false;
        _error = 'Google did not return a usable sign-in token.';
      });
      return;
    }

    setState(() {
      _isGoogleLoading = true;
      _error = null;
    });

    try {
      final token = await _authRepository.loginWithGoogleIdToken(idToken);
      await AuthStorage.saveToken(token);
      await _loadProfileName();
      if (!mounted) return;
      context.go(RouteNames.home);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error =
          e is AuthException ? e.message : 'Could not sign in with Google.');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  String _googleMessageFor(GoogleSignInException e) {
    if (e.code == GoogleSignInExceptionCode.canceled ||
        e.code == GoogleSignInExceptionCode.interrupted) {
      return 'Google sign-in was cancelled.';
    }
    if (e.code == GoogleSignInExceptionCode.uiUnavailable) {
      return 'Google sign-in is not available on this device.';
    }
    return 'Could not sign in with Google.';
  }

  /// Fetches the profile and pushes the student's name into [AppPreferences]
  /// so the home greeting picks it up. Best-effort -- any failure is swallowed
  /// so it can never block navigation to home after a valid login.
  Future<void> _loadProfileName() async {
    try {
      final profile = await _authRepository.getProfile();
      AppPreferences.studentName.value = profile.fullName;
    } catch (_) {
      // Leave the greeting on its default name.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Scaffold(
      backgroundColor: colors.pageBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthBrandBand(tagline: 'Your step-by-step math tutor.'),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
                children: [
                  FadeSlideIn(
                    child: Text(
                      'Welcome back',
                      style: GoogleFonts.fraunces(
                        color: colors.ink,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 70),
                    child: Text(
                      'Log in to keep growing your math skills.',
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: AuthField(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 150),
                    child: AuthField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 4),
                    AuthErrorBanner(message: _error!),
                    const SizedBox(height: 16),
                  ] else
                    const SizedBox(height: 10),
                  AuthPrimaryButton(
                    label: 'Log In',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handleLogin,
                  ),
                  const SizedBox(height: 20),
                  const _DividerOr(),
                  const SizedBox(height: 20),
                  _GoogleSignInSection(
                    enabled: _googleReady && !_isLoading && !_isGoogleLoading,
                    isLoading: _isGoogleLoading,
                    onPressed: _handleGoogleSignInPressed,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'New to Mathiva? ',
                        style: TextStyle(
                          color: colors.muted,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => context.push(RouteNames.register),
                        child: Text(
                          'Sign up',
                          style: TextStyle(
                            color: colors.accent,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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

// ─── Google Button ────────────────────────────────────────────────────────────

class _GoogleSignInSection extends StatelessWidget {
  final bool enabled;
  final bool isLoading;
  final VoidCallback onPressed;
  const _GoogleSignInSection({
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (kGoogleClientId.isEmpty) {
      return const SizedBox.shrink();
    }

    if (kIsWeb) {
      return AbsorbPointer(
        absorbing: !enabled,
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: Center(child: googleSignInWebButton()),
          ),
        ),
      );
    }

    return _GoogleButton(
      onPressed: enabled ? onPressed : null,
      isLoading: isLoading,
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  const _GoogleButton({
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.surface,
          foregroundColor: colors.ink,
          side: BorderSide(color: colors.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          elevation: 0,
        ),
        icon: Image.asset(
          'assets/google.png',
          height: 18,
          width: 18,
          fit: BoxFit.contain,
        ),
        label: Text(
          isLoading ? 'Signing in...' : 'Continue with Google',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }
}

// ─── Divider ──────────────────────────────────────────────────────────────────

class _DividerOr extends StatelessWidget {
  const _DividerOr();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Row(
      children: [
        Expanded(child: Divider(color: colors.border, height: 1, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(
              color: colors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: colors.border, height: 1, thickness: 1)),
      ],
    );
  }
}
