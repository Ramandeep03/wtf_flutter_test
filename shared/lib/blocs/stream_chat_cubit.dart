import 'package:api_state/api_state.dart';
import 'package:bloc/bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../models/failures.dart';
import '../models/user_entity.dart';
import '../services/stream_chat_service.dart';

/// `Unit` payload — the state itself communicates connected/disconnected;
/// the underlying user lives on AuthCubit.
typedef StreamChatState = ApiStatus<Unit>;

class StreamChatCubit extends Cubit<StreamChatState> {
  final StreamChatService _service;
  StreamChatCubit({StreamChatService? service})
      : _service = service ?? StreamChatService.instance,
        super(const ApiInitial());

  Future<void> connect(UserEntity user) async {
    emit(const ApiLoading());
    try {
      await _service.connect(user);
      emit(const ApiSuccess(unit));
    } catch (e) {
      emit(ApiFailure(ServerFailure(e.toString())));
    }
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    emit(const ApiInitial());
  }
}
