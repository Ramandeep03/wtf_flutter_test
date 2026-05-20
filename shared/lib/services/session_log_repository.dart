import 'package:api_state/api_state.dart';
import 'package:fpdart/fpdart.dart';

import '../models/failures.dart';
import '../models/session_log_draft.dart';
import '../models/session_log_entity.dart';
import 'api_client.dart';

class SessionLogRepository {
  final ApiClient _api;
  SessionLogRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  Future<Either<Failure, SessionLogEntity>> create(
    SessionLogDraft draft, {
    required String memberId,
    required String trainerId,
  }) async {
    try {
      final data = await _api.post('/session-logs', {
        'memberId': memberId,
        'trainerId': trainerId,
        'startedAt':   draft.joinedAt.toUtc().toIso8601String(),
        'endedAt':     draft.endedAt.toUtc().toIso8601String(),
        'durationSec': draft.durationSec,
      });
      return Right(SessionLogEntity.fromJson(data));
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, code: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, List<SessionLogEntity>>> getForUser(String userId) async {
    try {
      final raw = await _api.getList('/session-logs?userId=$userId');
      return Right(
        raw.cast<Map<String, dynamic>>().map(SessionLogEntity.fromJson).toList(),
      );
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, code: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, SessionLogEntity>> update(
    String id, {
    int? rating,
    String? memberNotes,
    String? trainerNotes,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (rating       != null) body['rating']       = rating;
      if (memberNotes  != null) body['memberNotes']  = memberNotes;
      if (trainerNotes != null) body['trainerNotes'] = trainerNotes;
      final data = await _api.patch('/session-logs/$id', body);
      return Right(SessionLogEntity.fromJson(data));
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, code: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
