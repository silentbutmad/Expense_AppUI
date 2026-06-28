import 'package:intl/intl.dart';

Map<String, List<Map<String, dynamic>>> groupTransactionsByDate(
  List<Map<String, dynamic>> transactions,
) {
  final Map<String, List<Map<String, dynamic>>> grouped = {};
  for (final tx in transactions) {
    final dateStr = tx['transaction_date'] as String? ?? '';
    if (dateStr.isEmpty) continue;
    try {
      final date = DateTime.parse(dateStr);
      final key = DateFormat.yMMMd().format(date);
      grouped.putIfAbsent(key, () => []).add(tx);
    } catch (e) {
      // Skip invalid dates
    }
  }
  return grouped;
}

String formatTransactionDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat.yMMMd().format(date);
  } catch (e) {
    return '';
  }
}

String formatTransactionTime(String? dateStr, String? timeStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  try {
    final date = DateTime.parse(dateStr);
    if (timeStr != null && timeStr.isNotEmpty) {
      return timeStr;
    }
    return DateFormat.jm().format(date);
  } catch (e) {
    return '';
  }
}