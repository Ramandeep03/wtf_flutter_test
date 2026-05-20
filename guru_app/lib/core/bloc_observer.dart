import 'package:bloc/bloc.dart';
import 'package:shared/shared.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    AppLogger.log(
      LogTag.auth,
      '[${bloc.runtimeType}] ${change.currentState.runtimeType}→${change.nextState.runtimeType}',
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    AppLogger.log(LogTag.auth, '[${bloc.runtimeType}] ERROR: $error');
    super.onError(bloc, error, stackTrace);
  }
}
