import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared/shared.dart';

class _MockRepo extends Mock implements SessionLogRepository {}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_slc_');
    Hive.init(tempDir.path);
    await Hive.openBox('app_prefs');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  SessionLogEntity log(DateTime when, {int? rating}) => SessionLogEntity(
        id: 'log-${when.millisecondsSinceEpoch}',
        memberId: 'm-1',
        trainerId: 't-1',
        startedAt: when,
        endedAt: when.add(const Duration(minutes: 30)),
        durationSec: 1800,
        rating: rating,
      );

  group('SessionLogsCubit', () {
    final now       = DateTime.now();
    final today     = log(now.subtract(const Duration(hours: 1)));
    final fourDays  = log(now.subtract(const Duration(days: 4)));
    final twoMonths = log(DateTime(now.year, now.month - 2, 15));

    SessionLogsCubit makeCubit() {
      final repo = _MockRepo();
      when(() => repo.getForUser('u-1'))
          .thenAnswer((_) async => Right([fourDays, today, twoMonths]));
      return SessionLogsCubit(repo: repo, userId: 'u-1');
    }

    test('initial load → ApiSuccess; displayed sorted newest-first', () async {
      final c = makeCubit();
      await Future<void>.delayed(Duration.zero);
      expect(c.state.listStatus, isA<ApiSuccess<List<SessionLogEntity>>>());
      final ids = c.state.displayed.map((l) => l.id).toList();
      expect(ids.first, today.id);
      expect(ids.last,  twoMonths.id);
      await c.close();
    });

    test('setFilter(last7Days) trims `displayed` to within-7-days logs', () async {
      final c = makeCubit();
      await Future<void>.delayed(Duration.zero);
      c.setFilter(LogFilter.last7Days);
      expect(c.state.filter, LogFilter.last7Days);
      final ids = c.state.displayed.map((l) => l.id).toSet();
      expect(ids, contains(today.id));
      expect(ids, contains(fourDays.id));
      expect(ids, isNot(contains(twoMonths.id)));
      await c.close();
    });

    test('setFilter(thisMonth) only this month\'s logs', () async {
      final c = makeCubit();
      await Future<void>.delayed(Duration.zero);
      c.setFilter(LogFilter.thisMonth);
      final ids = c.state.displayed.map((l) => l.id).toSet();
      expect(ids, contains(today.id));
      expect(ids, contains(fourDays.id));
      expect(ids, isNot(contains(twoMonths.id)));
      await c.close();
    });
  });
}
