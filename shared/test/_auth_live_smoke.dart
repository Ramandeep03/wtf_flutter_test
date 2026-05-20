// Live integration test against running backend on localhost:3000.
// Run: flutter test --dart-define=BACKEND_BASE_URL=http://localhost:3000 test/_auth_live_smoke.dart
// Prefix `_` keeps it out of default `flutter test` runs.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared/shared.dart';

void main() {
  late Directory tempDir;
  late AuthCubit cubit;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_auth_live_');
    Hive.init(tempDir.path);
    await Hive.openBox('app_prefs');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() {
    cubit = AuthCubit(AuthRepositoryImpl());
  });

  tearDown(() async {
    await cubit.close();
    await Hive.box('app_prefs').clear();
  });

  test('login with valid creds → ApiSuccess(DK) + token persisted', () async {
    await cubit.login('dk@wtf.fit', 'Wtf@1234');
    final state = cubit.state;
    expect(state, isA<ApiSuccess<UserEntity>>());
    final user = (state as ApiSuccess<UserEntity>).data;
    expect(user.email, 'dk@wtf.fit');
    expect(user.role, 'member');
    expect(ApiClient.storedToken, isNotNull);
    expect(ApiClient.storedToken!.length, greaterThan(100));
  });

  test('login with wrong password → ApiFailure with backend error', () async {
    await cubit.login('dk@wtf.fit', 'WRONG');
    final state = cubit.state;
    expect(state, isA<ApiFailure<UserEntity>>());
    expect(
      (state as ApiFailure<UserEntity>).error.message,
      contains('INVALID_LOGIN_CREDENTIALS'),
    );
    expect(ApiClient.storedToken, isNull);
  });

  test('checkSession after login → ApiSuccess from /auth/me', () async {
    await cubit.login('aarav@wtf.fit', 'Wtf@1234');
    expect(cubit.state, isA<ApiSuccess<UserEntity>>());

    // Simulate cold restart: new cubit, same Hive box (token persisted)
    final cold = AuthCubit(AuthRepositoryImpl());
    await cold.checkSession();
    expect(cold.state, isA<ApiSuccess<UserEntity>>());
    expect((cold.state as ApiSuccess<UserEntity>).data.name, 'Aarav');
    await cold.close();
  });

  test('logout clears token and emits ApiInitial', () async {
    await cubit.login('dk@wtf.fit', 'Wtf@1234');
    await cubit.logout();
    expect(cubit.state, isA<ApiInitial<UserEntity>>());
    expect(ApiClient.storedToken, isNull);
  });
}
