import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared/shared.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
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

  group('ApiClient token storage', () {
    test('storedToken is null when nothing saved', () {
      expect(ApiClient.storedToken, isNull);
    });

    test('saveToken persists, storedToken reads it back', () async {
      await ApiClient.saveToken('abc123');
      expect(ApiClient.storedToken, 'abc123');
    });

    test('clearToken removes it', () async {
      await ApiClient.saveToken('xyz');
      await ApiClient.clearToken();
      expect(ApiClient.storedToken, isNull);
    });
  });

  group('Domain models', () {
    test('Failure subclasses carry message + equate by message', () {
      const a = NetworkFailure('boom');
      const b = NetworkFailure('boom');
      const c = NetworkFailure('different');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.message, 'boom');
    });
  });

  group('Extensions', () {
    test('IntExt.toMMSS formats seconds', () {
      expect(90.toMMSS(), '01:30');
      expect(0.toMMSS(), '00:00');
      expect(3599.toMMSS(), '59:59');
    });

    test('DateTimeExt.isSameDay', () {
      final a = DateTime(2026, 5, 20, 8);
      final b = DateTime(2026, 5, 20, 23, 59);
      final c = DateTime(2026, 5, 21);
      expect(a.isSameDay(b), isTrue);
      expect(a.isSameDay(c), isFalse);
    });
  });

  group('AppLogger', () {
    test('caps at 20 entries and stores latest first-in-last-out', () {
      for (var i = 0; i < 25; i++) {
        AppLogger.log(LogTag.auth, 'msg $i');
      }
      expect(AppLogger.recent.length, 20);
      expect(AppLogger.recent.last, contains('msg 24'));
      expect(AppLogger.recent.first, contains('msg 5')); // 0–4 dropped
    });
  });
}
