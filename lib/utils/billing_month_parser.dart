import 'dart:math' as math;

abstract final class BillingMonthParser {
  static const _enMonths = <String, int>{
    'january': 1,
    'february': 2,
    'march': 3,
    'april': 4,
    'may': 5,
    'june': 6,
    'july': 7,
    'august': 8,
    'september': 9,
    'october': 10,
    'november': 11,
    'december': 12,
  };

  static const _arMonths = <String, int>{
    'يناير': 1,
    'كانون الثاني': 1,
    'شباط': 2,
    'فبراير': 2,
    'مارس': 3,
    'آذار': 3,
    'نيسان': 4,
    'ابريل': 4,
    'أبريل': 4,
    'أيار': 5,
    'مايو': 5,
    'حزيران': 6,
    'يونيو': 6,
    'تموز': 7,
    'يوليو': 7,
    'آب': 8,
    'اغسطس': 8,
    'أغسطس': 8,
    'ايلول': 9,
    'أيلول': 9,
    'سبتمبر': 9,
    'تشرين الاول': 10,
    'أكتوبر': 10,
    'تشرين الثاني': 11,
    'نوفمبر': 11,
    'كانون الاول': 12,
    'ديسمبر': 12,
  };

  static String? monthKeyFromText(String normalized) {
    final compact = normalized.replaceAll(RegExp(r'\s+'), ' ');
    var m = RegExp(r'\b(20\d{2})\s*[-/]\s*(\d{1,2})\b').firstMatch(compact);
    if (m != null) {
      final mo = int.tryParse(m.group(2)!);
      if (mo != null && mo >= 1 && mo <= 12) {
        return '${m.group(1)}-${mo.toString().padLeft(2, '0')}';
      }
    }
    m = RegExp(r'\b(\d{1,2})\s*[-/]\s*(20\d{2})\b').firstMatch(compact);
    if (m != null) {
      final mo = int.tryParse(m.group(1)!);
      final y = m.group(2);
      if (mo != null && mo >= 1 && mo <= 12 && y != null) {
        return '$y-${mo.toString().padLeft(2, '0')}';
      }
    }

    final lower = compact.toLowerCase();
    for (final e in _enMonths.entries) {
      final re = RegExp(
        r'\b' + RegExp.escape(e.key) + r'\s+(20\d{2})\b',
        caseSensitive: false,
      );
      final mm = re.firstMatch(lower);
      if (mm != null) {
        final y = mm.group(1)!;
        return '$y-${e.value.toString().padLeft(2, '0')}';
      }
    }

    final mmyyyy = RegExp(r'\b(0[1-9]|1[0-2])(20\d{2})\b').firstMatch(compact);
    if (mmyyyy != null) {
      final mo = int.tryParse(mmyyyy.group(1)!);
      final y = mmyyyy.group(2);
      if (mo != null && y != null) {
        return '$y-${mo.toString().padLeft(2, '0')}';
      }
    }

    for (final e in _arMonths.entries) {
      var start = 0;
      while (true) {
        final idx = compact.indexOf(e.key, start);
        if (idx < 0) break;
        final winStart = math.max(0, idx - 60);
        final winEnd = math.min(compact.length, idx + e.key.length + 60);
        final window = compact.substring(winStart, winEnd);
        final ym = RegExp(r'(20\d{2})').firstMatch(window);
        if (ym != null) {
          return '${ym.group(1)}-${e.value.toString().padLeft(2, '0')}';
        }
        start = idx + 1;
      }
    }

    final range = RegExp(
      r'\b(\d{1,2})[/-](\d{1,2})[/-](20\d{2})\b',
    ).firstMatch(compact);
    if (range != null) {
      final mo = int.tryParse(range.group(2)!);
      final y = range.group(3);
      if (mo != null && mo >= 1 && mo <= 12 && y != null) {
        return '$y-${mo.toString().padLeft(2, '0')}';
      }
    }
    return null;
  }

  static String? labelFromLines(List<String> lines) {
    const hints = [
      'billing month',
      'bill month',
      'invoice month',
      'statement month',
      'for month',
      'for the month',
      'فاتورة شهر',
      'شهر الفاتورة',
      'شهر فاتورة',
      'عن شهر',
      'لشهر',
      'خلال شهر',
      'فترة الفاتورة',
      'الفترة من',
    ];
    for (final line in lines) {
      final t = line.trim();
      if (t.length > 80) continue;
      final lower = t.toLowerCase();
      for (final h in hints) {
        if (lower.contains(h) || t.contains(h)) {
          return t;
        }
      }
    }
    return null;
  }
}
