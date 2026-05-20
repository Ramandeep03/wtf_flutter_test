// Live integration smoke test against a running backend on localhost:3000.
// Run with: BACKEND_BASE_URL=http://localhost:3000 dart test test/_health_smoke.dart
// Skipped by default (filename starts with _).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared/shared.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_smoke_');
    Hive.init(tempDir.path);
    await Hive.openBox('app_prefs');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('GET /health via ApiClient returns ok', () async {
    final res = await ApiClient.instance.get('/health');
    expect(res['status'], 'ok');
    expect(res['ts'], isA<String>());
  });
}
