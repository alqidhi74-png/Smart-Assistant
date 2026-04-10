import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import '../constants/app_layout.dart';
import '../constants/colors.dart';
import '../constants/language.dart';
import '../data/bill_store.dart';
import '../models/bill_summary.dart';
import '../utils/bill_date_utils.dart';
import '../utils/bill_list_query.dart';
import '../utils/bill_type_utils.dart';
import '../utils/consumption_series.dart';
import '../utils/smart_analytics_insights.dart';
import '../utils/category_rtdb_style.dart';
import '../services/categories_rtdb_hub.dart';
import '../utils/loading_overlay.dart';
import 'feedback_page.dart';
import 'help.dart';
import 'upload_bill.dart';

const double _cardRadius = 14;

/// Maps local X inside chart area to bar index (matches [_BarChartPainter] layout).
int _barIndexFromChartDx(double dx, double chartWidth, int n) {
  if (chartWidth <= 0 || n <= 0) return 0;
  if (n == 1) return 0;
  final barWidth = chartWidth / (n * 1.6);
  final gap = barWidth * 0.6;
  for (var i = 0; i < n; i++) {
    final left = i * (barWidth + gap) + gap * 0.5;
    if (dx >= left && dx <= left + barWidth) return i;
  }
  var best = 0;
  var bestDist = double.infinity;
  for (var i = 0; i < n; i++) {
    final left = i * (barWidth + gap) + gap * 0.5;
    final cx = left + barWidth / 2;
    final d = (dx - cx).abs();
    if (d < bestDist) {
      bestDist = d;
      best = i;
    }
  }
  return best;
}

int _lineIndexFromChartDx(double dx, double chartWidth, int n) {
  if (chartWidth <= 0 || n <= 0) return 0;
  if (n == 1) return 0;
  final step = chartWidth / (n - 1);
  return (dx / step).round().clamp(0, n - 1);
}

class HomePage extends StatefulWidget {
  final String fullName;
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const HomePage({
    super.key,
    required this.fullName,
    this.onLanguageChanged,
    this.currentLocale,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _chartMonths = 12;
  final Map<String, int> _selectedCategoryIndices = {};
  StreamSubscription<DatabaseEvent>? _categoriesSub;
  List<_CategoryStat> _categoryStats = const [];
  @override
  void initState() {
    super.initState();
    BillStore.instance.ensureListening();
    _categoriesSub = CategoriesRtdbHub.instance.stream.listen((event) {
      if (!mounted) return;
      setState(() {
        _categoryStats = _mapCategoryStats(event.snapshot.value);
      });
    });
  }

  @override
  void dispose() {
    _categoriesSub?.cancel();
    super.dispose();
  }

  /// Highlight + label default: last month when user has not tapped yet.
  int _effectiveChartIndex(int? selected, int length) {
    if (length <= 0) return 0;
    final i = selected ?? length - 1;
    if (i < 0) return 0;
    if (i >= length) return length - 1;
    return i;
  }

  ConsumptionSeries _buildCategorySeries(
    List<BillSummary> bills, {
    required String categoryName,
    required Locale locale,
    required int months,
  }) {
    final labels = buildMonthlyConsumptionSeries(
      const [],
      isElectricity: true,
      locale: locale,
      months: months,
    ).labels;
    final now = DateTime.now();
    final monthStarts = List.generate(months, (i) {
      return DateTime(now.year, now.month - (months - 1 - i), 1);
    });
    final values = List<double>.filled(months, 0);
    for (final bill in bills) {
      if (!_billMatchesCategory(categoryName, bill.type)) continue;
      final d = BillDateUtils.chartBucketDate(bill);
      for (var i = 0; i < months; i++) {
        final m = monthStarts[i];
        if (d.year == m.year && d.month == m.month) {
          final v =
              bill.consumptionValue ??
              bill.currentMonthAmount ??
              bill.totalAmount ??
              0;
          if (v > 0) values[i] += v;
          break;
        }
      }
    }
    return ConsumptionSeries(values: values, labels: labels);
  }

  bool _billMatchesCategory(String categoryName, String billType) {
    final categoryKey = BillTypeUtils.canonicalTypeKey(categoryName);
    final billKey = BillTypeUtils.canonicalTypeKey(billType);
    return categoryKey == billKey;
  }

  double _niceMax(List<double> values) {
    final maxValue =
        values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    if (maxValue <= 0) return 1;
    final rounded = (maxValue / 10).ceil() * 10;
    return rounded.toDouble();
  }

  String _formatTrend(List<double> values) {
    if (!_hasData(values)) return '+0.0%';
    if (values.length < 2) return '+0.0%';
    final last = values[values.length - 1];
    final prev = values[values.length - 2];
    if (prev == 0) return '+0.0%';
    final change = ((last - prev) / prev) * 100;
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(1)}%';
  }

  Color _trendColor(List<double> values) {
    if (!_hasData(values)) return const Color(0xFF43A047);
    if (values.length < 2) return const Color(0xFF43A047);
    final change = values.last - values[values.length - 2];
    return change >= 0 ? const Color(0xFFE53935) : const Color(0xFF43A047);
  }

  Color _trendBackground(List<double> values) {
    if (!_hasData(values)) return const Color(0xFFE8F5E9);
    if (values.length < 2) return const Color(0xFFE8F5E9);
    final change = values.last - values[values.length - 2];
    return change >= 0 ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);
  }

