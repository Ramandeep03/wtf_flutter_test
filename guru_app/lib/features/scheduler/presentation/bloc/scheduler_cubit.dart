import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared/shared.dart';

/// Form-state cubit: holds the user's in-progress selection plus a
/// nested submit status (loading/success/failure) per ADR#5.
class SchedulerFormState extends Equatable {
  final DateTime selectedDate;
  final DateTime? selectedSlot;
  final String note;
  final ApiStatus<Unit> submitStatus;
  final String? errorMessage;

  const SchedulerFormState({
    required this.selectedDate,
    this.selectedSlot,
    this.note = '',
    this.submitStatus = const ApiInitial(),
    this.errorMessage,
  });

  SchedulerFormState copyWith({
    DateTime? selectedDate,
    DateTime? selectedSlot,
    bool clearSlot = false,
    String? note,
    ApiStatus<Unit>? submitStatus,
    String? errorMessage,
    bool clearError = false,
  }) =>
      SchedulerFormState(
        selectedDate: selectedDate ?? this.selectedDate,
        selectedSlot: clearSlot ? null : (selectedSlot ?? this.selectedSlot),
        note: note ?? this.note,
        submitStatus: submitStatus ?? this.submitStatus,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [selectedDate, selectedSlot, note, submitStatus, errorMessage];
}

class SchedulerCubit extends Cubit<SchedulerFormState> {
  final CallRequestRepository _repo;
  final String memberId;
  final String trainerId;

  SchedulerCubit({
    required CallRequestRepository repo,
    required this.memberId,
    required this.trainerId,
  })  : _repo = repo,
        super(SchedulerFormState(selectedDate: DateTime.now()));

  void selectDate(DateTime d) =>
      emit(state.copyWith(selectedDate: d, clearSlot: true, clearError: true));

  void selectSlot(DateTime s) =>
      emit(state.copyWith(selectedSlot: s, clearError: true));

  void updateNote(String n) =>
      emit(state.copyWith(note: n, clearError: true));

  Future<void> submit() async {
    if (state.selectedSlot == null) {
      emit(state.copyWith(errorMessage: 'Pick a time slot first.'));
      return;
    }
    if (state.selectedSlot!.isBefore(DateTime.now())) {
      emit(state.copyWith(errorMessage: 'Cannot schedule in the past.'));
      return;
    }
    if (state.note.length > AppConstants.maxNoteLength) {
      emit(state.copyWith(errorMessage: 'Note max ${AppConstants.maxNoteLength} chars.'));
      return;
    }

    emit(state.copyWith(submitStatus: const ApiLoading(), clearError: true));
    final res = await _repo.create(
      memberId: memberId,
      trainerId: trainerId,
      note: state.note,
      scheduledFor: state.selectedSlot!,
    );
    res.fold(
      (f) => emit(state.copyWith(
        submitStatus: ApiFailure<Unit>(f),
        errorMessage: f.message,
      )),
      (_) => emit(SchedulerFormState(
        selectedDate: state.selectedDate,
        submitStatus: const ApiSuccess(unit),
      )),
    );
  }

  /// Called after the success snackbar has fired so the form is ready
  /// for another booking without firing the listener again.
  void acknowledgeSubmitResult() {
    emit(state.copyWith(submitStatus: const ApiInitial()));
  }
}
