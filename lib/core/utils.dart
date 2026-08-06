import 'package:intl/intl.dart';

String formatDateTime(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

  if (date == today) {
    return DateFormat('HH:mm').format(dateTime);
  } else if (date == yesterday) {
    return 'Yesterday';
  } else if (now.difference(dateTime).inDays < 7) {
    return DateFormat('EEEE').format(dateTime); // Day of the week
  } else {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }
}
