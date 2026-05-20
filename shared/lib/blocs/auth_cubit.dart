import 'package:api_state/api_state.dart';
import 'package:bloc/bloc.dart';

import '../models/user_entity.dart';
import '../services/auth_repository.dart';

/// Auth state is the api_state sealed class directly — see ADR#5.
///   ApiInitial  — boot, before checkSession resolves
///   ApiLoading  — request in flight
///   ApiSuccess  — authenticated, carries UserEntity
///   ApiFailure  — unauthenticated / login failed, carries Failure
typedef AuthState = ApiStatus<UserEntity>;

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repo;

  AuthCubit(this._repo) : super(const ApiInitial());

  Future<void> checkSession() async {
    emit(const ApiLoading());
    final res = await _repo.getSession();
    res.fold(
      (f) => emit(ApiFailure<UserEntity>(f)),
      (u) => emit(ApiSuccess(u)),
    );
  }

  Future<void> login(String email, String password) async {
    emit(const ApiLoading());
    final res = await _repo.login(email, password);
    res.fold(
      (f) => emit(ApiFailure<UserEntity>(f)),
      (u) => emit(ApiSuccess(u)),
    );
  }

  Future<void> logout() async {
    await _repo.logout();
    emit(const ApiInitial());
  }
}

/// Convenience for router redirect and conditional UI.
extension AuthStateX on AuthState {
  bool get isAuth => this is ApiSuccess<UserEntity>;
  UserEntity? get userOrNull => switch (this) {
        ApiSuccess(:final data) => data,
        _ => null,
      };
}
