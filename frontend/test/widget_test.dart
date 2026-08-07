import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:srm_rmp_od_frontend/main.dart';

void main() {
  testWidgets('SrmRmpOdApp mounts successfully', (WidgetTester tester) async {

    await tester.pumpWidget(
      const ProviderScope(
        child: SrmRmpOdApp(),
      ),
    );

    expect(find.byType(SrmRmpOdApp), findsOneWidget);
  });
}
