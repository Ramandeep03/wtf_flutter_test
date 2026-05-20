import 'package:fpdart/fpdart.dart';

import '../models/failures.dart';
import '../models/user_entity.dart';
import '../utils/app_logger.dart';
import 'api_client.dart';

abstract class AuthRepository {
  Future<Either<AuthFailure, UserEntity>> login(String email, String password);
  Future<Either<AuthFailure, UserEntity>> getSession();
  Future<Either<AuthFailure, Unit>> logout();
}

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _api;
  AuthRepositoryImpl({ApiClient? api}) : _api = api ?? ApiClient.instance;

  @override
  Future<Either<AuthFailure, UserEntity>> login(String email, String password) async {
    try {
      final data = await _api.post('/auth/login', {
        'email': email,
        'password': password,
      });
      await ApiClient.saveToken(data['idToken'] as String);
      final user = UserEntity.fromJson(data['user'] as Map<String, dynamic>);
      AppLogger.log(LogTag.auth, 'login ok uid=${user.uid}');
      return Right(user);
    } on ApiException catch (e) {
      AppLogger.log(LogTag.auth, 'login failed: ${e.message}');
      return Left(AuthFailure(e.message, code: e.statusCode));
    } catch (e) {
      AppLogger.log(LogTag.auth, 'login error: $e');
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, UserEntity>> getSession() async {
    if (ApiClient.storedToken == null) {
      return const Left(AuthFailure('No token'));
    }
    try {
      final data = await _api.get('/auth/me');
      return Right(UserEntity.fromJson(data));
    } on ApiException catch (e) {
      if (e.statusCode == 401) await ApiClient.clearToken();
      return Left(AuthFailure(e.message, code: e.statusCode));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> logout() async {
    await ApiClient.clearToken();
    AppLogger.log(LogTag.auth, 'logout');
    return const Right(unit);
  }
}
