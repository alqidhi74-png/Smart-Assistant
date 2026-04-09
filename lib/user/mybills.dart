import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import '../constants/app_layout.dart';
import '../constants/colors.dart';
import '../constants/language.dart';
import '../utils/bill_list_query.dart';
import '../utils/omr_format.dart';
import '../data/bill_store.dart';
import '../services/categories_rtdb_hub.dart';
import '../models/bill_summary.dart';
import '../utils/bill_type_utils.dart';
import '../utils/category_rtdb_style.dart';
import '../utils/loading_overlay.dart';
import 'bill_details.dart';

enum _SortOption { dateNewest, dateOldest }

class MyBillsPage extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const MyBillsPage({super.key, this.onLanguageChanged, this.currentLocale});

  @override
  State<MyBillsPage> createState() => _MyBillsPageState();
}

class _MyBillsPageState extends State<MyBillsPage> {
  String? _selectedFilterKey;
  _SortOption _sortOption = _SortOption.dateNewest;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedIds = {};
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    BillStore.instance.ensureListening();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BillSummary> _applyCategoryFilter(
    List<BillSummary> bills,
    String? selectedFilterKey,
  ) {
    if (selectedFilterKey == null) return bills;
    return bills.where((bill) {
      final billKey = BillTypeUtils.canonicalTypeKey(bill.type);
      return billKey == selectedFilterKey;
    }).toList();
  }

  List<_CategoryFilterChipData> _parseCategoryFilters(
    Object? data,
    AppLocalizations localizations,
  ) {
    final chips = <_CategoryFilterChipData>[
      _CategoryFilterChipData(
        key: null,
        label: localizations.filterAll,
        icon: Icons.tune,
        color: const Color(0xFF5DAAFB),
      ),
    ];
    if (data is Map) {
      data.forEach((_, value) {
        if (value is Map) {
          final map = Map<dynamic, dynamic>.from(value);
          final name = map['name']?.toString().trim() ?? '';
          if (name.isEmpty) return;
          final style = CategoryRtdbStyle.fromMap(map, name).overview;
          chips.add(
            _CategoryFilterChipData(
              key: BillTypeUtils.canonicalTypeKey(name),
              label: name,
              icon: style.icon,
              color: style.color,
            ),
          );
        }
      });
    }
    return chips;
  }

  BillSortOrder _sortOrder(_SortOption s) {
    switch (s) {
      case _SortOption.dateNewest:
        return BillSortOrder.newestFirst;
      case _SortOption.dateOldest:
        return BillSortOrder.oldestFirst;
    }
  }

  Future<void> _onRefresh() async {
    await BillStore.instance.refresh();
    if (mounted) setState(() {});
  }

