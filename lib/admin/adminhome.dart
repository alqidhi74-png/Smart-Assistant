import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../constants/app_layout.dart';
import '../constants/colors.dart';
import '../constants/language.dart';
import '../utils/account_actions.dart';
import '../utils/bill_type_utils.dart';
import '../services/categories_rtdb_hub.dart';
import '../utils/category_rtdb_style.dart';
import 'sidebar.dart';
import 'category.dart';
import 'userdetails.dart';
import 'profile.dart';
import 'feedback.dart';

class AdminHome extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const AdminHome({super.key, this.onLanguageChanged, this.currentLocale});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _fullName = 'Admin';
  int _userCount = 0;
  StreamSubscription<DatabaseEvent>? _usersCountSub;
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child(
    'users',
  );
  final DatabaseReference _billsRef = FirebaseDatabase.instance.ref().child(
    'my_bills',
  );

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _listenUserCount();
  }

  @override
  void dispose() {
    _usersCountSub?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final dbRef = FirebaseDatabase.instance.ref();
        final snapshot = await dbRef.child('users/${user.uid}').get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          setState(() {
            _fullName = data['fullName'] as String? ?? 'Admin';
          });
        }
      }
    } catch (_) {}
  }

  void _listenUserCount() {
    _usersCountSub = _usersRef.onValue.listen((event) {
      final value = event.snapshot.value;
      int count = 0;
      if (value is Map) {
        count = value.length;
      }
      if (mounted) {
        setState(() {
          _userCount = count;
        });
      }
    });
  }

  Future<void> _openAccountMenu() async {
    final currentLocale = widget.currentLocale ?? const Locale('en');
    await AccountActions.showAccountSwitcherSheet(
      context: context,
      onLanguageChanged: widget.onLanguageChanged,
      currentLocale: currentLocale,
    );
  }

  Future<void> _logout() async {
    await AccountActions.showLogoutChoiceAndExecute(context);
  }

  void _openPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = widget.currentLocale ?? const Locale('en');
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          localizations.adminPageTitle,
          style: TextStyle(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.textDark,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.textDark,
          ),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            tooltip: localizations.accountsTitle,
            onPressed: _openAccountMenu,
            icon: CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: Icon(Icons.person, color: AppColors.primary),
            ),
          ),
        ],
      ),
      drawer: AdminSidebar(
        adminName: _fullName,
        onHome: () {},
        onCategory:
            () => _openPage(
              AdminCategoryPage(
                onLanguageChanged: widget.onLanguageChanged,
                currentLocale: currentLocale,
              ),
            ),
        onUserDetails:
            () => _openPage(
              AdminUserDetailsPage(
                onLanguageChanged: widget.onLanguageChanged,
                currentLocale: currentLocale,
              ),
            ),
        onFeedback:
            () => _openPage(
              AdminFeedbackPage(
                onLanguageChanged: widget.onLanguageChanged,
                currentLocale: currentLocale,
              ),
            ),
        onSettings:
            () => _openPage(
              AdminProfilePage(
                onLanguageChanged: widget.onLanguageChanged,
                currentLocale: currentLocale,
              ),
            ),
        onLogout: _logout,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: AppLayout.pagePadding,
          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              localizations.overview,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            StreamBuilder<DatabaseEvent>(
                              stream: CategoriesRtdbHub.instance.stream,
                              builder: (context, categorySnapshot) {
                                final categoryItems = _mapCategoryStats(
                                  categorySnapshot.data?.snapshot.value,
                                );
                                return StreamBuilder<DatabaseEvent>(
                                  stream: _billsRef.onValue,
                                  builder: (context, billsSnapshot) {
                                    final bills = _mapBills(
                                      billsSnapshot.data?.snapshot.value,
                                    );
                                    final billCounts = _countBillsByType(bills);
                                    final categories = _applyBillCounts(
                                      categoryItems,
                                      billCounts,
                                    );
                                    final totalBills = billCounts.values
                                        .fold<int>(
                                          0,
                                          (sum, count) => sum + count,
                                        );
                                    final locale = Localizations.localeOf(
                                      context,
                                    );
                                    final months = _buildMonthBuckets(
                                      DateTime.now(),
                                      7,
                                    );
                                    final labels =
                                        months
                                            .map(
                                              (date) =>
                                                  _formatMonth(date, locale),
                                            )
                                            .toList();
                                    final chartSeries =
                                        categories
                                            .map(
                                              (item) => _CategoryChartSeries(
                                                title: item.title,
                                                color: item.color,
                                                values: _buildMonthlySeries(
                                                  bills,
                                                  months: months,
                                                  type: item.title,
                                                  useTotalAmount: true,
                                                ).values,
                                              ),
                                            )
                                            .toList();
                                    final overviewItems = [
                                      _OverviewItem(
                                        title: localizations.totalBills,
                                        value: totalBills.toString(),
                                        icon: Icons.receipt_long,
                                        color: const Color(0xFF33C26E),
                                        count: totalBills,
                                      ),
                                      _OverviewItem(
                                        title: localizations.users,
                                        value: _userCount.toString(),
                                        icon: Icons.person,
                                        color: const Color(0xFFF2C84B),
                                        count: _userCount,
                                      ),
                                      ...categories,
                                    ];
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            return GridView.count(
                                              crossAxisCount: 2,
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              crossAxisSpacing: 8,
                                              mainAxisSpacing: 8,
                                              childAspectRatio:
                                                  constraints.maxWidth < 420
                                                      ? 1.35
                                                      : 2.0,
                                              children:
                                                  overviewItems
                                                      .map(
                                                        (item) =>
                                                            _buildOverviewCard(
                                                              title: item.title,
                                                              value: item.value,
                                                              icon: item.icon,
                                                              color: item.color,
                                                            ),
                                                      )
                                                      .toList(),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          localizations.dashboard,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : AppColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildChartCard(
                                          title:
                                              localizations.billsDistribution,
                                          minHeight: 228,
                                          child: _BillsDistributionChart(
                                            items: categories,
                                            emptyText:
                                                localizations.noDataFound,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildChartCard(
                                          title: localizations.billsTrend,
                                          minHeight: 228,
                                          child: _BillsTrendChart(
                                            labels: labels,
                                            series: chartSeries,
                                            emptyText:
                                                localizations.noDataFound,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildChartCard(
                                          title: localizations.monthlyOverview,
                                          minHeight: 238,
                                          child: _MonthlyBarChart(
                                            labels: labels,
                                            series: chartSeries,
                                            emptyText:
                                                localizations.noDataFound,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 5, 7, 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.backgroundWhite, size: 13),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.backgroundWhite,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.backgroundWhite,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          SizedBox(
            width: 28,
            height: 12,
            child: CustomPaint(painter: _SparkLinePainter()),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required Widget child,
    double minHeight = 140,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? const Color(0xFF2F2F2F) : AppColors.backgroundWhite;
    final borderColor =
        isDark ? Colors.transparent : const Color(0xFFE0E4EA);
    final titleColor = isDark ? AppColors.backgroundWhite : AppColors.textDark;
    final contentHeight = (minHeight - 52).clamp(110.0, 1000.0).toDouble();
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: contentHeight,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _OverviewItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final int count;

  const _OverviewItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.count,
  });
}

class _CategoryChartSeries {
  final String title;
  final Color color;
  final List<double> values;

  const _CategoryChartSeries({
    required this.title,
    required this.color,
    required this.values,
  });
}

class _BillEntry {
  final String type;
  final int createdAt;
  final double? totalAmount;
  final double? consumptionValue;

  const _BillEntry({
    required this.type,
    required this.createdAt,
    required this.totalAmount,
    this.consumptionValue,
  });
}

class _MonthlySeries {
  final List<double> values;

  const _MonthlySeries(this.values);
}

List<_OverviewItem> _mapCategoryStats(Object? data) {
  final items = <_OverviewItem>[];
  if (data is Map) {
    data.forEach((_, value) {
      if (value is Map) {
        final map = Map<dynamic, dynamic>.from(value);
        final name = map['name']?.toString() ?? '';
        final count = (map['billsCount'] as num?)?.toInt() ?? 0;
        final o = CategoryRtdbStyle.fromMap(map, name).overview;
        items.add(
          _OverviewItem(
            title: name,
            value: count.toString(),
            icon: o.icon,
            color: o.color,
            count: count,
          ),
        );
      }
    });
  }
  return items;
}

List<_BillEntry> _mapBills(Object? data) {
  final entries = <_BillEntry>[];
  if (data is Map) {
    for (final userEntry in data.values) {
      if (userEntry is Map) {
        for (final billEntry in userEntry.values) {
          if (billEntry is Map) {
            final rawType = billEntry['type']?.toString() ?? '';
            final type = BillTypeUtils.canonicalTypeKey(rawType);
            final createdAt =
                int.tryParse(billEntry['createdAt']?.toString() ?? '') ?? 0;
            final totalAmount = (billEntry['totalAmount'] as num?)?.toDouble();
            final consumptionValue =
                (billEntry['consumptionValue'] as num?)?.toDouble();
            if (type.isNotEmpty) {
              entries.add(
                _BillEntry(
                  type: type,
                  createdAt: createdAt,
                  totalAmount: totalAmount,
                  consumptionValue: consumptionValue,
                ),
              );
            }
          }
        }
      }
    }
  }
  return entries;
}

Map<String, int> _countBillsByType(List<_BillEntry> bills) {
  final counts = <String, int>{};
  for (final bill in bills) {
    final type = BillTypeUtils.canonicalTypeKey(bill.type);
    counts[type] = (counts[type] ?? 0) + 1;
  }
  return counts;
}

_MonthlySeries _buildMonthlySeries(
  List<_BillEntry> bills, {
  required List<DateTime> months,
  required String type,
  required bool useTotalAmount,
}) {
  final key = BillTypeUtils.canonicalTypeKey(type);
  final values = List<double>.filled(months.length, 0);
  for (final bill in bills) {
    if (BillTypeUtils.canonicalTypeKey(bill.type) != key) continue;
    if (bill.createdAt == 0) continue;
    final date = DateTime.fromMillisecondsSinceEpoch(bill.createdAt);
    for (var i = 0; i < months.length; i++) {
      final month = months[i];
      if (month.year == date.year && month.month == date.month) {
        if (useTotalAmount) {
          if (bill.totalAmount != null) {
            values[i] += bill.totalAmount!;
          }
        } else {
          values[i] += 1;
        }
        break;
      }
    }
  }
  return _MonthlySeries(values);
}

List<_OverviewItem> _applyBillCounts(
  List<_OverviewItem> categories,
  Map<String, int> billCounts,
) {
  if (categories.isEmpty) {
    return billCounts.entries.map((entry) {
      final o = CategoryRtdbStyle.fallbackForName(entry.key).overview;
      return _OverviewItem(
        title: entry.key,
        value: entry.value.toString(),
        icon: o.icon,
        color: o.color,
        count: entry.value,
      );
    }).toList();
  }
  final items =
      categories.map((item) {
        final count = _countForCategoryName(item.title, billCounts);
        return _OverviewItem(
          title: item.title,
          value: count.toString(),
          icon: item.icon,
          color: item.color,
          count: count,
        );
      }).toList();
  final existingKeys =
      items.map((item) => BillTypeUtils.canonicalTypeKey(item.title)).toSet();
  for (final entry in billCounts.entries) {
    if (!existingKeys.contains(entry.key)) {
      final o = CategoryRtdbStyle.fallbackForName(entry.key).overview;
      items.add(
        _OverviewItem(
          title: entry.key,
          value: entry.value.toString(),
          icon: o.icon,
          color: o.color,
          count: entry.value,
        ),
      );
    }
  }
  return items;
}

int _countForCategoryName(String name, Map<String, int> billCounts) {
  final key = BillTypeUtils.canonicalTypeKey(name);
  if (billCounts.containsKey(key)) {
    return billCounts[key] ?? 0;
  }
  return 0;
}

List<DateTime> _buildMonthBuckets(DateTime now, int count) {
  final months = <DateTime>[];
  for (var i = count - 1; i >= 0; i--) {
    months.add(DateTime(now.year, now.month - i, 1));
  }
  return months;
}

String _formatMonth(DateTime date, Locale locale) {
  try {
    return DateFormat.MMM(locale.toString()).format(date);
  } catch (_) {
    return '${date.month}';
  }
}

String _percentage(int value, int total) {
  if (total == 0) return '';
  final percent = ((value / total) * 100).round();
  return '$percent%';
}

LineChartBarData _buildLineSeries({
  required List<double> values,
  required Color color,
}) {
  return LineChartBarData(
    spots:
        values
            .asMap()
            .entries
            .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
            .toList(),
    isCurved: true,
    color: color,
    barWidth: 2,
    dotData: FlDotData(show: false),
    belowBarData: BarAreaData(
      show: true,
      gradient: LinearGradient(
        colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
  );
}

class _SparkLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
    final path =
        Path()
          ..moveTo(0, size.height * 0.8)
          ..lineTo(size.width * 0.3, size.height * 0.55)
          ..lineTo(size.width * 0.6, size.height * 0.7)
          ..lineTo(size.width, size.height * 0.35);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BillsDistributionChart extends StatelessWidget {
  final List<_OverviewItem> items;
  final String emptyText;

  const _BillsDistributionChart({required this.items, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    final data = items.where((item) => item.title.trim().isNotEmpty).toList();
    if (data.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
      );
    }
    final total = data.fold<int>(0, (sum, item) => sum + item.count);
    final pieData = data.where((item) => item.count > 0).toList();
    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 24,
              startDegreeOffset: -90,
              sections:
                  pieData
                      .map(
                        (item) => PieChartSectionData(
                          value: item.count.toDouble(),
                          color: item.color,
                          showTitle: false,
                          radius: 18,
                        ),
                      )
                      .toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children:
              data
                  .map(
                    (item) => _LegendItem(
                      color: item.color,
                      label:
                          '${item.title} (${item.count}) ${_percentage(item.count, total)}',
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.backgroundWhite : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _BillsTrendChart extends StatelessWidget {
  final List<String> labels;
  final List<_CategoryChartSeries> series;
  final String emptyText;

  const _BillsTrendChart({
    required this.labels,
    required this.series,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final faintText =
        isDark
            ? Colors.white.withValues(alpha: 0.7)
            : AppColors.textSecondary;
    final axisText =
        isDark
            ? Colors.white.withValues(alpha: 0.6)
            : AppColors.textSecondary;
    final hGrid =
        isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFDDE3EC);
    final vGrid =
        isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFE7ECF3);
    final borderColor =
        isDark
            ? Colors.white.withValues(alpha: 0.1)
            : const Color(0xFFD3DAE5);
    final values = series.expand((s) => s.values).toList();
    final maxValue =
        values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) {
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(color: faintText),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
        minX: 0,
        maxX: (labels.length - 1).toDouble(),
        minY: 0,
        maxY: maxValue * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine:
              (value) =>
                  FlLine(
                    color: hGrid,
                    strokeWidth: 1,
                  ),
          getDrawingVerticalLine:
              (value) =>
                  FlLine(
                    color: vGrid,
                    strokeWidth: 1,
                  ),
        ),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget:
                  (value, meta) => Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: axisText,
                      fontSize: 9,
                    ),
                  ),
              interval: maxValue > 0 ? maxValue / 3 : 1,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: axisText,
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: borderColor),
            bottom: BorderSide(color: borderColor),
          ),
        ),
        lineBarsData:
            series
                .map((s) => _buildLineSeries(values: s.values, color: s.color))
                .toList(),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children:
              series
                  .map((s) => _LegendItem(color: s.color, label: s.title))
                  .toList(),
        ),
      ],
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final List<String> labels;
  final List<_CategoryChartSeries> series;
  final String emptyText;

  const _MonthlyBarChart({
    required this.labels,
    required this.series,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final faintText =
        isDark
            ? Colors.white.withValues(alpha: 0.7)
            : AppColors.textSecondary;
    final axisText =
        isDark
            ? Colors.white.withValues(alpha: 0.6)
            : AppColors.textSecondary;
    final hGrid =
        isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFDDE3EC);
    final borderColor =
        isDark
            ? Colors.white.withValues(alpha: 0.1)
            : const Color(0xFFD3DAE5);
    final values = series.expand((s) => s.values).toList();
    final maxValue =
        values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) {
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(color: faintText),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
        maxY: maxValue * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine:
              (value) =>
                  FlLine(
                    color: hGrid,
                    strokeWidth: 1,
                  ),
        ),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget:
                  (value, meta) => Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: axisText,
                      fontSize: 9,
                    ),
                  ),
              interval: maxValue > 0 ? maxValue / 3 : 1,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: axisText,
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: borderColor),
            bottom: BorderSide(color: borderColor),
          ),
        ),
        barGroups: List.generate(labels.length, (index) {
          final visibleSeries =
              series.where((s) => index < s.values.length).toList();
          final barsSpace = visibleSeries.length <= 1 ? 0.0 : 4.0;
          final rodWidth = visibleSeries.length > 4 ? 4.0 : 6.0;
          return BarChartGroupData(
            x: index,
            barsSpace: barsSpace,
            barRods:
                visibleSeries
                    .map(
                      (s) => BarChartRodData(
                        toY: s.values[index],
                        width: rodWidth,
                        borderRadius: BorderRadius.circular(2),
                        color: s.color,
                      ),
                    )
                    .toList(),
          );
        }),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children:
              series
                  .map((s) => _LegendItem(color: s.color, label: s.title))
                  .toList(),
        ),
      ],
    );
  }
}
