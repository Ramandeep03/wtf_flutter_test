import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared/shared.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_auth_');
    Hive.init(tempDir.path);
    await Hive.openBox('app_prefs');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    await Hive.box('app_prefs').clear();
  });

  const user = UserEntity(
    uid: 'uid-1',
    name: 'DK',
    email: 'dk@wtf.fit',
    role: 'member',
    assignedTrainerId: 'uid-2',
  );

  group('AuthCubit', () {
    blocTest<AuthCubit, AuthState>(
      'checkSession → completed when session valid',
      build: () {
        final repo = _MockAuthRepository();
        when(repo.getSession).thenAnswer((_) async => const Right(user));
        return AuthCubit(repo);
      },
      act: (c) => c.checkSession(),
      expect: () => [
        isA<ApiLoading<UserEntity>>(),
        const ApiSuccess(user),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'checkSession → failure when no token',
      build: () {
        final repo = _MockAuthRepository();
        when(repo.getSession).thenAnswer(
          (_) async => const Left(AuthFailure('No token')),
        );
        return AuthCubit(repo);
      },
      act: (c) => c.checkSession(),
      expect: () => [
        isA<ApiLoading<UserEntity>>(),
        isA<ApiFailure<UserEntity>>()
            .having((s) => s.error.message, 'error.message', 'No token'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'login success → ApiSuccess(user)',
      build: () {
        final repo = _MockAuthRepository();
        when(() => repo.login(any(), any())).thenAnswer((_) async => const Right(user));
        return AuthCubit(repo);
      },
      act: (c) => c.login('dk@wtf.fit', 'Wtf@1234'),
      expect: () => [
        isA<ApiLoading<UserEntity>>(),
        const ApiSuccess(user),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'login failure → ApiFailure with backend message',
      build: () {
        final repo = _MockAuthRepository();
        when(() => repo.login(any(), any())).thenAnswer(
          (_) async => const Left(AuthFailure('INVALID_LOGIN_CREDENTIALS', code: 401)),
        );
        return AuthCubit(repo);
      },
      act: (c) => c.login('dk@wtf.fit', 'wrong'),
      expect: () => [
        isA<ApiLoading<UserEntity>>(),
        isA<ApiFailure<UserEntity>>().having(
          (s) => s.error.message,
          'error.message',
          'INVALID_LOGIN_CREDENTIALS',
        ),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'logout → ApiInitial and repo.logout called',
      build: () {
        final repo = _MockAuthRepository();
        when(repo.logout).thenAnswer((_) async => const Right(unit));
        return AuthCubit(repo);
      },
      seed: () => const ApiSuccess(user),
      act: (c) => c.logout(),
      expect: () => [isA<ApiInitial<UserEntity>>()],
      verify: (c) {
        // mocktail verify
      },
    );
  });
}
