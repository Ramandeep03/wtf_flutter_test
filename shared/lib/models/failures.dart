import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class NetworkFailure    extends Failure { const NetworkFailure(super.m); }
class AuthFailure       extends Failure { const AuthFailure(super.m); }
class ValidationFailure extends Failure { const ValidationFailure(super.m); }
class ServerFailure     extends Failure { const ServerFailure(super.m); }
