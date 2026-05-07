import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../models/bill_summary.dart';
import 'bill_date_utils.dart';
import 'bill_type_utils.dart';

class ConsumptionSeries {
  final List<double> values;
  final List<String> labels;

  const ConsumptionSeries({required this.values, required this.labels});
}

ConsumptionSeries buildMonthlyConsumptionSeries(
  List<BillSummary> bills, {
  required bool isElectricity,
  required Locale locale,
  int months = 12,
}) {
  final now = DateTime.now();
  final monthStarts = List.generate(months, (i) {
    return DateTime(now.year, now.month - (months - 1 - i), 1);
  });
  final labels =
      monthStarts.map((d) {
        try {
          return intl.DateFormat.MMM(locale.toString()).format(d);
        } catch (_) {
          return '${d.month}/${(d.year % 100).toString().padLeft(2, '0')}';
        }
      }).toList();

  final values = List<double>.filled(months, 0);
  final filtered =
      bills
          .where(
            (b) =>
                isElectricity
                    ? BillTypeUtils.isElectricity(b.type)
                    : BillTypeUtils.isWater(b.type),
          )
          .toList();

  for (final bill in filtered) {
    final d = BillDateUtils.chartBucketDate(bill);
    for (var i = 0; i < months; i++) {
      final m = monthStarts[i];
      if (d.year == m.year && d.month == m.month) {
        final v = bill.consumptionValue;
        if (v != null && v > 0) {
          values[i] += v;
        }
        break;
      }
    }
  }
  return ConsumptionSeries(values: values, labels: labels);
}

ConsumptionSeries buildMonthlyAmountSeries(
  List<BillSummary> bills, {
  required bool isElectricity,
  required Locale locale,
  int months = 12,
}) {
  final now = DateTime.now();
  final monthStarts = List.generate(months, (i) {
    return DateTime(now.year, now.month - (months - 1 - i), 1);
  });
  final labels =
      monthStarts.map((d) {
        try {
          return intl.DateFormat.MMM(locale.toString()).format(d);
        } catch (_) {
          return '${d.month}/${(d.year % 100).toString().padLeft(2, '0')}';
        }
      }).toList();

  final values = List<double>.filled(months, 0);
  final filtered =
      bills
          .where(
            (b) =>
                isElectricity
                    ? BillTypeUtils.isElectricity(b.type)
                    : BillTypeUtils.isWater(b.type),
          )
          .toList();

  for (final bill in filtered) {
    final d = BillDateUtils.chartBucketDate(bill);
    for (var i = 0; i < months; i++) {
      final m = monthStarts[i];
      if (d.year == m.year && d.month == m.month) {
        final v = bill.totalAmount;
        if (v != null && v > 0) {
          values[i] += v;
        }
        break;
      }
    }
  }
  return ConsumptionSeries(values: values, labels: labels);
}
