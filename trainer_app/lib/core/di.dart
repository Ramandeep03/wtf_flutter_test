import 'package:shared/shared.dart';

class AppDependencies {
  late final AuthRepository authRepository;
  late final AuthCubit authCubit;
  late final StreamChatCubit streamChatCubit;

  AppDependencies() {
    authRepository = AuthRepositoryImpl();
    authCubit = AuthCubit(authRepository)..checkSession();
    streamChatCubit = StreamChatCubit();
  }

  void dispose() {
    authCubit.close();
    streamChatCubit.close();
  }
}
