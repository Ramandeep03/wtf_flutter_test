import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared/shared.dart';

class _MockRepo extends Mock implements SessionLogRepository {}
class _FakeDraft extends Fake implements SessionLogDraft {}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_pcc_');
    Hive.init(tempDir.path);
    await Hive.openBox('app_prefs');
    registerFallbackValue(_FakeDraft());
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  final draft = SessionLogDraft(
    joinedAt: DateTime(2026, 5, 20, 10, 0),
    endedAt:  DateTime(2026, 5, 20, 10, 30),
  );

  final created = SessionLogEntity(
    id: 'sl-1',
    memberId: 'm-1',
    trainerId: 't-1',
    startedAt: draft.joinedAt,
    endedAt:   draft.endedAt,
    durationSec: draft.durationSec,
  );

  final rated = SessionLogEntity(
    id: 'sl-1',
    memberId: 'm-1',
    trainerId: 't-1',
    startedAt: draft.joinedAt,
    endedAt:   draft.endedAt,
    durationSec: draft.durationSec,
    rating: 5,
    memberNotes: 'Great',
  );

  group('PostCallCubit', () {
    test('creates log on init → PostCallPhase.ready, log set', () async {
      final repo = _MockRepo();
      when(() => repo.create(
            any(),
            memberId: any(named: 'memberId'),
            trainerId: any(named: 'trainerId'),
          )).thenAnswer((_) async => Right(created));
      final c = PostCallCubit(
        repo: repo,
        draft: draft,
        memberId: 'm-1',
        trainerId: 't-1',
      );
      await Future<void>.delayed(Duration.zero);
      expect(c.state.phase, PostCallPhase.ready);
      expect(c.state.log?.id, 'sl-1');
      await c.close();
    });

    blocTest<PostCallCubit, PostCallState>(
      'save() with rating → PostCallPhase.saved',
      build: () {
        final repo = _MockRepo();
        when(() => repo.update(
              any(),
              rating: any(named: 'rating'),
              memberNotes:  any(named: 'memberNotes'),
              trainerNotes: any(named: 'trainerNotes'),
            )).thenAnswer((_) async => Right(rated));
        return PostCallCubit(
          repo: repo,
          draft: draft,
          memberId: 'm-1',
          trainerId: 't-1',
          autoCreate: false,
        );
      },
      seed: () => PostCallState(
        phase: PostCallPhase.ready,
        log: created,
        rating: 5,
        memberNote: 'Great',
      ),
      act: (c) => c.save(),
      expect: () => [
        isA<PostCallState>().having((s) => s.phase, 'phase', PostCallPhase.saving),
        isA<PostCallState>()
            .having((s) => s.phase, 'phase', PostCallPhase.saved)
            .having((s) => s.log?.rating, 'log.rating', 5),
      ],
    );

    test('initial create fails → PostCallPhase.failed with error', () async {
      final repo = _MockRepo();
      when(() => repo.create(
            any(),
            memberId: any(named: 'memberId'),
            trainerId: any(named: 'trainerId'),
          )).thenAnswer((_) async => const Left(ServerFailure('500 internal')));
      final c = PostCallCubit(
        repo: repo,
        draft: draft,
        memberId: 'm-1',
        trainerId: 't-1',
      );
      await Future<void>.delayed(Duration.zero);
      expect(c.state.phase, PostCallPhase.failed);
      expect(c.state.error, '500 internal');
      await c.close();
    });
  });
}