  bool _hasData(List<double> values) {
    return values.any((value) => value > 0);
  }

  String? _buildCategoryInsightLine(
    List<BillSummary> bills,
    List<_CategoryStat> categories,
    Locale locale,
  ) {
    if (categories.isEmpty) return null;
    _CategoryStat? bestCategory;
    double? bestRatio;
    double? bestLastValue;

    for (final category in categories) {
      final series = _buildCategorySeries(
        bills,
        categoryName: category.name,
        locale: locale,
        months: _chartMonths,
      );
      if (!_hasData(series.values)) continue;
      final last = series.values.last;
      if (last <= 0) continue;
      final baseline = _avgBeforeLast(series.values);
      final ratio = baseline != null && baseline > 0 ? (last / baseline) : null;

      if (bestCategory == null) {
        bestCategory = category;
        bestRatio = ratio;
        bestLastValue = last;
        continue;
      }
      final bestRatioValue = bestRatio ?? 0;
      final currentRatioValue = ratio ?? 0;
      if (currentRatioValue > bestRatioValue + 0.01 ||
          (currentRatioValue == bestRatioValue &&
              last > (bestLastValue ?? 0))) {
        bestCategory = category;
        bestRatio = ratio;
        bestLastValue = last;
      }
    }

    if (bestCategory == null || bestLastValue == null) return null;
    final isArabic = locale.languageCode == 'ar';
    final key = BillTypeUtils.canonicalTypeKey(bestCategory.name);
    final unit = key == 'water' ? 'm³' : key == 'electricity' ? 'kWh' : '';
    final ratioPct = ((bestRatio ?? 1) - 1) * 100;
    final trendText =
        ratioPct >= 0
            ? '+${ratioPct.toStringAsFixed(1)}%'
            : '${ratioPct.toStringAsFixed(1)}%';
    final valueText = bestLastValue.toStringAsFixed(bestLastValue % 1 == 0 ? 0 : 1);
    if (isArabic) {
      return 'الأكثر نشاطًا: ${bestCategory.name} ($valueText${unit.isEmpty ? '' : ' $unit'}, اتجاه $trendText)';
    }
    return 'Top active category: ${bestCategory.name} ($valueText${unit.isEmpty ? '' : ' $unit'}, trend $trendText)';
  }

  double? _avgBeforeLast(List<double> values) {
    if (values.length < 2) return null;
    final end = values.length - 1;
    final start = end - 3 < 0 ? 0 : end - 3;
    final slice = values.sublist(start, end);
    if (slice.isEmpty) return null;
    if (!slice.any((v) => v > 0)) return null;
    return slice.reduce((a, b) => a + b) / slice.length;
  }

