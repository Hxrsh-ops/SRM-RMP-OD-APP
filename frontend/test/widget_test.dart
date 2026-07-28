import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:srm_rmp_od_frontend/core/network/providers/dio_provider.dart';
import 'package:srm_rmp_od_frontend/core/services/storage_service.dart';
import 'package:srm_rmp_od_frontend/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('SrmRmpOdApp mounts successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          useApiRepositoryProvider.overrideWith((ref) => false),
        ],
        child: const SrmRmpOdApp(),
      ),
    );

    expect(find.byType(SrmRmpOdApp), findsOneWidget);
  });
}
