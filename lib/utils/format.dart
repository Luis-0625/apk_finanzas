import 'package:intl/intl.dart';

final NumberFormat _n = NumberFormat('#,##0', 'es_CO');

/// 150000 -> $150.000
String cop(num v) {
  final r = v.round();
  final s = '\$${_n.format(r.abs())}';
  return r < 0 ? '-$s' : s;
}

/// 1500000 -> $1,5M | 150000 -> $150k
String copCompact(num v) {
  final a = v.abs();
  String s;
  if (a >= 1e6) {
    s = '${(a / 1e6).toStringAsFixed(a % 1e6 == 0 ? 0 : 1)}M';
  } else if (a >= 1e3) {
    s = '${(a / 1e3).round()}k';
  } else {
    s = '${a.round()}';
  }
  return '\$$s';
}

String monthLabel(DateTime d) {
  final s = DateFormat('MMMM yyyy', 'es').format(d);
  return s[0].toUpperCase() + s.substring(1);
}

String shortMonth(DateTime d) =>
    DateFormat('MMM', 'es').format(d).replaceAll('.', '');

String shortDate(DateTime d) =>
    DateFormat('d MMM', 'es').format(d).replaceAll('.', '');