  void _showSortFilterSheet() {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.sortAndFilter,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ..._SortOption.values.map((option) {
                  String label;
                  switch (option) {
                    case _SortOption.dateNewest:
                      label = localizations.sortByDateNewest;
                      break;
                    case _SortOption.dateOldest:
                      label = localizations.sortByDateOldest;
                      break;
                  }
                  return ListTile(
                    title: Text(label),
                    trailing:
                        _sortOption == option
                            ? Icon(Icons.check, color: AppColors.primary)
                            : null,
                    onTap: () {
                      setState(() => _sortOption = option);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteAll(int count) async {
    if (count == 0) return;
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations.deleteAll),
            content: Text(localizations.deleteAllConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(localizations.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: Text(localizations.delete),
              ),
            ],
          ),
    );
    if (ok == true && mounted) {
      final bills = BillStore.instance.bills.value;
      for (final b in bills) {
        await BillStore.instance.deleteBill(b.id);
      }
      setState(() {
        _selectedIds.clear();
        _selectionMode = false;
      });
    }
  }

  Future<void> _confirmDeleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations.deleteSelected),
            content: Text(localizations.deleteSelectedConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(localizations.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: Text(localizations.delete),
              ),
            ],
          ),
    );
    if (ok == true && mounted) {
      for (final id in _selectedIds) {
        await BillStore.instance.deleteBill(id);
      }
      setState(() {
        _selectedIds.clear();
        _selectionMode = false;
      });
    }
  }

  void _toggleSelectAll(List<BillSummary> filtered) {
    if (_selectedIds.length >= filtered.length) {
      setState(() {
        for (final b in filtered) {
          _selectedIds.remove(b.id);
        }
      });
    } else {
      setState(() {
        for (final b in filtered) {
          _selectedIds.add(b.id);
        }
      });
    }
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _enterSelectionMode(String firstSelectedId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectionMode = true;
      _selectedIds.add(firstSelectedId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading:
            Navigator.of(context).canPop()
                ? BackButton(color: textColor)
                : null,
        title: Text(localizations.myBills),
        backgroundColor: background,
        elevation: 0,
        foregroundColor: textColor,
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: IconButton(
              icon: const Icon(Icons.sort_rounded),
              iconSize: 30,
              onPressed: _showSortFilterSheet,
              tooltip: localizations.sortAndFilter,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: AppLayout.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: localizations.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isEmpty
                        ? null
                        : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            FocusScope.of(context).unfocus();
                          },
                          tooltip: localizations.cancel,
                        ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<DatabaseEvent>(
              stream: CategoriesRtdbHub.instance.stream,
              builder: (context, snapshot) {
                final filters = _parseCategoryFilters(
                  snapshot.data?.snapshot.value,
                  localizations,
                );
                final validKeys = filters.map((f) => f.key).toSet();
                if (!validKeys.contains(_selectedFilterKey)) {
                  _selectedFilterKey = null;
                }
                return _FilterChips(
                  filters: filters,
                  selectedKey: _selectedFilterKey,
                  onChanged:
                      (key) => setState(() => _selectedFilterKey = key),
                  isDark: isDark,
                );
              },
            ),
            const SizedBox(height: 12),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child:
                  _selectionMode
                      ? TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 6 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: ValueListenableBuilder<List<BillSummary>>(
                          valueListenable: BillStore.instance.bills,
                          builder: (context, bills, _) {
                            final filtered = BillListQuery.applySort(
                              BillListQuery.applySearch(
                                _applyCategoryFilter(bills, _selectedFilterKey),
                                _searchQuery,
                              ),
                              _sortOrder(_sortOption),
                            );
                            final allSelected =
                                filtered.isNotEmpty &&
                                _selectedIds.length >= filtered.length;
                            return _SelectionToolbar(
                              allSelected: allSelected,
                              hasSelection: _selectedIds.isNotEmpty,
                              filteredNotEmpty: filtered.isNotEmpty,
                              filteredLength: filtered.length,
                              onSelectAll: () => _toggleSelectAll(filtered),
                              onDeleteSelected: _confirmDeleteSelected,
                              onDeleteAll:
                                  () => _confirmDeleteAll(filtered.length),
                              onCancel: _exitSelectionMode,
                            );
                          },
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: BillStore.instance.initialLoading,
                builder: (context, loading, _) {
                  if (loading) {
                    return const IosStyleLoading();
                  }
                  return ValueListenableBuilder<List<BillSummary>>(
                    valueListenable: BillStore.instance.bills,
                    builder: (context, bills, _) {
                      final filtered = BillListQuery.applySort(
                        BillListQuery.applySearch(
                          _applyCategoryFilter(bills, _selectedFilterKey),
                          _searchQuery,
                        ),
                        _sortOrder(_sortOption),
                      );
                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          CupertinoSliverRefreshControl(onRefresh: _onRefresh),
                          if (filtered.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Text(
                                  localizations.noDataFound,
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? Colors.white70
                                            : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final bill = filtered[index];
                                final selected = _selectedIds.contains(bill.id);
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        index < filtered.length - 1 ? 12 : 0,
                                  ),
                                  child: _BillCard(
                                    bill: bill,
                                    analysisLabel: localizations.analysis,
                                    consumptionLabel: localizations.consumption,
                                    isDark: isDark,
                                    selectionMode: _selectionMode,
                                    isSelected: selected,
                                    onTap: () {
                                      if (_selectionMode) {
                                        setState(() {
                                          if (selected) {
                                            _selectedIds.remove(bill.id);
                                          } else {
                                            _selectedIds.add(bill.id);
                                          }
                                        });
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    BillDetailsPage(bill: bill),
                                          ),
                                        );
                                      }
                                    },
                                    onLongPress: () {
                                      if (!_selectionMode) {
                                        _enterSelectionMode(bill.id);
                                      }
                                    },
                                    onDelete: () async {
                                      await BillStore.instance.deleteBill(
                                        bill.id,
                                      );
                                    },
                                    onSelect: () {
                                      setState(() {
                                        if (selected) {
                                          _selectedIds.remove(bill.id);
                                        } else {
                                          _selectedIds.add(bill.id);
                                        }
                                      });
                                    },
                                  ),
                                );
                              }, childCount: filtered.length),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterChipData {
  final String? key;
  final String label;
  final IconData icon;
  final Color color;

  const _CategoryFilterChipData({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _SelectionToolbar extends StatelessWidget {
  final bool allSelected;
  final bool hasSelection;
  final bool filteredNotEmpty;
  final int filteredLength;
  final VoidCallback onSelectAll;
  final VoidCallback onDeleteSelected;
  final VoidCallback onDeleteAll;
  final VoidCallback onCancel;

  const _SelectionToolbar({
    required this.allSelected,
    required this.hasSelection,
    required this.filteredNotEmpty,
    required this.filteredLength,
    required this.onSelectAll,
    required this.onDeleteSelected,
    required this.onDeleteAll,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolbarBtn(
              icon: allSelected ? Icons.deselect : Icons.select_all,
              label:
                  allSelected
                      ? localizations.deselectAll
                      : localizations.selectAll,
              onPressed: filteredNotEmpty ? onSelectAll : null,
            ),
            if (hasSelection)
              _ToolbarBtn(
                icon: Icons.delete_outline,
                label: localizations.deleteSelected,
                onPressed: onDeleteSelected,
                isDestructive: true,
              ),
            _ToolbarBtn(
              icon: Icons.delete_forever,
              label: localizations.deleteAll,
              onPressed: filteredNotEmpty ? onDeleteAll : null,
              isDestructive: true,
            ),
            _ToolbarBtn(
              icon: Icons.close,
              label: localizations.cancel,
              onPressed: onCancel,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isDestructive;

  const _ToolbarBtn({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
        style: TextButton.styleFrom(
          foregroundColor: isDestructive ? AppColors.error : null,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final List<_CategoryFilterChipData> filters;
  final String? selectedKey;
  final ValueChanged<String?> onChanged;
  final bool isDark;

  const _FilterChips({
    required this.filters,
    required this.selectedKey,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final chipBg = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE6E8ED);
    final labelColorUnselected = isDark ? Colors.white70 : AppColors.textDark;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          filters.map((item) {
            final selected = item.key == selectedKey;
            return ChoiceChip(
              backgroundColor: chipBg,
              avatar: Icon(
                item.icon,
                size: 16,
                color: selected ? Colors.white : item.color,
              ),
              label: Text(item.label),
              selected: selected,
              selectedColor: item.key == null ? const Color(0xFF5DAAFB) : item.color,
              onSelected: (_) => onChanged(item.key),
              labelStyle: TextStyle(
                color: selected ? Colors.white : labelColorUnselected,
              ),
            );
          }).toList(),
    );
  }
}

class _BillCard extends StatefulWidget {
  final BillSummary bill;
  final String analysisLabel;
  final String consumptionLabel;
  final bool isDark;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onDelete;
  final VoidCallback onSelect;

  const _BillCard({
    required this.bill,
    required this.analysisLabel,
    required this.consumptionLabel,
    required this.isDark,
    required this.selectionMode,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
    required this.onDelete,
    required this.onSelect,
  });

  @override
  State<_BillCard> createState() => _BillCardState();
}

class _BillCardState extends State<_BillCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final isElectricity = BillTypeUtils.isElectricity(widget.bill.type);
    final backgroundColor =
        isElectricity ? const Color(0xFFFFB45E) : const Color(0xFF6FB7FF);
    final iconColor =
        isElectricity ? const Color(0xFFEF6C00) : AppColors.primary;
    final icon = isElectricity ? Icons.bolt : Icons.water_drop;
    final consumption =
        widget.bill.consumptionValue == null
            ? ''
            : '${widget.bill.consumptionValue!.toStringAsFixed(0)} ${widget.bill.consumptionUnit ?? ''}'
                .trim();

    final dataColor = widget.isDark ? AppColors.textDark : AppColors.textDark;

    final content = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border:
            widget.isSelected
                ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
                : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 380;
          final trailingActions = Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.analysisLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: dataColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: widget.onDelete,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete, size: 22, color: AppColors.error),
                ),
              ),
            ],
          );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          if (widget.selectionMode) ...[
            InkWell(
              onTap: widget.onSelect,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  widget.isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: dataColor,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.bill.type,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: dataColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.bill.dateText,
                      style: TextStyle(
                        color: dataColor.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                    if (widget.bill.totalAmount != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        OmrFormat.amount(widget.bill.totalAmount!, loc),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: dataColor,
                        ),
                      ),
                    ],
                    if (consumption.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${widget.consumptionLabel}: $consumption',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: dataColor,
                        ),
                      ),
                    ],
                    if (isNarrow) ...[
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerRight, child: trailingActions),
                    ],
                  ],
                ),
              ),
              if (!isNarrow) ...[
                const SizedBox(width: 8),
                trailingActions,
              ],
            ],
          );
        },
      ),
    );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPress: widget.selectionMode ? null : widget.onLongPress,
          onLongPressStart:
              widget.selectionMode ? null : (_) => _scaleController.forward(),
          onLongPressEnd:
              widget.selectionMode ? null : (_) => _scaleController.reverse(),
          onLongPressCancel: () => _scaleController.reverse(),
          behavior: HitTestBehavior.opaque,
          child: content,
        ),
      ),
    );
  }
}
