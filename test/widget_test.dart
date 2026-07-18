import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bill_split/app/app.dart';
import 'package:bill_split/core/constants/app_const.dart';
import 'package:bill_split/features/auth/presentation/screens/login_screen.dart';
import 'package:bill_split/features/splash/presentation/screens/splash_screen.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  group('SplashScreen', () {
    testWidgets('shows branding then navigates to the login screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(const BillSplitApp());

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
      await tester.pumpWidget(_wrap(const LoginScreen()));

      expect(find.text('BillSplit'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('shows validation errors when submitting an empty form',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('rejects malformed email and short password',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'not-an-email');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), '123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(
          find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('toggles between sign-in and registration modes',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));

      await tester.tap(find.text("Don't have an account? Sign up"));
      await tester.pump();

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Already have an account? Sign in'), findsOneWidget);
    });
  });
}
