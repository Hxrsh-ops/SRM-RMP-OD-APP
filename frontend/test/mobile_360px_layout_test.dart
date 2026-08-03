import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srm_rmp_od_frontend/core/ui/layout/app_top_header.dart';
import 'package:srm_rmp_od_frontend/features/dashboard/presentation/views/shared_dashboard_widgets.dart';

void main() {
  testWidgets('AppTopHeader consumes top inset cleanly at 360px width', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(94.0),
            child: AppTopHeader(
              userName: 'K.M. Harshanth',
              userSubtext: 'B.Tech CSE',
              onNotificationTap: () {},
              onProfileTap: () {},
            ),
          ),
          body: const Center(child: Text('Body Content')),
        ),
      ),
    );

    expect(find.text('SRM RMP OD Platform'), findsOneWidget);
    expect(find.text('On Duty Approval Workflow'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ProfileDetailRow displays vertically on 360px without text truncation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProfileDetailRow(
              label: 'Institutional Department',
              value: 'Department of Computer Science & Engineering (Artificial Intelligence and Machine Learning)',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Institutional Department'), findsOneWidget);
    expect(find.text('Department of Computer Science & Engineering (Artificial Intelligence and Machine Learning)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
