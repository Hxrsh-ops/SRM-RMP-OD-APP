import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srm_rmp_od_frontend/core/ui/layout/app_bottom_nav_bar.dart';

void main() {
  group('Milestone 6.3.1 - Role-Aware Bottom Navigation Unit & Widget Tests', () {
    testWidgets('1. Role-aware Bottom Navigation hides Create button for Faculty Advisor', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNavBar(
              currentIndex: 0,
              onTap: (_) {},
              role: 'FACULTY_ADVISOR',
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Create'), findsNothing);
    });

    testWidgets('2. Role-aware Bottom Navigation displays 5 tabs including Create for Student', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNavBar(
              currentIndex: 0,
              onTap: (_) {},
              role: 'STUDENT',
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('My Requests'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('3. Role-aware Bottom Navigation displays Approval Queue for Coordinator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNavBar(
              currentIndex: 0,
              onTap: (_) {},
              role: 'COORDINATOR',
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Approval Queue'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Create'), findsNothing);
    });
  });
}
