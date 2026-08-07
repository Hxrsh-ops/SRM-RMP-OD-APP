import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../lib/features/admin/presentation/views/admin_dashboard_view.dart';
import '../../../lib/features/admin/domain/models/admin_models.dart';
import '../../../lib/features/admin/presentation/controllers/admin_controller.dart';

void main() {
  testWidgets('AdminDashboardView renders executive metrics correctly', (WidgetTester tester) async {
    final mockMetrics = AdminDashboardMetrics(
      totalUsers: 150,
      studentsCount: 120,
      facultyCount: 20,
      coordinatorsCount: 8,
      departmentsCount: 2,
      totalOdRequests: 45,
      pendingRequests: 10,
      completedRequests: 30,
      rejectedRequests: 5,
      evidencePendingRequests: 3,
      todayRequests: 4,
      requestsThisWeek: 18,
      requestsThisMonth: 45,
      approvalRate: 85.5,
      avgProcessingTimeHours: 4.2,
      mostActiveDepartment: 'CSE Department',
      mostActiveFaculty: 'Dr. Karthik B',
      storageUsageMb: 120.5,
      dailyLoginCount: 50,
      activeSessions: 12,
      recentActivity: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminDashboardProvider.overrideWith((ref) async => mockMetrics),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AdminDashboardView(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Executive Control Center'), findsOneWidget);
    expect(find.text('Total Registered Users'), findsOneWidget);
    expect(find.text('150'), findsOneWidget);
    expect(find.text('85.5%'), findsOneWidget);
  });
}
