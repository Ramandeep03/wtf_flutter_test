import 'package:api_state/api_state.dart';
import 'package:fpdart/fpdart.dart';

import '../models/call_request_entity.dart';
import '../models/failures.dart';
import 'api_client.dart';

class CallRequestRepository {
  final ApiClient _api;
  CallRequestRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  Future<Either<Failure, CallRequestEntity>> create({
    required String memberId,
    required String trainerId,
    required String note,
    required DateTime scheduledFor,
  }) async {
    try {
      final data = await _api.post('/call-requests', {
        'memberId': memberId,
        'trainerId': trainerId,
        'note': note,
        'scheduledFor': scheduledFor.toUtc().toIso8601String(),
      });
      return Right(CallRequestEntity.fromJson(data));
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return const Left(ValidationFailure('Slot already booked.'));
      }
      return Left(ServerFailure(e.message, code: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, List<CallRequestEntity>>> getForMember(String memberId) =>
      _list('/call-requests?memberId=$memberId');

  Future<Either<Failure, List<CallRequestEntity>>> getForTrainer(String trainerId) =>
      _list('/call-requests?trainerId=$trainerId');

  Future<Either<Failure, List<CallRequestEntity>>> _list(String path) async {
    try {
      final raw = await _api.getList(path);
      return Right(
        raw
            .cast<Map<String, dynamic>>()
            .map(CallRequestEntity.fromJson)
            .toList(),
      );
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, code: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, CallRequestEntity>> updateStatus(
    String id,
    String status, {
    String? declineReason,
  }) async {
    try {
      final body = <String, dynamic>{'status': status};
      if (declineReason != null) body['declineReason'] = declineReason;
      final data = await _api.patch('/call-requests/$id', body);
      return Right(CallRequestEntity.fromJson(data));
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, code: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

/// Room creation lives on its own minimal repository so it can be swapped
/// in tests / mocked when 100ms creds aren't available.
class RoomRepository {
  final ApiClient _api;
  RoomRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  /// POST /rooms — returns the persisted room_meta document.
  Future<Either<Failure, Map<String, dynamic>>> create(String callRequestId) async {
    try {
      final data = await _api.post('/rooms', {'callRequestId': callRequestId});
      return Right(data);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, code: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
