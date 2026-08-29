import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srm_rmp_od_frontend/core/ui/inputs/app_password_field.dart';
import 'package:srm_rmp_od_frontend/core/ui/inputs/app_text_field.dart';

void main() {
  group('Design System Inputs Tests', () {
    testWidgets('AppTextField accepts input text', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              labelText: 'Username',
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.text('Username'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'John Doe');
      expect(controller.text, 'John Doe');
    });

    testWidgets('AppPasswordField toggles text visibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppPasswordField(),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.visibility_outlined);
      expect(iconFinder, findsOneWidget);

      await tester.tap(iconFinder);
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });
}
