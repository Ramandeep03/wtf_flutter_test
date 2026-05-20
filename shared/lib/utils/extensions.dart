extension DateTimeExt on DateTime {
  String toRelativeString() {
    final diff = DateTime.now().difference(this);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    == 1) return 'Yesterday';
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}';
  }

  String toSlotLabel() {
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m ${hour >= 12 ? 'PM' : 'AM'}';
  }

  String toDateLabel() {
    const days   = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[weekday - 1]}, $day ${months[month - 1]}';
  }

  bool isSameDay(DateTime o) => year == o.year && month == o.month && day == o.day;
}

extension IntExt on int {
  String toMMSS() {
    final m = (this ~/ 60).toString().padLeft(2, '0');
    final s = (this  % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
