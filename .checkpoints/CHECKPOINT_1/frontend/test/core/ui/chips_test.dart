import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srm_rmp_od_frontend/core/ui/chips/app_status_chip.dart';

void main() {
  group('Design System Chips Tests', () {
    testWidgets('AppStatusChip renders label correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppStatusChip(
              label: 'Approved',
              statusType: AppStatusType.approved,
            ),
          ),
        ),
      );

      expect(find.text('Approved'), findsOneWidget);
    });
  });
}
