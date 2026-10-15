String two(int n) => n.toString().padLeft(2, '0');

String formatDate(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';

String formatTime(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

String formatDateTime(DateTime d) => '${formatDate(d)} às ${formatTime(d)}';

const List<String> kMonthsShort = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];

const List<String> kMonthsFull = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

String formatMonthYear(DateTime d) => '${kMonthsFull[d.month - 1]} ${d.year}';

String formatDuration(int? minutes) {
  if (minutes == null) return '—';
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h h' : '$h h ${two(m)} min';
}

String formatMeters(double? v) {
  if (v == null) return '—';
  final text = v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  return '$text m';
}

String formatNumber(double? v, String unit) {
  if (v == null) return '—';
  final text = v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  return '$text $unit';
}

/// "1,5" ou "1.5" -> 1.5 ; vazio -> null
double? parseDouble(String text) {
  final t = text.trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

int? parseInt(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  return int.tryParse(t);
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}
