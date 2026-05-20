import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (kDebugMode) debugPrint('[${bloc.runtimeType}] $change');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    if (kDebugMode) debugPrint('[${bloc.runtimeType}] ERROR $error\n$stackTrace');
    super.onError(bloc, error, stackTrace);
  }
}
