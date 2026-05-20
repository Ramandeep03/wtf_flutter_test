import 'package:api_state/api_state.dart';

/// Domain failures used across both apps. All extend the api_state [Failure]
/// so they can be carried inside `ApiFailure<T>(failure)` and switch-matched
/// in the UI alongside other `ApiStatus<T>` cases.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code, super.stackTrace});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code, super.stackTrace});
}
