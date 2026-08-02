import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:srm_rmp_od_frontend/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('SrmRmpOdApp mounts successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: SrmRmpOdApp(),
      ),
    );

    expect(find.byType(SrmRmpOdApp), findsOneWidget);
  });
}
