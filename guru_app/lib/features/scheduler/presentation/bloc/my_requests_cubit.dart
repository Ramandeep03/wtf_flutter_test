import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';

class MyRequestsCubit extends Cubit<ApiStatus<List<CallRequestEntity>>> {
  final CallRequestRepository _repo;
  final String memberId;

  /// Previous list snapshot so we can fire notifications for newly
  /// approved / declined requests instead of every request on every load.
  List<CallRequestEntity> _previous = const [];

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
      (list) {
        _fireDiffNotifications(_previous, list);
        _previous = list;
        emit(ApiSuccess(list));
      },
    );
  }

  Future<void> _fireDiffNotifications(
    List<CallRequestEntity> prev,
    List<CallRequestEntity> next,
  ) async {
    final byId = {for (final p in prev) p.id: p};

    final newlyApproved = next.where(
      (r) => r.isApproved && byId[r.id]?.isApproved != true,
    );
    for (final r in newlyApproved) {
      await NotificationService.instance.show(
        id: NotifId.callApproved,
        title: 'Call Approved 📅',
        body:
            'Your call is confirmed for ${r.scheduledFor.toSlotLabel()} on ${r.scheduledFor.toDateLabel()}.',
        payload: 'call_approved:${r.id}',
      );
      await NotificationService.instance.schedule(
        id: NotifId.callReminder,
        title: 'Call Starting Soon 🎥',
        body: 'Your call starts in 10 minutes. Tap to join.',
        scheduledAt: r.scheduledFor.subtract(const Duration(minutes: 10)),
        payload: 'call_join:${r.id}',
      );
    }

    final newlyDeclined = next.where(
      (r) => r.isDeclined && byId[r.id]?.isDeclined != true,
    );
    for (final r in newlyDeclined) {
      final reason = (r.declineReason?.isNotEmpty ?? false)
          ? r.declineReason!
          : 'No reason provided';
      await NotificationService.instance.show(
        id: NotifId.callDeclined,
        title: 'Call Request Declined',
        body: 'Reason: $reason',
        payload: 'call_declined:${r.id}',
      );
    }
  }
}
