import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guru_app/features/scheduler/presentation/bloc/scheduler_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared/shared.dart';

class _MockRepo extends Mock implements CallRequestRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.now());
  });

  final created = CallRequestEntity(
    id: 'cr-1',
    memberId: 'm-1',
    trainerId: 't-1',
    note: '',
    status: 'pending',
    requestedAt: DateTime.now(),
    scheduledFor: DateTime.now().add(const Duration(hours: 1)),
  );

  group('SchedulerCubit', () {
    blocTest<SchedulerCubit, SchedulerFormState>(
      'submit past slot → errorMessage, no repo call',
      build: () {
        final repo = _MockRepo();
        return SchedulerCubit(repo: repo, memberId: 'm-1', trainerId: 't-1');
      },
      act: (c) {
        c.selectSlot(DateTime.now().subtract(const Duration(hours: 1)));
        return c.submit();
      },
      skip: 1,
      expect: () => [
        isA<SchedulerFormState>()
            .having((s) => s.errorMessage, 'errorMessage', 'Cannot schedule in the past.'),
      ],
    );

    blocTest<SchedulerCubit, SchedulerFormState>(
      'submit note > 140 chars → errorMessage',
      build: () {
        final repo = _MockRepo();
        return SchedulerCubit(repo: repo, memberId: 'm-1', trainerId: 't-1');
      },
      act: (c) {
        c.selectSlot(DateTime.now().add(const Duration(hours: 2)));
        c.updateNote('x' * 141);
        return c.submit();
      },
      skip: 2,
      expect: () => [
        isA<SchedulerFormState>()
            .having((s) => s.errorMessage, 'errorMessage', contains('Note max')),
      ],
    );

    blocTest<SchedulerCubit, SchedulerFormState>(
      'submit ok → ApiLoading then ApiSuccess, slot/note cleared',
      build: () {
        final repo = _MockRepo();
        when(() => repo.create(
              memberId: any(named: 'memberId'),
              trainerId: any(named: 'trainerId'),
              note: any(named: 'note'),
              scheduledFor: any(named: 'scheduledFor'),
            )).thenAnswer((_) async => Right(created));
        return SchedulerCubit(repo: repo, memberId: 'm-1', trainerId: 't-1');
      },
      act: (c) {
        c.selectSlot(DateTime.now().add(const Duration(hours: 3)));
        return c.submit();
      },
      skip: 1,
      expect: () => [
        isA<SchedulerFormState>()
            .having((s) => s.submitStatus, 'submitStatus', isA<ApiLoading<Unit>>()),
        isA<SchedulerFormState>()
            .having((s) => s.submitStatus, 'submitStatus', isA<ApiSuccess<Unit>>())
            .having((s) => s.selectedSlot, 'slot', isNull)
            .having((s) => s.note, 'note', ''),
      ],
    );
  });
}
