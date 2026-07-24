import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bill_split/app/app.dart';
import 'package:bill_split/core/constants/app_const.dart';
import 'package:bill_split/core/models/friend.dart';
import 'package:bill_split/features/auth/data/services/auth_service.dart';
import 'package:bill_split/features/auth/presentation/providers/auth_provider.dart';
import 'package:bill_split/features/auth/presentation/screens/login_screen.dart';
import 'package:bill_split/features/friends/domain/repositories/friends_repository.dart';
import 'package:bill_split/features/friends/presentation/screens/friends_screen.dart';
import 'package:bill_split/features/splash/presentation/screens/splash_screen.dart';

/// Auth service stand-in so widget tests never touch Firebase.
class FakeAuthService implements AuthService {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => Stream<User?>.value(null);

  @override
  Future<void> signInWithEmail(String email, String password) async {}

  @override
  Future<void> registerWithEmail(String email, String password) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<bool> signInWithGoogle() async => false;

  @override
  Future<void> signOut() async {}
}

/// In-memory friends store, so the screen can be driven without Firestore.
class FakeFriendsRepository implements FriendsRepository {
  FakeFriendsRepository(this._friends);

  final List<Friend> _friends;

  @override
  Stream<List<Friend>> watchFriends() => Stream<List<Friend>>.value(_friends);

  @override
  Future<void> addFriend(Friend friend) async => _friends.add(friend);

  @override
  Future<void> updateFriend(Friend friend) async {}

  @override
  Future<void> deleteFriend(String id) async =>
      _friends.removeWhere((f) => f.id == id);
}

Widget _wrapLogin() {
  return MultiProvider(
    providers: buildAuthProviders(FakeAuthService()),
    child: const MaterialApp(home: LoginScreen()),
  );
}

/// Registers the fake against the *interface*, exactly how
/// `buildRepositoryProviders` registers the Firestore implementation in
/// production — which is what makes this screen testable at all.
Widget _wrapFriends(FriendsRepository repository) {
  return Provider<FriendsRepository?>.value(
    value: repository,
    child: const MaterialApp(home: FriendsScreen()),
  );
}

void main() {
  group('SplashScreen', () {
    testWidgets('shows branding then navigates to the login screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(BillSplitApp(authService: FakeAuthService()));

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text(AppConstants.tagline), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      await tester.pump(AppConstants.splashMinDuration);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    });
  });

  group('LoginScreen', () {
    testWidgets('renders branding, email form and sign-in options',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapLogin());

      expect(find.text('BillSplit'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('shows validation errors when submitting an empty form',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapLogin());

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('rejects malformed email and short password',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapLogin());

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'not-an-email');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), '123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(
          find.text('Password must be at least 8 characters'), findsOneWidget);
    });

    testWidgets(
        'registration mode shows confirm password field and mode toggle',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapLogin());

      expect(
          find.widgetWithText(TextFormField, 'Confirm Password'), findsNothing);

      await tester.ensureVisible(find.text('Sign up'));
      await tester.tap(find.text('Sign up'));
      await tester.pump();

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Confirm Password'),
          findsOneWidget);
      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('rejects mismatched passwords during registration',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapLogin());

      await tester.ensureVisible(find.text('Sign up'));
      await tester.tap(find.text('Sign up'));
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'secret123');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'), 'secret124');

      await tester.ensureVisible(find.text('Create Account'));
      await tester.tap(find.text('Create Account'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });

  group('FriendsScreen with an injected repository', () {
    final List<Friend> friends = const [
      Friend(id: 'a', name: 'Asha', upiId: 'asha@upi'),
      Friend(id: 'b', name: 'Bala'),
      Friend(id: 'c', name: 'Chitra'),
    ];

    testWidgets('renders the friends supplied by the repository',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          _wrapFriends(FakeFriendsRepository(List<Friend>.of(friends))));
      await tester.pumpAndSettle();

      expect(find.text('Asha'), findsOneWidget);
      expect(find.text('Bala'), findsOneWidget);
      expect(find.text('Chitra'), findsOneWidget);
    });

    testWidgets('shows the empty state when the repository has no friends',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapFriends(FakeFriendsRepository(<Friend>[])));
      await tester.pumpAndSettle();

      expect(find.text('No friends yet'), findsOneWidget);
    });

    testWidgets('filters the list as the search query changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          _wrapFriends(FakeFriendsRepository(List<Friend>.of(friends))));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'ash');
      await tester.pumpAndSettle();

      expect(find.text('Asha'), findsOneWidget);
      expect(find.text('Bala'), findsNothing);
      expect(find.text('Chitra'), findsNothing);
    });
  });
}
