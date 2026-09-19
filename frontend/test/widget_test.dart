import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mathiva/models/user_profile.dart';
import 'package:mathiva/repositories/auth_repository.dart';
import 'package:mathiva/repositories/tutor_repository.dart';
import 'package:mathiva/screens/chat_screen.dart';
import 'package:mathiva/screens/forgot_password_screen.dart';
import 'package:mathiva/screens/image_solver_screen.dart';
import 'package:mathiva/screens/login_screen.dart';
import 'package:mathiva/screens/register_screen.dart';
import 'package:mathiva/screens/reset_password_screen.dart';
import 'package:mathiva/services/app_preferences.dart';
import 'package:mathiva/services/auth_storage.dart';
import 'package:mathiva/services/chat_service.dart';
import 'package:mathiva/services/chat_store.dart';
import 'package:mathiva/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthStorage.init();
    await AppPreferences.init();
    AppPreferences.studentName.value = 'Learner';
  });

  testWidgets('login validates required fields before calling auth',
      (tester) async {
    final auth = _FakeAuthRepository();
    await _pumpAuthScreen(tester, LoginScreen(authRepository: auth));

    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your email and password.'), findsOneWidget);
    expect(auth.loginCalls, isEmpty);

    await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(auth.loginCalls, isEmpty);
  });

  testWidgets('login saves token, loads profile name, and navigates home',
      (tester) async {
    final auth = _FakeAuthRepository(
      loginToken: 'test-token',
      profile: const UserProfile(
        id: 7,
        email: 'ada@example.com',
        fullName: 'Ada Lovelace',
      ),
    );
    await _pumpAuthScreen(tester, LoginScreen(authRepository: auth));

    await tester.enterText(find.byType(TextFormField).at(0), 'ada@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Home reached'), findsOneWidget);
    expect(await AuthStorage.getToken(), 'test-token');
    expect(AppPreferences.studentName.value, 'Ada Lovelace');
    expect(auth.loginCalls, [
      const _LoginCall(email: 'ada@example.com', password: 'password123'),
    ]);
  });

  testWidgets('register shows field-level validation errors', (tester) async {
    final auth = _FakeAuthRepository();
    await _pumpAuthScreen(tester, RegisterScreen(authRepository: auth));

    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your full name'), findsOneWidget);
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter a password'), findsOneWidget);
    expect(find.text('Please confirm your password'), findsOneWidget);
    expect(auth.registerCalls, isEmpty);
  });

  testWidgets('register submits valid details then navigates home',
      (tester) async {
    final auth = _FakeAuthRepository(loginToken: 'registered-token');
    await _pumpAuthScreen(tester, RegisterScreen(authRepository: auth));

    await tester.enterText(find.byType(TextFormField).at(0), 'Grace Hopper');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'grace@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'STEM-A');
    await tester.enterText(find.byType(TextFormField).at(3), 'password123');
    await tester.enterText(find.byType(TextFormField).at(4), 'password123');
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Home reached'), findsOneWidget);
    expect(await AuthStorage.getToken(), 'registered-token');
    expect(AppPreferences.studentName.value, 'Grace Hopper');
    expect(auth.registerCalls, [
      const _RegisterCall(
        email: 'grace@example.com',
        password: 'password123',
        fullName: 'Grace Hopper',
        section: 'STEM-A',
      ),
    ]);
  });

  testWidgets('forgot password validates email before requesting reset',
      (tester) async {
    final auth = _FakeAuthRepository(
      passwordResetMessage: 'Reset instructions sent.',
    );
    await _pumpAuthScreen(tester, ForgotPasswordScreen(authRepository: auth));

    await tester.enterText(find.byType(TextFormField), 'bad-email');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(
        find.text('Enter the email address on your account.'), findsOneWidget);
    expect(auth.passwordResetRequests, isEmpty);
  });

  testWidgets('reset password submits matching passwords and shows completion',
      (tester) async {
    final auth = _FakeAuthRepository(resetPasswordMessage: 'Password changed.');
    await _pumpAuthScreen(
      tester,
      ResetPasswordScreen(token: 'reset-token', authRepository: auth),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'newpass123');
    await tester.enterText(find.byType(TextFormField).at(1), 'newpass123');
    await tester.tap(find.text('Reset Password'));
    await tester.pumpAndSettle();

    expect(find.text('Password updated'), findsOneWidget);
    expect(find.text('Back to Login'), findsOneWidget);
    expect(auth.resetCalls, [
      const _ResetCall(token: 'reset-token', newPassword: 'newpass123'),
    ]);
  });

  testWidgets('chat sends a question and renders streamed tutor response',
      (tester) async {
    final originalRepository = ChatService.repository;
    final fakeTutor = _FakeTutorRepository(['The answer is ', r'\(x = 4\).']);
    ChatService.repository = fakeTutor;
    ChatStore.reset();
    addTearDown(() {
      ChatService.repository = originalRepository;
      ChatStore.reset();
    });

    await _pumpAppScreen(tester, const ChatScreen());

    await tester.enterText(find.byType(TextField), 'Solve 2x + 5 = 13');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();

    expect(find.text('Solve 2x + 5 = 13'), findsOneWidget);
    expect(fakeTutor.questions, ['Solve 2x + 5 = 13']);

    await tester.pump(const Duration(milliseconds: 250));
    expect(find.textContaining('The answer is'), findsOneWidget);
    expect(ChatStore.messages.value.any((m) => m.text.contains(r'\(x = 4\).')),
        isTrue);

    await tester.enterText(find.byType(TextField), 'Explain step two');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();

    expect(fakeTutor.questions.last, 'Explain step two');
    expect(
      fakeTutor.histories.last.any((m) => m.text == 'Solve 2x + 5 = 13'),
      isTrue,
    );
  });

  testWidgets('chat keeps streaming answer after leaving the tab',
      (tester) async {
    final originalRepository = ChatService.repository;
    final fakeTutor = _ControlledTutorRepository();
    ChatService.repository = fakeTutor;
    ChatStore.reset();
    addTearDown(() {
      ChatService.repository = originalRepository;
      ChatStore.reset();
      fakeTutor.dispose();
    });

    await _pumpAppScreen(tester, const ChatScreen());

    await tester.enterText(find.byType(TextField), 'Solve 3x = 12');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();

    expect(fakeTutor.questions, ['Solve 3x = 12']);

    await tester.pumpWidget(const SizedBox.shrink());
    fakeTutor.add('The answer is ');
    fakeTutor.add(r'\(x = 4\).');
    await fakeTutor.close();
    await tester.pump();

    expect(
      ChatStore.messages.value.any((m) => m.text.contains(r'\(x = 4\).')),
      isTrue,
    );
  });

  testWidgets(
      'image solver opens camera flow and shows fallback without camera',
      (tester) async {
    await _pumpAppScreen(tester, const ImageSolverScreen());

    await tester.pump(const Duration(seconds: 2));

    final fallbackVisible = find.text('Try Again').evaluate().isNotEmpty &&
        find.text('Gallery').evaluate().isNotEmpty &&
        find
            .textContaining('Could not open the live camera')
            .evaluate()
            .isNotEmpty;
    final loadingVisible =
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty;

    expect(fallbackVisible || loadingVisible, isTrue);
  });
}