  @override
  Widget build(BuildContext context) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final locale = Localizations.localeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final primaryText = isDark ? Colors.white : AppColors.textDark;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: BillStore.instance.initialLoading,
          builder: (context, loading, _) {
            if (loading) {
              return const Center(child: IosStyleLoading());
            }
            return SingleChildScrollView(
              child: Padding(
                padding: AppLayout.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderSection(
                      fullName: widget.fullName,
                      subtitle: localizations.userHomePage,
                      welcomeText: localizations.welcome,
                    ),
                    const SizedBox(height: 10),
                                    _UploadBillCard(
                                      title: localizations.uploadNewBill,
                                      subtitle: localizations.uploadBillHint,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const UploadBillPage(),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    ValueListenableBuilder<List<BillSummary>>(
                                      valueListenable: BillStore.instance.bills,
                                      builder: (context, bills, _) {
                                        final utilBills =
                                            BillListQuery.utilityBillsOnly(
                                              bills,
                                            );
                                        final total = utilBills.length;
                                        final items = [
                                          _CategoryStat(
                                            name: localizations.totalBills,
                                            count: total,
                                            icon: Icons.stacked_line_chart,
                                            color: const Color(0xFF0B1E39),
                                          ),
                                          ..._categoryStats.map(
                                            (item) => item.copyWith(
                                              count: _countForCategory(
                                                item.name,
                                                utilBills,
                                              ),
                                            ),
                                          ),
                                        ];
                                        return LayoutBuilder(
                                          builder: (context, constraints) {
                                            final maxWidth = constraints.maxWidth;
                                            final columns = (maxWidth / 128)
                                                .floor()
                                                .clamp(2, 4);
                                            return GridView.count(
                                              crossAxisCount: columns,
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              crossAxisSpacing: 12,
                                              mainAxisSpacing: 12,
                                              childAspectRatio: 1.28,
                                              children:
                                                  items
                                                      .map(
                                                        (item) => _StatTile(
                                                          title: item.name,
                                                          value:
                                                              item.count
                                                                  .toString(),
                                                          backgroundColor:
                                                              item.color,
                                                          icon: item.icon,
                                                        ),
                                                      )
                                                      .toList(),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    _SectionTitle(
                                      title:
                                          localizations
                                              .compareMonthlyConsumption,
                                      color: primaryText,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      localizations.chartPeriodLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: primaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SegmentedButton<int>(
                                      segments: [
                                        ButtonSegment<int>(
                                          value: 3,
                                          label: Text(
                                            localizations.chartMonthsShort3,
                                          ),
                                        ),
                                        ButtonSegment<int>(
                                          value: 6,
                                          label: Text(
                                            localizations.chartMonthsShort6,
                                          ),
                                        ),
                                        ButtonSegment<int>(
                                          value: 12,
                                          label: Text(
                                            localizations.chartMonthsShort12,
                                          ),
                                        ),
                                      ],
                                      selected: {_chartMonths},
                                      onSelectionChanged: (Set<int> next) {
                                        setState(() {
                                          _chartMonths = next.first;
                                          _selectedCategoryIndices.clear();
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.swipe_vertical_rounded,
                                          size: 16,
                                          color:
                                              isDark
                                                  ? const Color(0xFF9E9E9E)
                                                  : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            localizations.chartInteractionHint,
                                            style: TextStyle(
                                              fontSize: 11,
                                              height: 1.3,
                                              color:
                                                  isDark
                                                      ? const Color(0xFF9E9E9E)
                                                      : AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ValueListenableBuilder<List<BillSummary>>(
                                      valueListenable: BillStore.instance.bills,
                                      builder: (context, bills, _) {
                                        final allBills = bills;
                                        final dynamicCategories =
                                            _categoryStats
                                                .where(
                                                  (c) =>
                                                      c.name.trim().isNotEmpty,
                                                )
                                                .toList();
                                        return Column(
                                          children: [
                                            LayoutBuilder(
                                              builder: (context, constraints) {
                                                final isWide =
                                                    constraints.maxWidth >=
                                                    AppLayout.breakpointWideCharts;
                                                final cardWidth =
                                                    isWide
                                                        ? (constraints.maxWidth - 10) / 2
                                                        : constraints.maxWidth;
                                                return Wrap(
                                                  spacing: 10,
                                                  runSpacing: 10,
                                                  children:
                                                      dynamicCategories.map((
                                                        category,
                                                      ) {
                                                        final series =
                                                            _buildCategorySeries(
                                                              allBills,
                                                              categoryName:
                                                                  category.name,
                                                              locale: locale,
                                                              months:
                                                                  _chartMonths,
                                                            );
                                                        final chartUnit =
                                                            BillTypeUtils
                                                                        .canonicalTypeKey(
                                                                          category
                                                                              .name,
                                                                        ) ==
                                                                    'Electricity'
                                                                ? localizations
                                                                    .chartUnitKwh
                                                                : BillTypeUtils
                                                                            .canonicalTypeKey(
                                                                              category.name,
                                                                            ) ==
                                                                        'Water'
                                                                    ? localizations
                                                                        .chartUnitWater
                                                                    : '';
                                                        return SizedBox(
                                                          width: cardWidth,
                                                          child:
                                                              _ChartCardStyled(
                                                            title: category.name,
                                                            badge: _formatTrend(
                                                              series.values,
                                                            ),
                                                            badgeColor:
                                                                _trendColor(
                                                                  series.values,
                                                                ),
                                                            badgeBackground:
                                                                _trendBackground(
                                                                  series.values,
                                                                ),
                                                            child:
                                                                _hasData(
                                                                      series
                                                                          .values,
                                                                    )
                                                                    ? Column(
                                                                      children: [
                                                                        Expanded(
                                                                          child: Tooltip(
                                                                            message:
                                                                                localizations.chartInteractionHint,
                                                                            child: _InteractiveLineChart(
                                                                              values: series.values,
                                                                              maxValue: _niceMax(series.values),
                                                                              lineColor: category.color,
                                                                              yAxisUnit: chartUnit.isEmpty ? null : chartUnit,
                                                                              labels: series.labels,
                                                                              selectedIndex: _effectiveChartIndex(
                                                                                _selectedCategoryIndices[category.name],
                                                                                series.values.length,
                                                                              ),
                                                                              onSelected: (index) {
                                                                                setState(() {
                                                                                  _selectedCategoryIndices[category.name] = index;
                                                                                });
                                                                              },
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        _SelectedValueLabel(
                                                                          labels: series.labels,
                                                                          values: series.values,
                                                                          selectedIndex: _selectedCategoryIndices[category.name],
                                                                          suffix: chartUnit,
                                                                        ),
                                                                      ],
                                                                    )
                                                                    : _NoDataChart(
                                                                      text: localizations.noDataFound,
                                                                    ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                );
                                              },
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 10,
                                              ),
                                              child: Text(
                                                localizations.chartFootnoteOcr,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  height: 1.35,
                                                  color:
                                                      isDark
                                                          ? const Color(
                                                            0xFF9E9E9E,
                                                          )
                                                          : AppColors
                                                              .textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    ValueListenableBuilder<List<BillSummary>>(
                                      valueListenable: BillStore.instance.bills,
                                      builder: (context, bills, _) {
                                        final utilBills =
                                            BillListQuery.utilityBillsOnly(
                                              bills,
                                            );
                                        final snap =
                                            SmartAnalyticsInsights.build(
                                              utilBills,
                                              localizations,
                                              locale,
                                              seriesMonths: _chartMonths,
                                            );
                                        final dynamicCategories =
                                            _categoryStats
                                                .where(
                                                  (c) =>
                                                      c.name.trim().isNotEmpty,
                                                )
                                                .toList();
                                        final categoryInsight =
                                            _buildCategoryInsightLine(
                                              utilBills,
                                              dynamicCategories,
                                              locale,
                                            );
                                        return _SmartAnalyticsCard(
                                          title: localizations.smartAnalytics,
                                          primaryText: snap.primaryLine,
                                          secondaryText: snap.secondaryLine,
                                          tertiaryText: snap.tertiaryLine,
                                          alertText: snap.alertLine,
                                          categoryInsightText: categoryInsight,
                                          categoriesCount:
                                              dynamicCategories.length,
                                          onCategoriesTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => _UserCategoriesPage(
                                                      categories:
                                                          dynamicCategories
                                                              .map(
                                                                (c) {
                                                                  final series =
                                                                      _buildCategorySeries(
                                                                        utilBills,
                                                                        categoryName:
                                                                            c.name,
                                                                        locale:
                                                                            locale,
                                                                        months:
                                                                            _chartMonths,
                                                                      );
                                                                  final latest =
                                                                      series
                                                                          .values
                                                                          .isEmpty
                                                                      ? null
                                                                      : series
                                                                          .values
                                                                          .last;
                                                                  final avgBefore =
                                                                      _avgBeforeLast(
                                                                        series
                                                                            .values,
                                                                      );
                                                                  final growthPct =
                                                                      (latest != null &&
                                                                              avgBefore != null &&
                                                                              avgBefore > 0)
                                                                          ? ((latest - avgBefore) /
                                                                                  avgBefore) *
                                                                              100
                                                                          : null;
                                                                  return c.copyWith(
                                                                    count:
                                                                        _countForCategory(
                                                                          c.name,
                                                                          utilBills,
                                                                        ),
                                                                    latestValue:
                                                                        latest,
                                                                    growthPct:
                                                                        growthPct,
                                                                  );
                                                                },
                                                              )
                                                              .toList(),
                                                    ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    _SectionTitle(
                                      title: localizations.fastActions,
                                      color: primaryText,
                                    ),
                                    const SizedBox(height: 8),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        return Row(
                                          children: [
                                            Expanded(
                                              child: _ActionButton(
                                                label: localizations.help,
                                                icon: Icons.help_outline,
                                                backgroundColor: const Color(
                                                  0xFFFFF1B8,
                                                ),
                                                iconColor: AppColors.textDark,
                                                labelColor: AppColors.textDark,
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              const HelpPage(),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _ActionButton(
                                                label: localizations.feedback,
                                                icon: Icons.feedback_outlined,
                                                backgroundColor: const Color(
                                                  0xFFC8F7C5,
                                                ),
                                                iconColor: AppColors.textDark,
                                                labelColor: AppColors.textDark,
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              const FeedbackPage(),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryStat {
  final String name;
  final int count;
  final IconData icon;
  final Color color;
  final double? latestValue;
  final double? growthPct;

  const _CategoryStat({
    required this.name,
    required this.count,
    required this.icon,
    required this.color,
    this.latestValue,
    this.growthPct,
  });

  _CategoryStat copyWith({int? count, double? latestValue, double? growthPct}) {
    return _CategoryStat(
      name: name,
      count: count ?? this.count,
      icon: icon,
      color: color,
      latestValue: latestValue ?? this.latestValue,
      growthPct: growthPct ?? this.growthPct,
    );
  }
}

List<_CategoryStat> _mapCategoryStats(Object? data) {
  final items = <_CategoryStat>[];
  if (data is Map) {
    data.forEach((_, value) {
      if (value is Map) {
        final map = Map<dynamic, dynamic>.from(value);
        final name = map['name']?.toString() ?? '';
        final count = (map['billsCount'] as num?)?.toInt() ?? 0;
        final o = CategoryRtdbStyle.fromMap(map, name).overview;
        items.add(
          _CategoryStat(
            name: name,
            count: count,
            icon: o.icon,
            color: o.color,
          ),
        );
      }
    });
  }
  return items;
}

int _countForCategory(String name, List<BillSummary> bills) {
  final target = BillTypeUtils.canonicalTypeKey(name);
  return bills
      .where((bill) => BillTypeUtils.canonicalTypeKey(bill.type) == target)
      .length;
}

class _HeaderSection extends StatelessWidget {
  final String welcomeText;
  final String fullName;
  final String subtitle;

  const _HeaderSection({
    required this.welcomeText,
    required this.fullName,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : AppColors.textDark;
    final secondaryText =
        isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: Icon(Icons.person, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$welcomeText $fullName',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: secondaryText)),
            ],
          ),
        ),
      ],
    );
  }
}

class _UploadBillCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _UploadBillCard({
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadowColor =
        isDark
            ? Colors.black.withValues(alpha: 0.35)
            : AppColors.primary.withValues(alpha: 0.25);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(_cardRadius),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.cloud_upload,
                  color: AppColors.textOnDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.textOnDark),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textOnDark,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final Color backgroundColor;
  final IconData icon;

  const _StatTile({
    required this.title,
    required this.value,
    required this.backgroundColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPad = 7.0;
        const verticalPad = 7.0;
        final innerW = constraints.maxWidth > 2 * horizontalPad
            ? constraints.maxWidth - 2 * horizontalPad
            : 0.0;
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(_cardRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: verticalPad,
              horizontal: horizontalPad,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: SizedBox(
                width: innerW,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(icon, color: AppColors.textOnDark, size: 18),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChartCardStyled extends StatelessWidget {
  final String title;
  final String badge;
  final Color badgeColor;
  final Color badgeBackground;
  final Widget child;

  const _ChartCardStyled({
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.badgeBackground,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? const Color(0xFF1E1E1E) : AppColors.backgroundWhite;
    final borderColor =
        isDark ? const Color(0xFF2C2C2C) : AppColors.borderLight;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(height: 118, width: double.infinity, child: child),
        ],
      ),
    );
  }
}

class _BarChartWithAxis extends StatelessWidget {
  final List<double> values;
  final double maxValue;
  final Color barColor;
  final List<String> labels;
  final int selectedIndex;

  const _BarChartWithAxis({
    required this.values,
    required this.maxValue,
    required this.barColor,
    required this.labels,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _BarChartPainter(
          values: values,
          maxValue: maxValue,
          barColor: barColor,
          labels: labels,
          selectedIndex: selectedIndex,
        ),
      ),
    );
  }
}

class _LineChartWithAxis extends StatelessWidget {
  final List<double> values;
  final double maxValue;
  final Color lineColor;
  final List<String> labels;
  final String? yAxisUnit;
  final int selectedIndex;

  const _LineChartWithAxis({
    required this.values,
    required this.maxValue,
    required this.lineColor,
    required this.labels,
    this.yAxisUnit,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _LineChartPainterStyled(
          values: values,
          maxValue: maxValue,
          lineColor: lineColor,
          labels: labels,
          yAxisUnit: yAxisUnit,
          selectedIndex: selectedIndex,
        ),
      ),
    );
  }
}

class _ChartAxisHelper {
  final double leftPadding = 26;
  final double bottomPadding = 18;
  final double topPadding = 6;
  final double rightPadding = 6;
}

class _NoDataChart extends StatelessWidget {
  final String text;

  const _NoDataChart({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }
}

class _SelectedValueLabel extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final int? selectedIndex;
  final String suffix;

  const _SelectedValueLabel({
    required this.labels,
    required this.values,
    required this.selectedIndex,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox(height: 10);
    }
    final fallbackIndex = values.length - 1;
    final index =
        selectedIndex == null ||
                selectedIndex! < 0 ||
                selectedIndex! >= values.length
            ? fallbackIndex
            : selectedIndex!;
    final label = labels[index];
    final value = values[index].toStringAsFixed(0);
    final hasSuffix = suffix.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) {
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
        child: Align(
          key: ValueKey('$index-$label-$value'),
          alignment: Alignment.centerLeft,
          child: Text(
            hasSuffix ? '$label: $value ($suffix)' : '$label: $value',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveBarChart extends StatefulWidget {
  final List<double> values;
  final double maxValue;
  final Color barColor;
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _InteractiveBarChart({
    required this.values,
    required this.maxValue,
    required this.barColor,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<_InteractiveBarChart> createState() => _InteractiveBarChartState();
}

class _InteractiveBarChartState extends State<_InteractiveBarChart> {
  int? _lastEmitted;

  void _pickChartX(double localDx, double chartWidth) {
    final dx = localDx.clamp(0.0, chartWidth).toDouble();
    final index = _barIndexFromChartDx(dx, chartWidth, widget.labels.length);
    if (index != _lastEmitted) {
      _lastEmitted = index;
      HapticFeedback.selectionClick();
    }
    widget.onSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final axis = _ChartAxisHelper();
        final chartWidth =
            constraints.maxWidth - axis.leftPadding - axis.rightPadding;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            if (chartWidth <= 0) return;
            final dx = details.localPosition.dx - axis.leftPadding;
            _pickChartX(dx, chartWidth);
          },
          onHorizontalDragUpdate: (details) {
            if (chartWidth <= 0) return;
            final dx = details.localPosition.dx - axis.leftPadding;
            _pickChartX(dx, chartWidth);
          },
          child: _BarChartWithAxis(
            values: widget.values,
            maxValue: widget.maxValue,
            barColor: widget.barColor,
            labels: widget.labels,
            selectedIndex: widget.selectedIndex,
          ),
        );
      },
    );
  }
}

class _InteractiveLineChart extends StatefulWidget {
  final List<double> values;
  final double maxValue;
  final Color lineColor;
  final List<String> labels;
  final String? yAxisUnit;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _InteractiveLineChart({
    required this.values,
    required this.maxValue,
    required this.lineColor,
    required this.labels,
    this.yAxisUnit,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<_InteractiveLineChart> createState() => _InteractiveLineChartState();
}

class _InteractiveLineChartState extends State<_InteractiveLineChart> {
  int? _lastEmitted;

  void _pickChartX(double localDx, double chartWidth) {
    final dx = localDx.clamp(0.0, chartWidth).toDouble();
    final index = _lineIndexFromChartDx(dx, chartWidth, widget.labels.length);
    if (index != _lastEmitted) {
      _lastEmitted = index;
      HapticFeedback.selectionClick();
    }
    widget.onSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final axis = _ChartAxisHelper();
        final chartWidth =
            constraints.maxWidth - axis.leftPadding - axis.rightPadding;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            if (chartWidth <= 0) return;
            final dx = details.localPosition.dx - axis.leftPadding;
            _pickChartX(dx, chartWidth);
          },
          onHorizontalDragUpdate: (details) {
            if (chartWidth <= 0) return;
            final dx = details.localPosition.dx - axis.leftPadding;
            _pickChartX(dx, chartWidth);
          },
          child: _LineChartWithAxis(
            values: widget.values,
            maxValue: widget.maxValue,
            lineColor: widget.lineColor,
            labels: widget.labels,
            yAxisUnit: widget.yAxisUnit,
            selectedIndex: widget.selectedIndex,
          ),
        );
      },
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;
  final Color barColor;
  final List<String> labels;
  final int selectedIndex;

  _BarChartPainter({
    required this.values,
    required this.maxValue,
    required this.barColor,
    required this.labels,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final axis = _ChartAxisHelper();
    final chartWidth = size.width - axis.leftPadding - axis.rightPadding;
    final chartHeight = size.height - axis.topPadding - axis.bottomPadding;
    if (chartWidth <= 0 || chartHeight <= 0) return;

    final gridPaint =
        Paint()
          ..color = const Color(0xFFE3E7EE)
          ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = axis.topPadding + (chartHeight / 3) * i;
      canvas.drawLine(
        Offset(axis.leftPadding, y),
        Offset(axis.leftPadding + chartWidth, y),
        gridPaint,
      );
    }

    if (values.isEmpty) {
      _drawYAxisLabels(canvas, axis, size, maxValue);
      _drawXAxisLabels(canvas, axis, size, labels);
      return;
    }
    final barWidth = chartWidth / (values.length * 1.6);
    final gap = barWidth * 0.6;
    final sel = selectedIndex.clamp(0, values.length - 1);
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final height = (value / maxValue) * chartHeight;
      final left = axis.leftPadding + i * (barWidth + gap) + gap * 0.5;
      final top = axis.topPadding + chartHeight - height;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, height),
        const Radius.circular(6),
      );
      final isSel = i == sel;
      final fill =
          Paint()..color = isSel ? barColor : barColor.withValues(alpha: 0.38);
      canvas.drawRRect(rect, fill);
      if (isSel) {
        canvas.drawRRect(
          rect,
          Paint()
            ..color = const Color(0xFFFFFFFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    _drawYAxisLabels(canvas, axis, size, maxValue);
    _drawXAxisLabels(canvas, axis, size, labels);
  }

  void _drawYAxisLabels(
    Canvas canvas,
    _ChartAxisHelper axis,
    Size size,
    double maxValue,
  ) {
    final style = const TextStyle(fontSize: 9, color: Color(0xFF8A94A6));
    for (var i = 0; i <= 3; i++) {
      final value = maxValue - (maxValue / 3) * i;
      final text = value.toStringAsFixed(0);
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final y =
          axis.topPadding +
          (size.height - axis.topPadding - axis.bottomPadding) / 3 * i -
          tp.height / 2;
      tp.paint(canvas, Offset(0, y));
    }
  }

  void _drawXAxisLabels(
    Canvas canvas,
    _ChartAxisHelper axis,
    Size size,
    List<String> labels,
  ) {
    final style = const TextStyle(fontSize: 9, color: Color(0xFF8A94A6));
    final chartWidth = size.width - axis.leftPadding - axis.rightPadding;
    final step = chartWidth / (labels.length - 1);
    for (var i = 0; i < labels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = axis.leftPadding + step * i - tp.width / 2;
      final y = size.height - axis.bottomPadding + 2;
      tp.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.maxValue != maxValue ||
        oldDelegate.barColor != barColor ||
        oldDelegate.selectedIndex != selectedIndex ||
        !listEquals(oldDelegate.values, values) ||
        !listEquals(oldDelegate.labels, labels);
  }
}

class _LineChartPainterStyled extends CustomPainter {
  final List<double> values;
  final double maxValue;
  final Color lineColor;
  final List<String> labels;
  final String? yAxisUnit;
  final int selectedIndex;

  _LineChartPainterStyled({
    required this.values,
    required this.maxValue,
    required this.lineColor,
    required this.labels,
    this.yAxisUnit,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final axis = _ChartAxisHelper();
    final chartWidth = size.width - axis.leftPadding - axis.rightPadding;
    final chartHeight = size.height - axis.topPadding - axis.bottomPadding;
    if (chartWidth <= 0 || chartHeight <= 0) return;

    final gridPaint =
        Paint()
          ..color = const Color(0xFFE3E7EE)
          ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = axis.topPadding + (chartHeight / 3) * i;
      canvas.drawLine(
        Offset(axis.leftPadding, y),
        Offset(axis.leftPadding + chartWidth, y),
        gridPaint,
      );
    }

    if (values.isEmpty) {
      _drawYAxisLabels(canvas, axis, size, maxValue, yAxisUnit);
      _drawXAxisLabels(canvas, axis, size, labels);
      return;
    }
    final step = chartWidth / (values.length - 1);
    final path = Path();
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final x = axis.leftPadding + step * i;
      final y =
          axis.topPadding + chartHeight - (value / maxValue) * chartHeight;
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint =
        Paint()
          ..color = lineColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    final sel = selectedIndex.clamp(0, values.length - 1);
    final vx = points[sel].dx;
    final guidePaint =
        Paint()
          ..color = lineColor.withValues(alpha: 0.22)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(vx, axis.topPadding),
      Offset(vx, axis.topPadding + chartHeight),
      guidePaint,
    );

    for (var i = 0; i < points.length; i++) {
      final isSel = i == sel;
      final r = isSel ? 5.0 : 2.5;
      final dotPaint =
          Paint()
            ..color = isSel ? lineColor : lineColor.withValues(alpha: 0.45);
      canvas.drawCircle(points[i], r, dotPaint);
      if (isSel) {
        canvas.drawCircle(
          points[i],
          r + 2,
          Paint()
            ..color = lineColor.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }

    _drawYAxisLabels(canvas, axis, size, maxValue, yAxisUnit);
    _drawXAxisLabels(canvas, axis, size, labels);
  }

  void _drawYAxisLabels(
    Canvas canvas,
    _ChartAxisHelper axis,
    Size size,
    double maxValue,
    String? yAxisUnit,
  ) {
    final style = const TextStyle(fontSize: 9, color: Color(0xFF8A94A6));
    for (var i = 0; i <= 3; i++) {
      final value = maxValue - (maxValue / 3) * i;
      var text = value.toStringAsFixed(0);
      if (i == 0 && yAxisUnit != null && yAxisUnit.isNotEmpty) {
        text = '$text $yAxisUnit';
      }
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final y =
          axis.topPadding +
          (size.height - axis.topPadding - axis.bottomPadding) / 3 * i -
          tp.height / 2;
      tp.paint(canvas, Offset(0, y));
    }
  }

  void _drawXAxisLabels(
    Canvas canvas,
    _ChartAxisHelper axis,
    Size size,
    List<String> labels,
  ) {
    final style = const TextStyle(fontSize: 9, color: Color(0xFF8A94A6));
    final chartWidth = size.width - axis.leftPadding - axis.rightPadding;
    final step = chartWidth / (labels.length - 1);
    for (var i = 0; i < labels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = axis.leftPadding + step * i - tp.width / 2;
      final y = size.height - axis.bottomPadding + 2;
      tp.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainterStyled oldDelegate) {
    return oldDelegate.maxValue != maxValue ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.yAxisUnit != yAxisUnit ||
        !listEquals(oldDelegate.values, values) ||
        !listEquals(oldDelegate.labels, labels);
  }
}

class _SmartAnalyticsCard extends StatelessWidget {
  final String title;
  final String primaryText;
  final String secondaryText;
  final String? tertiaryText;
  final String? alertText;
  final String? categoryInsightText;
  final int categoriesCount;
  final VoidCallback? onCategoriesTap;

  const _SmartAnalyticsCard({
    required this.title,
    required this.primaryText,
    required this.secondaryText,
    this.tertiaryText,
    this.alertText,
    this.categoryInsightText,
    required this.categoriesCount,
    this.onCategoriesTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? const Color(0xFF1E1E1E) : AppColors.backgroundWhite;
    final borderColor =
        isDark ? const Color(0xFF2C2C2C) : AppColors.borderLight;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final mutedText =
        isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.lightbulb, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                _InsightRow(text: primaryText, color: mutedText),
                const SizedBox(height: 4),
                _InsightRow(text: secondaryText, color: mutedText),
                if (tertiaryText != null && tertiaryText!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _InsightRow(text: tertiaryText!, color: mutedText),
                ],
                if (alertText != null && alertText!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InsightAlertRow(text: alertText!),
                ],
                if (categoryInsightText != null &&
                    categoryInsightText!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InsightRow(text: categoryInsightText!, color: mutedText),
                ],
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onCategoriesTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.category_outlined, size: 14, color: mutedText),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isArabic
                                ? 'عدد التصنيفات المرتبطة: $categoriesCount'
                                : 'Linked categories count: $categoriesCount',
                            style: TextStyle(
                              color: mutedText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (onCategoriesTap != null)
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 14,
                            color: mutedText,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightAlertRow extends StatelessWidget {
  final String text;

  const _InsightAlertRow({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.warning_amber_rounded, color: color, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 12, height: 1.3),
          ),
        ),
      ],
    );
  }
}

enum _CategorySortMode { topActivity, topGrowth }

class _UserCategoriesPage extends StatefulWidget {
  final List<_CategoryStat> categories;

  const _UserCategoriesPage({required this.categories});

  @override
  State<_UserCategoriesPage> createState() => _UserCategoriesPageState();
}

class _UserCategoriesPageState extends State<_UserCategoriesPage> {
  _CategorySortMode _sortMode = _CategorySortMode.topActivity;

  List<_CategoryStat> _sortedCategories() {
    final list = List<_CategoryStat>.from(widget.categories);
    if (_sortMode == _CategorySortMode.topGrowth) {
      list.sort((a, b) {
        final ga = a.growthPct ?? -9999;
        final gb = b.growthPct ?? -9999;
        final byGrowth = gb.compareTo(ga);
        if (byGrowth != 0) return byGrowth;
        final la = a.latestValue ?? 0;
        final lb = b.latestValue ?? 0;
        final byLatest = lb.compareTo(la);
        if (byLatest != 0) return byLatest;
        return b.count.compareTo(a.count);
      });
      return list;
    }
    list.sort((a, b) {
      final la = a.latestValue ?? 0;
      final lb = b.latestValue ?? 0;
      final byLatest = lb.compareTo(la);
      if (byLatest != 0) return byLatest;
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      return (b.growthPct ?? -9999).compareTo(a.growthPct ?? -9999);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final loc =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final mutedText =
        isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary;
    final borderColor =
        isDark ? const Color(0xFF2C2C2C) : AppColors.borderLight;
    final sorted = _sortedCategories();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          loc.categoryPage,
          style: TextStyle(color: textColor),
        ),
        backgroundColor: background,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: textColor),
      ),
      body:
          widget.categories.isEmpty
              ? Center(
                child: Text(
                  loc.noDataFound,
                  style: TextStyle(color: mutedText),
                ),
              )
              : Column(
                children: [
                  Padding(
                    padding: AppLayout.pagePadding,
                    child: SegmentedButton<_CategorySortMode>(
                      segments: [
                        ButtonSegment<_CategorySortMode>(
                          value: _CategorySortMode.topActivity,
                          label: Text(
                            isArabic ? 'الأكثر نشاطًا' : 'Top activity',
                          ),
                        ),
                        ButtonSegment<_CategorySortMode>(
                          value: _CategorySortMode.topGrowth,
                          label: Text(isArabic ? 'الأعلى نموًا' : 'Top growth'),
                        ),
                      ],
                      selected: {_sortMode},
                      onSelectionChanged: (next) {
                        setState(() => _sortMode = next.first);
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: AppLayout.pagePadding,
                      itemCount: sorted.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final c = sorted[index];
                        final latest =
                            c.latestValue == null
                                ? (isArabic ? 'لا بيانات' : 'No data')
                                : c.latestValue!.toStringAsFixed(
                                  c.latestValue! % 1 == 0 ? 0 : 1,
                                );
                        final growth =
                            c.growthPct == null
                                ? (isArabic ? '—' : '—')
                                : '${c.growthPct! >= 0 ? '+' : ''}${c.growthPct!.toStringAsFixed(1)}%';
                        final growthColor =
                            c.growthPct == null
                                ? mutedText
                                : c.growthPct! >= 0
                                ? const Color(0xFFE65100)
                                : const Color(0xFF2E7D32);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color:
                                isDark
                                    ? const Color(0xFF1E1E1E)
                                    : AppColors.backgroundWhite,
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: c.color.withValues(alpha: 0.2),
                                child: Icon(c.icon, color: c.color, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isArabic
                                          ? 'آخر قراءة: $latest'
                                          : 'Latest: $latest',
                                      style: TextStyle(
                                        color: mutedText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${c.count}',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    growth,
                                    style: TextStyle(
                                      color: growthColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onTap;
  final IconData icon;
  final Color? labelColor;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.labelColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2C2C2C) : Colors.transparent;
    final textColor =
        labelColor ?? (isDark ? AppColors.textOnDark : AppColors.textDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String text;
  final Color color;

  const _InsightRow({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 14),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(color: color))),
      ],
    );
  }
}
