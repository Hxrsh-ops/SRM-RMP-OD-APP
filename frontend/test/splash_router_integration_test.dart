import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srm_rmp_od_frontend/core/constants/app_constants.dart';
import 'package:srm_rmp_od_frontend/core/routing/app_router.dart';
import 'package:srm_rmp_od_frontend/core/security/memory_secure_storage.dart';
import 'package:srm_rmp_od_frontend/core/network/providers/dio_provider.dart';
import 'package:srm_rmp_od_frontend/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:srm_rmp_od_frontend/features/authentication/data/repositories/mock_authentication_repository.dart';
import 'package:srm_rmp_od_frontend/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:srm_rmp_od_frontend/features/authentication/domain/entities/auth_status.dart';
import 'package:srm_rmp_od_frontend/features/authentication/domain/entities/user_session.dart';
import 'package:srm_rmp_od_frontend/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:srm_rmp_od_frontend/features/od_workflow/data/repositories/mock_workflow_repository.dart';
import 'package:srm_rmp_od_frontend/features/od_workflow/presentation/controllers/workflow_controller.dart';

class FailingAuthRepository implements AuthenticationRepository {
  @override
  Future<UserSession> login({required String username, required String password}) async {
    throw Exception('Backend unreachable');
  }

  @override
  Future<UserSession?> restoreSession() async {
    throw Exception('Backend unreachable');
  }

  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<void> logout() async {}
}

class PendingAuthRepository implements AuthenticationRepository {
  final Completer<UserSession?> completer;
  PendingAuthRepository(this.completer);

  @override
  Future<UserSession> login({required String username, required String password}) async {
    return completer.future.then((s) => s!);
  }

  @override
  Future<UserSession?> restoreSession() async {
    return completer.future;
  }

  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<void> logout() async {}
}

void main() {
  group('Splash Screen & GoRouter Navigation Integration Tests', () {
    late MemorySecureStorage memoryStorage;

    setUp(() {
      memoryStorage = MemorySecureStorage();
    });

    testWidgets('1. Initial/Restoring state keeps location on Splash', (WidgetTester tester) async {
      final completer = Completer<UserSession?>();
      final pendingRepo = PendingAuthRepository(completer);

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(memoryStorage),
          authenticationRepositoryProvider.overrideWithValue(pendingRepo),
        ],
      );

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pump();
      expect(container.read(authControllerProvider).status, AuthStatus.initial);
      expect(router.routerDelegate.currentConfiguration.matches.last.matchedLocation, AppConstants.splashRoute);

      completer.complete(null);
      await tester.pumpAndSettle();
    });

    testWidgets('2. No stored token routes from Splash to Login', (WidgetTester tester) async {
      final localDataSource = AuthLocalDataSource(memoryStorage);
      final mockRepo = MockAuthenticationRepository(localDataSource: localDataSource);

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(memoryStorage),
          authenticationRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(container.read(authControllerProvider).status, AuthStatus.unauthenticated);
      expect(router.routerDelegate.currentConfiguration.matches.last.matchedLocation, AppConstants.loginRoute);
    });

    testWidgets('3. Valid stored token routes from Splash to Dashboard', (WidgetTester tester) async {
      final localDataSource = AuthLocalDataSource(memoryStorage);
      final mockRepo = MockAuthenticationRepository(localDataSource: localDataSource);
      final mockWorkflow = MockWorkflowRepository();

      await mockRepo.login(username: 'RA2511026020400', password: 'student123');

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(memoryStorage),
          authenticationRepositoryProvider.overrideWithValue(mockRepo),
          workflowRepositoryProvider.overrideWithValue(mockWorkflow),
        ],
      );

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(container.read(authControllerProvider).status, AuthStatus.authenticated);
      expect(router.routerDelegate.currentConfiguration.matches.last.matchedLocation, '/dashboard');
    });

    testWidgets('4. Expired or invalid token clears storage and routes to Login', (WidgetTester tester) async {
      final localDataSource = AuthLocalDataSource(memoryStorage);
      final mockRepo = MockAuthenticationRepository(localDataSource: localDataSource);

      await memoryStorage.write(key: 'jwt_access_token', value: 'invalid_expired_jwt_token');

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(memoryStorage),
          authenticationRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(container.read(authControllerProvider).status, AuthStatus.unauthenticated);
      expect(router.routerDelegate.currentConfiguration.matches.last.matchedLocation, AppConstants.loginRoute);
    });

    testWidgets('5. Unreachable backend cannot leave app on Splash indefinitely', (WidgetTester tester) async {
      final failingRepo = FailingAuthRepository();

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(memoryStorage),
          authenticationRepositoryProvider.overrideWithValue(failingRepo),
        ],
      );

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(container.read(authControllerProvider).status, AuthStatus.unauthenticated);
      expect(router.routerDelegate.currentConfiguration.matches.last.matchedLocation, AppConstants.loginRoute);
    });
  });
}