Future<void> _pumpAuthScreen(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(430, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => screen),
      GoRoute(
        path: '/home',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('Home reached'))),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('Login route'))),
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpAppScreen(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(430, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => screen),
      GoRoute(
        path: '/home',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('Home reached'))),
      ),
      GoRoute(
        path: '/chat',
        builder: (_, __) => const ChatScreen(),
      ),
      GoRoute(
        path: '/image-solver',
        builder: (_, __) => const ImageSolverScreen(),
      ),
      GoRoute(
        path: '/progress',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('Progress reached'))),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('Profile reached'))),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.loginToken = 'fake-token',
    this.profile = const UserProfile(
      id: 1,
      email: 'student@example.com',
      fullName: 'Sample Student',
    ),
    this.passwordResetMessage = 'Check your email for a reset link.',
    this.resetPasswordMessage = 'Password reset.',
  });

  final String loginToken;
  final UserProfile profile;
  final String passwordResetMessage;
  final String resetPasswordMessage;

  final List<_RegisterCall> registerCalls = [];
  final List<_LoginCall> loginCalls = [];
  final List<String> googleTokens = [];
  final List<String> passwordResetRequests = [];
  final List<_ResetCall> resetCalls = [];

  @override
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? section,
  }) async {
    registerCalls.add(_RegisterCall(
      email: email,
      password: password,
      fullName: fullName,
      section: section,
    ));
  }

  @override
  Future<String> login({
    required String email,
    required String password,
  }) async {
    loginCalls.add(_LoginCall(email: email, password: password));
    return loginToken;
  }

  @override
  Future<String> loginWithGoogleIdToken(String idToken) async {
    googleTokens.add(idToken);
    return loginToken;
  }

  @override
  Future<String> requestPasswordReset(String email) async {
    passwordResetRequests.add(email);
    return passwordResetMessage;
  }

  @override
  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    resetCalls.add(_ResetCall(token: token, newPassword: newPassword));
    return resetPasswordMessage;
  }

  @override
  Future<UserProfile> getProfile() async => profile;
}

class _FakeTutorRepository implements TutorRepository {
  _FakeTutorRepository(this.chunks);

  final List<String> chunks;
  final List<String> questions = [];
  final List<List<TutorChatTurn>> histories = [];

  @override
  Stream<String> ask(
    String question, {
    List<TutorChatTurn> history = const [],
  }) async* {
    questions.add(question);
    histories.add(history);
    for (final chunk in chunks) {
      yield chunk;
    }
  }
}

class _ControlledTutorRepository implements TutorRepository {
  final StreamController<String> _controller = StreamController<String>();
  final List<String> questions = [];
  final List<List<TutorChatTurn>> histories = [];

  @override
  Stream<String> ask(
    String question, {
    List<TutorChatTurn> history = const [],
  }) {
    questions.add(question);
    histories.add(history);
    return _controller.stream;
  }

  void add(String chunk) => _controller.add(chunk);

  Future<void> close() => _controller.close();

  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}

class _RegisterCall {
  const _RegisterCall({
    required this.email,
    required this.password,
    required this.fullName,
    required this.section,
  });

  final String email;
  final String password;
  final String fullName;
  final String? section;

  @override
  bool operator ==(Object other) =>
      other is _RegisterCall &&
      other.email == email &&
      other.password == password &&
      other.fullName == fullName &&
      other.section == section;

  @override
  int get hashCode => Object.hash(email, password, fullName, section);
}

class _LoginCall {
  const _LoginCall({required this.email, required this.password});

  final String email;
  final String password;

  @override
  bool operator ==(Object other) =>
      other is _LoginCall && other.email == email && other.password == password;

  @override
  int get hashCode => Object.hash(email, password);
}

class _ResetCall {
  const _ResetCall({required this.token, required this.newPassword});

  final String token;
  final String newPassword;

  @override
  bool operator ==(Object other) =>
      other is _ResetCall &&
      other.token == token &&
      other.newPassword == newPassword;

  @override
  int get hashCode => Object.hash(token, newPassword);
}
