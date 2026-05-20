import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';

class MyRequestsCubit extends Cubit<ApiStatus<List<CallRequestEntity>>> {
  final CallRequestRepository _repo;
  final String memberId;

  MyRequestsCubit({required CallRequestRepository repo, required this.memberId})
      : _repo = repo,
        super(const ApiInitial()) {
    load();
  }

  Future<void> load() async {
    emit(const ApiLoading());
    final res = await _repo.getForMember(memberId);
    res.fold(
      (f) => emit(ApiFailure<List<CallRequestEntity>>(f)),
      (list) => emit(ApiSuccess(list)),
    );
  }
}
