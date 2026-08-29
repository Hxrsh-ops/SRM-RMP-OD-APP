import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srm_rmp_od_frontend/features/authentication/presentation/screens/login_screen.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('Renders the UI Kit login screen and form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Register Number / Employee ID / Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });
  });
}
