/// Bolivia is UTC-4, no DST — centralised so every file imports from here.
class BoliviaTime {
  BoliviaTime._();

  static const _offset = Duration(hours: 4);

  /// Returns the current date/time in Bolivia's timezone.
  static DateTime now() => DateTime.now().toUtc().subtract(_offset);

  /// Converts any UTC [DateTime] to Bolivia local time.
  static DateTime fromUtc(DateTime utc) => utc.toUtc().subtract(_offset);

  /// Returns the [DateTime] range (UTC) that covers today in Bolivia.
  static ({DateTime start, DateTime end}) todayUtcRange() {
    final today = now();
    final startBolivia = DateTime(
      today.year,
      today.month,
      today.day,
    ); // midnight Bolivia
    final startUtc = startBolivia.add(_offset); // back to UTC
    final endUtc = startUtc.add(const Duration(days: 1));
    return (start: startUtc, end: endUtc);
  }

  /// Formats a UTC [DateTime] as HH:mm in Bolivia time.
  static String formatTime(DateTime? utc) {
    if (utc == null) return '—';
    final local = fromUtc(utc);
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
