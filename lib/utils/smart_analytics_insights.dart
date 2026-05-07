import 'package:flutter/material.dart';

import '../constants/language.dart';
import '../models/bill_summary.dart';
import 'consumption_series.dart';

class SmartAnalyticsSnapshot {
  final String primaryLine;
  final String secondaryLine;
  final String? tertiaryLine;
  final String? alertLine;
  final String? predictionLine;

  const SmartAnalyticsSnapshot({
    required this.primaryLine,
    required this.secondaryLine,
    this.tertiaryLine,
    this.alertLine,
    this.predictionLine,
  });
}

abstract final class SmartAnalyticsInsights {
  static const double _spikeThreshold = 1.15;

  static SmartAnalyticsSnapshot build(
    List<BillSummary> bills,
    AppLocalizations loc,
    Locale locale, {
    int seriesMonths = 12,
  }) {
    final m = seriesMonths.clamp(3, 24).toInt();
    final elec = buildMonthlyConsumptionSeries(
      bills,
      isElectricity: true,
      locale: locale,
      months: m,
    );
    final water = buildMonthlyConsumptionSeries(
      bills,
      isElectricity: false,
      locale: locale,
      months: m,
    );

    final avgWindow = m >= 3 ? 3 : m;
    final avgE = _meanLastN(elec.values, avgWindow);
    final avgW = _meanLastN(water.values, avgWindow);

    final hasE = avgE != null && avgE > 0;
    final hasW = avgW != null && avgW > 0;

    if (!hasE && !hasW) {
      return SmartAnalyticsSnapshot(
        primaryLine: loc.smartAnalyticsFallbackPrimary,
        secondaryLine: loc.smartAnalyticsFallbackSecondary,
        tertiaryLine: null,
      );
    }

    late final String primary;
    late final String secondary;
    if (hasE) {
      primary = loc.smartAnalyticsAvgElectric3m(avgE);
    } else {
      primary = loc.smartAnalyticsNoElectricityData;
    }
    if (hasW) {
      secondary = loc.smartAnalyticsAvgWater3m(avgW);
    } else {
      secondary = loc.smartAnalyticsNoWaterData;
    }

    String? alert;
    final ratioE = _spikeRatio(elec.values);
    final ratioW = _spikeRatio(water.values);
    if (ratioE != null && ratioE >= _spikeThreshold) {
      alert = loc.smartAnalyticsSpikeElectric(
        ((ratioE - 1) * 100).clamp(0, 9999).toDouble(),
      );
    } else if (ratioW != null && ratioW >= _spikeThreshold) {
      alert = loc.smartAnalyticsSpikeWater(
        ((ratioW - 1) * 100).clamp(0, 9999).toDouble(),
      );
    }

    String? tertiary;
    if (m >= 12) {
      tertiary = _yoyLine(
        bills,
        locale,
        loc,
        isElectricity: true,
      );
      tertiary ??= _yoyLine(
        bills,
        locale,
        loc,
        isElectricity: false,
      );
    }

    String? prediction;
    final predE = _predictNextAmount(bills, isElectricity: true, locale: locale);
    final predW = _predictNextAmount(bills, isElectricity: false, locale: locale);

    if (predE != null && predE > 0 && predW != null && predW > 0) {
      prediction = '${loc.nextBillPredictionText(loc.billTypeElectricityLabel, predE)}\n\n${loc.nextBillPredictionText(loc.billTypeWaterLabel, predW)}';
    } else if (predE != null && predE > 0) {
      prediction = loc.nextBillPredictionText(loc.billTypeElectricityLabel, predE);
    } else if (predW != null && predW > 0) {
      prediction = loc.nextBillPredictionText(loc.billTypeWaterLabel, predW);
    }

    return SmartAnalyticsSnapshot(
      primaryLine: primary,
      secondaryLine: secondary,
      tertiaryLine: tertiary,
      alertLine: alert,
      predictionLine: prediction,
    );
  }

  static String? _yoyLine(
    List<BillSummary> bills,
    Locale locale,
    AppLocalizations loc, {
    required bool isElectricity,
  }) {
    final s = buildMonthlyConsumptionSeries(
      bills,
      isElectricity: isElectricity,
      locale: locale,
      months: 24,
    );
    if (s.values.length < 24) return null;
    final now = s.values[23];
    final yoy = s.values[11];
    if (now <= 0 || yoy <= 0) return null;
    final pct = ((now - yoy) / yoy) * 100;
    return isElectricity
        ? loc.smartAnalyticsYoyElectric(pct)
        : loc.smartAnalyticsYoyWater(pct);
  }

  static double? _meanLastN(List<double> values, int n) {
    if (values.length < n) return null;
    final slice = values.sublist(values.length - n);
    if (!slice.any((v) => v > 0)) return null;
    return slice.reduce((a, b) => a + b) / n;
  }

  static double? _spikeRatio(List<double> values) {
    if (values.length < 4) return null;
    final last = values.last;
    if (last <= 0) return null;
    final baseline = values.sublist(values.length - 4, values.length - 1);
    final avg = baseline.reduce((a, b) => a + b) / 3;
    if (avg <= 0) return null;
    return last / avg;
  }

  static double? _predictNextAmount(
    List<BillSummary> bills, {
    required bool isElectricity,
    required Locale locale,
  }) {
    final s = buildMonthlyAmountSeries(
      bills,
      isElectricity: isElectricity,
      locale: locale,
      months: 6,
    );
    // Use last 3 months with data as baseline
    final values = s.values.where((v) => v > 0).toList();
    if (values.isEmpty) return null;
    final n = values.length > 3 ? 3 : values.length;
    final slice = values.sublist(values.length - n);
    return slice.reduce((a, b) => a + b) / n;
  }
}
