import '../models/bill_summary.dart';
import 'billing_month_parser.dart';
import 'text_normalize.dart';

abstract final class BillDateUtils {
  static DateTime effectiveDate(BillSummary bill) {
    final parsed = parseDateText(bill.dateText);
    if (parsed != null) return parsed;
    return DateTime.fromMillisecondsSinceEpoch(bill.createdAt);
  }

  static DateTime chartBucketDate(BillSummary bill) {
    final key = bill.billingMonthKey;
    if (key != null && key.contains('-')) {
      final p = key.split('-');
      if (p.length == 2) {
        final y = int.tryParse(p[0]);
        final m = int.tryParse(p[1]);
        if (y != null && m != null && m >= 1 && m <= 12) {
          return DateTime(y, m, 1);
        }
      }
    }
    final txt = bill.billingMonthText;
    if (txt != null && txt.isNotEmpty) {
      final nk = BillingMonthParser.monthKeyFromText(
        TextNormalize.forDateParsing(txt),
      );
      if (nk != null) {
        final p = nk.split('-');
        if (p.length == 2) {
          final y = int.tryParse(p[0]);
          final m = int.tryParse(p[1]);
          if (y != null && m != null && m >= 1 && m <= 12) {
            return DateTime(y, m, 1);
          }
        }
      }
    }
    return effectiveDate(bill);
  }

  static DateTime? parseDateText(String dateText) {
    if (dateText.isEmpty) return null;

    final normalized = TextNormalize.forDateParsing(dateText);

    final iso = RegExp(
      r'^(\d{4})[/-](\d{1,2})[/-](\d{1,2})',
    ).firstMatch(normalized);
    if (iso != null) {
      final y = int.tryParse(iso.group(1)!);
      final m = int.tryParse(iso.group(2)!);
      final day = int.tryParse(iso.group(3)!);
      if (y != null && m != null && m >= 1 && m <= 12 && day != null) {
        final d = day.clamp(1, 31);
        try {
          return DateTime(y, m, d);
        } catch (_) {
          return DateTime(y, m, 1);
        }
      }
    }

    final dmy = RegExp(
      r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})',
    ).firstMatch(normalized);
    if (dmy != null) {
      final day = int.tryParse(dmy.group(1)!);
      final month = int.tryParse(dmy.group(2)!);
      var year = int.tryParse(dmy.group(3)!);
      if (year != null && year < 100) year += 2000;
      if (day != null &&
          month != null &&
          year != null &&
          month >= 1 &&
          month <= 12) {
        final dd = day.clamp(1, 31);
        try {
          return DateTime(year, month, dd);
        } catch (_) {
          return DateTime(year, month, 1);
        }
      }
    }

    return null;
  }
}
