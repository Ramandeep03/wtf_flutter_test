import 'package:bloc/bloc.dart';
import 'package:shared/shared.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    AppLogger.t(
      LogTag.nav,
      '[${bloc.runtimeType}] ${change.currentState.runtimeType}→${change.nextState.runtimeType}',
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    AppLogger.e(LogTag.nav, '[${bloc.runtimeType}] error', error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}
