import 'package:intl/intl.dart';

/// Date presentation helpers.
class Formatters {
  const Formatters._();

  static final DateFormat _absolute = DateFormat('d MMM yyyy, HH:mm');
  static final DateFormat _dayMonth = DateFormat('d MMM');

  static String absolute(DateTime value) => _absolute.format(value.toLocal());

  static String dayMonth(DateTime value) => _dayMonth.format(value.toLocal());

  /// Short relative age, e.g. "2 h ago". Lists use this because a student
  /// scanning reports cares about recency, not calendar dates.
  static String relative(DateTime value) {
    final diff = DateTime.now().difference(value.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return _dayMonth.format(value.toLocal());
  }

  /// Human-sized reference built from the Firestore document id, shown on
  /// the card and the detail screen so a student can quote it to a cleaner
  /// or a facilities officer in person.
  static String reference(String documentId) {
    final slice = documentId.length >= 6
        ? documentId.substring(0, 6)
        : documentId.padRight(6, '0');
    return 'INC-${slice.toUpperCase()}';
  }

  static String initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0].toUpperCase();
    if (parts.length == 1) return first;
    return '$first${parts.last[0].toUpperCase()}';
  }
}
