import 'package:shared/shared.dart';

class AppDependencies {
  late final AuthRepository authRepository;
  late final AuthCubit authCubit;

  AppDependencies() {
    authRepository = AuthRepositoryImpl();
    authCubit = AuthCubit(authRepository)..checkSession();
  }

  void dispose() {
    authCubit.close();
  }
}
