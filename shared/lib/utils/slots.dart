import 'constants.dart';

/// 30-minute slots between [AppConstants.slotStartHour] (inclusive) and
/// [AppConstants.slotEndHour] (exclusive) for the calendar day of [date].
///
/// When [date] is today (or earlier), past slots are dropped so the user
/// can't pick a slot that's already gone. A small +1 minute buffer prevents
/// edge-case clicks on a slot that's about to lapse mid-tap.
List<DateTime> generateSlots(DateTime date) {
  final slots = <DateTime>[];
  var t = DateTime(date.year, date.month, date.day, AppConstants.slotStartHour);
  final end =
      DateTime(date.year, date.month, date.day, AppConstants.slotEndHour);
  final cutoff = DateTime.now().add(const Duration(minutes: 1));
  while (t.isBefore(end)) {
    if (t.isAfter(cutoff)) slots.add(t);
    t = t.add(Duration(minutes: AppConstants.slotDurationMinutes));
  }
  return slots;
}
