import 'package:api_state/api_state.dart';

/// Every feature BLoC/Cubit state that wraps an HTTP call must use
/// [ApiStatus<T>] from the `api_state` package (see ADR#5).
///
/// States:
///   - ApiInitial         — no request started yet
///   - ApiLoading         — request in flight, no prior data
///   - ApiSuccess<T>      — completed with data
///   - ApiFailure<T>      — failed (carries message / failure type)
///   - ApiRefresh<T>      — re-fetching while keeping previous data
///
/// Example:
///   class UsersCubit extends Cubit<ApiStatus<List<User>>> {
///     UsersCubit(this._repo) : super(const ApiInitial());
///     final UserRepository _repo;
///
///     Future<void> load() async {
///       emit(const ApiLoading());
///       emit(await ApiStatus.guard(() => _repo.getUsers()));
///     }
///   }
///
/// UI consumes via exhaustive pattern matching:
///   switch (state) {
///     ApiInitial()           => const SizedBox.shrink(),
///     ApiLoading()           => const CircularProgressIndicator(),
///     ApiSuccess(:final data) => UsersList(users: data),
///     ApiFailure(:final message) => ErrorView(message: message),
///     ApiRefresh(:final data) => UsersList(users: data, refreshing: true),
///   }
typedef BaseState<T> = ApiStatus<T>;
