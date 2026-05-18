import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../constants/language.dart';
import '../data/bill_store.dart';
import '../models/bill_summary.dart';
import '../utils/bill_list_query.dart';
import '../services/categories_rtdb_hub.dart';
import '../utils/category_rtdb_style.dart';
import '../data/notification_store.dart';
import 'bill_details.dart';

class MyBillsPage extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const MyBillsPage({super.key, this.onLanguageChanged, this.currentLocale});

  @override
  State<MyBillsPage> createState() => _MyBillsPageState();
}

class _MyBillsPageState extends State<MyBillsPage> {
  String? _selectedFilterKey;
  String _searchQuery = '';
  BillSortOrder _sortOrder = BillSortOrder.newestFirst;
  final Set<String> _selectedIds = {};
  bool _selectionMode = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF0A0E14) : const Color(0xFFF8F9FA);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1F26);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: CategoriesRtdbHub.instance.stream,
          builder: (context, catSnapshot) {
            final categories = _parseCategories(catSnapshot.data?.snapshot.value);
            
            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectionMode 
                          ? (loc.locale.languageCode == 'ar' ? 'تم اختيار ${_selectedIds.length}' : '${_selectedIds.length} Selected') 
                          : loc.myBills,
                        style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      if (_selectionMode) Row(
                        children: [
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: _deleteSelected),
                          IconButton(icon: Icon(Icons.close, color: textColor), onPressed: () => setState(() { _selectionMode = false; _selectedIds.clear(); })),
                        ],
                      ) else ValueListenableBuilder<int>(
                        valueListenable: NotificationStore.instance.unreadCount,
                        builder: (context, count, _) {
                          return IconButton(
                            icon: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(Icons.notifications_none_outlined, color: textColor, size: 28),
                                if (count > 0)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: TweenAnimationBuilder<double>(
                                      duration: const Duration(milliseconds: 300),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      curve: Curves.elasticOut,
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                            child: Text(
                                              '$count',
                                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            onPressed: () {
                              NotificationStore.instance.markAllAsRead();
                              _showNotifications(loc, isDark);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                _buildSearchBar(loc, isDark, textColor),
                _buildDynamicSummarySection(loc, isDark, textColor, categories),
                _buildDynamicFilters(loc, isDark, categories),
                Expanded(child: _buildBillsList(loc, isDark, textColor, categories)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations loc, bool isDark, Color textColor) {
    final searchBg = isDark ? const Color(0xFF14181F) : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: searchBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: loc.locale.languageCode == 'ar' ? 'البحث في الفواتير...' : 'Search bills...',
            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(Icons.search, color: isDark ? Colors.white38 : Colors.grey[400], size: 20),
            suffixIcon: PopupMenuButton<BillSortOrder>(
              icon: Icon(Icons.tune, color: isDark ? Colors.white38 : Colors.grey[400], size: 20),
              color: isDark ? const Color(0xFF1A1F26) : Colors.white,
              offset: const Offset(0, 40),
              onSelected: (order) => setState(() => _sortOrder = order),
              itemBuilder: (context) => [
                PopupMenuItem(enabled: false, child: Text(loc.locale.languageCode == 'ar' ? 'الترتيب والتصفية' : 'Sort & Filter', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold))),
                const PopupMenuDivider(),
                PopupMenuItem(value: BillSortOrder.newestFirst, child: Row(children: [Icon(Icons.calendar_month_outlined, size: 16, color: _sortOrder == BillSortOrder.newestFirst ? Colors.blue : Colors.grey), const SizedBox(width: 8), Text(loc.locale.languageCode == 'ar' ? 'التاريخ (الأحدث)' : 'Date (Newest)', style: TextStyle(color: textColor, fontSize: 13))])),
                PopupMenuItem(value: BillSortOrder.oldestFirst, child: Row(children: [Icon(Icons.history, size: 16, color: _sortOrder == BillSortOrder.oldestFirst ? Colors.blue : Colors.grey), const SizedBox(width: 8), Text(loc.locale.languageCode == 'ar' ? 'التاريخ (الأقدم)' : 'Date (Oldest)', style: TextStyle(color: textColor, fontSize: 13))])),
              ],
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicSummarySection(AppLocalizations loc, bool isDark, Color textColor, Map<String, _CategoryData> categories) {
    return Container(
      height: 115,
      margin: const EdgeInsets.only(top: 8),
      child: ValueListenableBuilder<List<BillSummary>>(
        valueListenable: BillStore.instance.bills,
        builder: (context, bills, _) {
          final stats = _calculateDynamicStats(bills);
          if (stats.isEmpty) return const SizedBox.shrink();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: stats.length,
            itemBuilder: (ctx, index) {
              final entry = stats.entries.elementAt(index);
              final type = entry.key;
              final data = entry.value;
              final cat = _findCategoryByName(categories, type);
              final style = cat?.style ?? CategoryRtdbStyle.fallbackForName(type);
              
              // Find tip for this specific category
              final sameType = bills.where((b) => b.type == type).toList();
              String? categoryTip;
              if (sameType.length >= 2) {
                final diff = _calculateUsageDiff(sameType[0], sameType[1]);
                if (diff != null && diff > 0) {
                  categoryTip = _generateCategorySpecificTip(type, diff, loc);
                }
              }

              return _SummaryCard(
                title: cat != null ? cat.name : (loc.locale.languageCode == 'ar' ? (type == 'Electricity' ? 'الكهرباء' : (type == 'Water' ? 'المياه' : type)) : type),
                amount: data['amount'] ?? 0,
                usage: data['usage'] ?? 0,
                unit: _getUnitForType(type),
                icon: style.icon,
                color: style.cardColor,
                isDark: isDark,
                tip: categoryTip,
                onTipTap: categoryTip != null ? () => _showTipSheet(categoryTip!, cat?.name ?? type, style.icon, style.cardColor, isDark) : null,
              );
            },
          );
        },
      ),
    );
  }

  void _showTipSheet(String tip, String title, IconData icon, Color color, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F26) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 18))),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.withOpacity(0.1))),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 30),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      tip,
                      textAlign: AppLocalizations.of(context)?.locale.languageCode == 'ar' ? TextAlign.right : TextAlign.left,
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text(AppLocalizations.of(context)?.locale.languageCode == 'ar' ? 'فهمت' : 'Got it', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  String _generateCategorySpecificTip(String type, double diff, AppLocalizations loc) {
    final isAr = loc.locale.languageCode == 'ar';
    final month = DateTime.now().month;
    final isSummer = month >= 5 && month <= 10;
    
    String valStr;
    if (diff > 100) {
      valStr = isAr ? 'كبيرة جداً' : 'significantly';
    } else {
      valStr = '${diff.toStringAsFixed(0)}%';
    }

    if (type.toLowerCase().contains('electric') || type.contains('كهرب')) {
      if (isSummer) {
        return isAr
          ? 'نظراً لارتفاع درجات الحرارة، هناك زيادة ملحوظة في الاستهلاك. السبب المرجح هو أجهزة التكييف؛ نوصي بتنظيف الفلاتر وضبط الحرارة على 24 درجة.'
          : 'Due to summer heat, usage is up $valStr. Likely cause: ACs; try cleaning filters and setting temp to 24°C.';
      } else {
        return isAr
          ? 'لاحظنا ارتفاعاً في فاتورة الكهرباء. في هذا الموسم، غالباً ما تكون سخانات المياه هي المسبب الرئيسي لزيادة الاستهلاك.'
          : 'Electricity is up $valStr. During this season, water heaters or heating appliances are often the main cause.';
      }
    } else if (type.toLowerCase().contains('water') || type.contains('مياه')) {
      return isAr
        ? 'فاتورة المياه مرتفعة بشكل غير معتاد. ننصح بفحص الأنابيب الخارجية أو نظام الري، حيث تعد التسريبات الخفية السبب الأكثر شيوعاً للزيادة.'
        : 'Water usage increased by $valStr. We suggest checking external pipes or irrigation; hidden leaks are the most common cause.';
    } else {
      return isAr
        ? 'فاتورة $type مرتفعة هذا الشهر. نوصي بمراجعة نمط الاستخدام لتحديد الأجهزة التي تستهلك طاقة أكبر.'
        : '$type bills rose by $valStr. Reviewing your usage patterns this month can help identify the appliance causing the spike.';
    }
  }

  Widget _buildDynamicFilters(AppLocalizations loc, bool isDark, Map<String, _CategoryData> categories) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _FilterChip(label: loc.locale.languageCode == 'ar' ? 'الكل' : 'All', icon: Icons.grid_view_rounded, selected: _selectedFilterKey == null, color: const Color(0xFF5C6BC0), onTap: () => setState(() => _selectedFilterKey = null), isDark: isDark),
          const SizedBox(width: 8),
          ...categories.values.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(label: cat.name, icon: cat.style.icon, selected: _selectedFilterKey == cat.name, color: cat.style.cardColor, onTap: () => setState(() => _selectedFilterKey = cat.name), isDark: isDark),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBillsList(AppLocalizations loc, bool isDark, Color textColor, Map<String, _CategoryData> categories) {
    return ValueListenableBuilder<List<BillSummary>>(
      valueListenable: BillStore.instance.bills,
      builder: (context, bills, _) {
        final filtered = BillListQuery.applySort(
          BillListQuery.applySearch(_applyCategoryFilter(bills, _selectedFilterKey), _searchQuery),
          _sortOrder,
        );

        if (filtered.isEmpty) {
          return Center(child: Text(loc.noDataFound, style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[500])));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filtered.length,
          itemBuilder: (ctx, index) {
            final bill = filtered[index];
            final cat = _findCategoryByName(categories, bill.type);
            final style = cat?.style ?? CategoryRtdbStyle.fallbackForName(bill.type);
            final prevBill = _findPreviousBill(bills, bill);
            final usageDiff = _calculateUsageDiff(bill, prevBill);

            return _BillCard(
              bill: bill,
              usageDiff: usageDiff,
              isSelected: _selectedIds.contains(bill.id),
              selectionMode: _selectionMode,
              onTap: () => _selectionMode ? _toggleSelection(bill.id) : _viewDetails(bill),
              onLongPress: () => setState(() { _selectionMode = true; _selectedIds.add(bill.id); }),
              onDelete: () => _confirmDelete(bill.id),
              onSelect: () => _toggleSelection(bill.id),
              isDark: isDark,
              textColor: textColor,
              style: style,
            );
          },
        );
      },
    );
  }

  Map<String, Map<String, double>> _calculateDynamicStats(List<BillSummary> bills) {
    final stats = <String, Map<String, double>>{};
    for (var b in bills) {
      final type = b.type;
      if (!stats.containsKey(type)) stats[type] = {'amount': 0, 'usage': 0};
      stats[type]!['amount'] = (stats[type]!['amount'] ?? 0) + (b.totalAmount ?? 0);
      stats[type]!['usage'] = (stats[type]!['usage'] ?? 0) + (b.consumptionValue ?? 0);
    }
    return stats;
  }

  String _getUnitForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('electric') || t.contains('كهرب')) return 'kWh';
    if (t.contains('water') || t.contains('مياه')) return 'm³';
    return '';
  }

  Map<String, _CategoryData> _parseCategories(Object? value) {
    if (value == null) return {};
    final data = value as Map<dynamic, dynamic>;
    return data.map((key, val) {
      final name = (val['name'] ?? key).toString();
      return MapEntry(key.toString(), _CategoryData(name: name, style: CategoryRtdbStyle.fromMap(val as Map, name)));
    });
  }

  _CategoryData? _findCategoryByName(Map<String, _CategoryData> categories, String name) {
    final target = name.toLowerCase();
    for (var cat in categories.values) {
      if (cat.name.toLowerCase() == target) return cat;
    }
    return null;
  }

  List<BillSummary> _applyCategoryFilter(List<BillSummary> bills, String? key) {
    if (key == null) return bills;
    return bills.where((b) => b.type.toLowerCase() == key.toLowerCase()).toList();
  }

  BillSummary? _findPreviousBill(List<BillSummary> all, BillSummary current) {
    final sameType = all.where((b) => b.type == current.type && b.id != current.id).toList();
    sameType.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sameType.isNotEmpty ? sameType.first : null;
  }

  double? _calculateUsageDiff(BillSummary current, BillSummary? prev) {
    if (prev == null || current.consumptionValue == null || prev.consumptionValue == null || prev.consumptionValue == 0) return null;
    return ((current.consumptionValue! - prev.consumptionValue!) / prev.consumptionValue!) * 100;
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) _selectedIds.remove(id); else _selectedIds.add(id);
      if (_selectedIds.isEmpty) _selectionMode = false;
    });
  }

  void _viewDetails(BillSummary bill) => Navigator.push(context, MaterialPageRoute(builder: (context) => BillDetailsPage(bill: bill)));

  void _showNotifications(AppLocalizations loc, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1F26) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        title: Padding(
          padding: const EdgeInsets.all(12.0), // Slightly reduced padding
          child: Row(
            children: [
              const Icon(Icons.notifications_active_outlined, color: Colors.blue, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.locale.languageCode == 'ar' ? 'التنبيهات' : 'Notifications',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, size: 20, color: Colors.redAccent),
                onPressed: () {
                  NotificationStore.instance.clearAll();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ValueListenableBuilder<List<AppNotification>>(
            valueListenable: NotificationStore.instance.notifications,
            builder: (context, list, _) {
              if (list.isEmpty) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    Icon(Icons.mark_email_read_outlined, size: 60, color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                    const SizedBox(height: 16),
                    Text(loc.locale.languageCode == 'ar' ? 'أنت على اطلاع بكل شيء!' : 'You are all caught up!', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(loc.locale.languageCode == 'ar' ? 'لا توجد تنبيهات جديدة في الوقت الحالي.' : 'No new notifications at this time.', textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500], fontSize: 13)),
                    const SizedBox(height: 30),
                  ],
                );
              }
              return Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: list.length,
                  separatorBuilder: (c, i) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                  itemBuilder: (ctx, index) {
                    final n = list[index];
                    final color = n.type == NotificationType.success ? Colors.green : (n.type == NotificationType.warning ? Colors.orange : Colors.blue);
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(_getNotifIcon(n.type), color: color, size: 20)),
                      title: Text(n.title, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.body, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(_formatTime(n.timestamp, loc), style: TextStyle(color: isDark ? Colors.white24 : Colors.grey[400], fontSize: 10)),
                        ],
                      ),
                      isThreeLine: true,
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.locale.languageCode == 'ar' ? 'إغلاق' : 'Close', style: const TextStyle(color: Colors.blue))),
        ],
      ),
    );
  }

  IconData _getNotifIcon(NotificationType type) {
    switch (type) {
      case NotificationType.success: return Icons.check_circle_outline;
      case NotificationType.warning: return Icons.error_outline;
      case NotificationType.info: return Icons.info_outline;
    }
  }

  String _formatTime(DateTime dt, AppLocalizations loc) {
    final diff = DateTime.now().difference(dt);
    final isAr = loc.locale.languageCode == 'ar';
    if (diff.inMinutes < 1) return isAr ? 'الآن' : 'Just now';
    if (diff.inMinutes < 60) return isAr ? 'قبل ${diff.inMinutes} دقيقة' : '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return isAr ? 'قبل ${diff.inHours} ساعة' : '${diff.inHours}h ago';
    return isAr ? 'قبل ${diff.inDays} يوم' : '${diff.inDays}d ago';
  }

  Future<void> _confirmDelete(String id) async {
    final loc = AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1F26) : Colors.white,
        title: Text(loc.locale.languageCode == 'ar' ? 'حذف الفاتورة' : 'Delete Bill', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: Text(loc.locale.languageCode == 'ar' ? 'هل أنت متأكد؟' : 'Are you sure?', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(loc.locale.languageCode == 'ar' ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed == true) await BillStore.instance.deleteBill(id);
  }

  void _deleteSelected() async {
    final loc = AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1F26) : Colors.white,
        title: Text(loc.locale.languageCode == 'ar' ? 'حذف الفواتير' : 'Delete Bills', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: Text('${loc.locale.languageCode == 'ar' ? 'حذف' : 'Delete'} ${_selectedIds.length} ${loc.locale.languageCode == 'ar' ? 'فاتورة؟' : 'bills?'}', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(loc.locale.languageCode == 'ar' ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed == true) {
      for (var id in _selectedIds) await BillStore.instance.deleteBill(id);
      setState(() { _selectedIds.clear(); _selectionMode = false; });
    }
  }
}

class _CategoryData {
  final String name;
  final CategoryRtdbStyle style;
  const _CategoryData({required this.name, required this.style});
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final double usage;
  final String unit;
  final IconData icon;
  final Color color;
  final bool isDark;
  final String? tip;
  final VoidCallback? onTipTap;

  const _SummaryCard({required this.title, required this.amount, required this.usage, required this.unit, required this.icon, required this.color, required this.isDark, this.tip, this.onTipTap});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF14181F) : Colors.white;
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600], fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (tip != null)
                GestureDetector(
                  onTap: onTipTap,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 1.0, end: 1.3),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) => Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lightbulb, color: Colors.amber, size: 14),
                      ),
                    ),
                    onEnd: () {}, // For infinite loop, we would usually use an AnimationController, 
                    // but TweenAnimationBuilder with key or state change works too.
                  ),
                ),
            ],
          ),
          const Spacer(),
          FittedBox(fit: BoxFit.scaleDown, child: Text('${amount.toStringAsFixed(3)} OMR', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A1F26), fontWeight: FontWeight.bold, fontSize: 14))),
          if (unit.isNotEmpty) Text('${usage.toStringAsFixed(0)} $unit', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500], fontSize: 10)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterChip({required this.label, required this.icon, required this.selected, required this.color, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final chipBg = selected ? color : (isDark ? const Color(0xFF14181F) : Colors.white);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Colors.transparent : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
          boxShadow: selected || isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Row(children: [Icon(icon, color: selected ? Colors.white : color, size: 16), const SizedBox(width: 6), Text(label, style: TextStyle(color: selected ? Colors.white : (isDark ? Colors.white60 : Colors.grey[700]), fontWeight: FontWeight.w600, fontSize: 12))]),
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final BillSummary bill;
  final double? usageDiff;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;
  final VoidCallback onSelect;
  final bool isDark;
  final Color textColor;
  final CategoryRtdbStyle style;

  const _BillCard({required this.bill, this.usageDiff, required this.isSelected, required this.selectionMode, required this.onTap, required this.onLongPress, required this.onDelete, required this.onSelect, required this.isDark, required this.textColor, required this.style});

  @override
  Widget build(BuildContext context) {
    final indicatorColor = style.cardColor;
    final loc = AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final cardBg = isDark ? const Color(0xFF14181F) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? indicatorColor : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)), width: isSelected ? 2 : 1),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: indicatorColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(style.icon, color: indicatorColor, size: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.locale.languageCode == 'ar' 
                        ? (bill.type == 'Electricity' ? 'الكهرباء' : (bill.type == 'Water' ? 'المياه' : bill.type))
                        : bill.type, 
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)
                    ),
                    Text(bill.dateText, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500], fontSize: 11)),
                    if (usageDiff != null) ...[const SizedBox(height: 6), _buildUsageBadge(loc, usageDiff!)],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(bill.totalAmount?.toStringAsFixed(3) ?? '0.000', style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 15)),
                      const SizedBox(width: 4),
                      Text(loc.currencyOmr, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[400], fontSize: 9)),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: isDark ? Colors.white38 : Colors.grey[400], size: 18),
                        padding: EdgeInsets.zero,
                        color: isDark ? const Color(0xFF1A1F26) : Colors.white,
                        onSelected: (val) { if (val == 'delete') onDelete(); },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18), const SizedBox(width: 8), Text(loc.delete, style: const TextStyle(color: Colors.redAccent, fontSize: 13))])),
                        ],
                      ),
                    ],
                  ),
                  if (bill.consumptionValue != null) Text('${bill.consumptionValue!.toStringAsFixed(0)} ${bill.consumptionUnit ?? ''}', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500], fontSize: 10)),
                  const SizedBox(height: 8),
                  _buildAnalyzeButton(loc, isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsageBadge(AppLocalizations loc, double diff) {
    final isAr = loc.locale.languageCode == 'ar';
    final isLess = diff <= 0;
    final color = isLess ? const Color(0xFF4CAF50) : const Color(0xFFFFB300);
    final text = isAr 
      ? '${diff.abs().toStringAsFixed(0)}% ${isLess ? 'أقل' : 'أكثر'}'
      : '${diff.abs().toStringAsFixed(0)}% ${isLess ? 'less' : 'more'}';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), 
      child: Row(
        mainAxisSize: MainAxisSize.min, 
        children: [
          Icon(isLess ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 10), 
          const SizedBox(width: 2), 
          Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold))
        ]
      )
    );
  }

  Widget _buildAnalyzeButton(AppLocalizations loc, bool isDark) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1F26) : Colors.grey[50], borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.blue.withOpacity(0.3))), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.analytics_outlined, color: Colors.blue, size: 12), const SizedBox(width: 4), Text(loc.locale.languageCode == 'ar' ? 'تحليل' : 'Analyze', style: const TextStyle(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold))]));
  }
}
