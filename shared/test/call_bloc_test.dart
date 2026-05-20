import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared/shared.dart';

class _MockApi extends Mock implements ApiClient {}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_call_');
    Hive.init(tempDir.path);
    await Hive.openBox('app_prefs');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('CallBloc', () {
    blocTest<CallBloc, CallState>(
      'CallJoinRequested with /hms-token failure → CallPhase.failed',
      build: () {
        final api = _MockApi();
        when(() => api.get(any())).thenThrow(const ApiException(500, 'boom'));
        return CallBloc(api: api);
      },
      act: (b) => b.add(const CallJoinRequested(
        roomId: 'room-1',
        userId: 'u-1',
        userName: 'DK',
        role: 'member',
      )),
      expect: () => [
        isA<CallState>().having((s) => s.phase, 'phase', CallPhase.joining),
        isA<CallState>()
            .having((s) => s.phase, 'phase', CallPhase.failed)
            .having((s) => s.errorMessage, 'errorMessage', contains('boom')),
      ],
    );

    blocTest<CallBloc, CallState>(
      'CallHmsConnected → CallPhase.inCall + joinedAt set',
      build: () => CallBloc(api: _MockApi()),
      act: (b) => b.add(const CallHmsConnected()),
      expect: () => [
        isA<CallState>()
            .having((s) => s.phase, 'phase', CallPhase.inCall)
            .having((s) => s.joinedAt, 'joinedAt', isNotNull),
      ],
    );

    blocTest<CallBloc, CallState>(
      'CallHmsReconnecting → CallPhase.joining',
      build: () => CallBloc(api: _MockApi()),
      seed: () => CallState(
        phase: CallPhase.inCall,
        joinedAt: DateTime(2026, 5, 20),
      ),
      act: (b) => b.add(const CallHmsReconnecting()),
      expect: () => [
        isA<CallState>().having((s) => s.phase, 'phase', CallPhase.joining),
      ],
    );

    blocTest<CallBloc, CallState>(
      'CallHmsReconnected → CallPhase.inCall',
      build: () => CallBloc(api: _MockApi()),
      seed: () => CallState(
        phase: CallPhase.joining,
        joinedAt: DateTime(2026, 5, 20),
      ),
      act: (b) => b.add(const CallHmsReconnected()),
      expect: () => [
        isA<CallState>().having((s) => s.phase, 'phase', CallPhase.inCall),
      ],
    );

    blocTest<CallBloc, CallState>(
      'CallHmsFailed terminal → CallPhase.failed + errorMessage',
      build: () => CallBloc(api: _MockApi()),
      act: (b) => b.add(const CallHmsFailed('network-lost', isTerminal: true)),
      expect: () => [
        isA<CallState>()
            .having((s) => s.phase, 'phase', CallPhase.failed)
            .having((s) => s.errorMessage, 'errorMessage', 'network-lost'),
      ],
    );

    blocTest<CallBloc, CallState>(
      'CallHmsFailed non-terminal → no state change',
      build: () => CallBloc(api: _MockApi()),
      act: (b) => b.add(const CallHmsFailed('hiccup', isTerminal: false)),
      expect: () => [],
    );

  });
}
