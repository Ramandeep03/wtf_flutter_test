import 'constants.dart';

/// 30-minute slots between [AppConstants.slotStartHour] (inclusive) and
/// [AppConstants.slotEndHour] (exclusive) for the calendar day of [date].
List<DateTime> generateSlots(DateTime date) {
  final slots = <DateTime>[];
  var t = DateTime(date.year, date.month, date.day, AppConstants.slotStartHour);
  final end = DateTime(date.year, date.month, date.day, AppConstants.slotEndHour);
  while (t.isBefore(end)) {
    slots.add(t);
    t = t.add(Duration(minutes: AppConstants.slotDurationMinutes));
  }
  return slots;
}
