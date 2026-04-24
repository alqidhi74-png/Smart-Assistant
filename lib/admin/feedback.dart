import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../constants/app_layout.dart';
import '../constants/colors.dart';
import '../constants/language.dart';
import '../utils/account_actions.dart';
import '../utils/app_snackbar.dart';
import 'adminhome.dart';
import 'sidebar.dart';
import 'category.dart';
import 'userdetails.dart';
import 'profile.dart';

class AdminFeedbackPage extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const AdminFeedbackPage({
    super.key,
    this.onLanguageChanged,
    this.currentLocale,
  });

  @override
  State<AdminFeedbackPage> createState() => _AdminFeedbackPageState();
}

class _AdminFeedbackPageState extends State<AdminFeedbackPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _filter = 'all';
  bool _isReplying = false;
  bool _selectionMode = false;
  final Set<String> _selectedKeys = <String>{};

  @override
  Widget build(BuildContext context) {
    final activeLocale = widget.currentLocale ?? const Locale('en');
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));

    return Scaffold(
      key: _scaffoldKey,
      drawer: AdminSidebar(
        adminName: 'Admin',
        onHome: _goHome,
        onCategory:
            () => _openPage(
              AdminCategoryPage(
                onLanguageChanged: widget.onLanguageChanged,
                currentLocale: activeLocale,
              ),
            ),
        onUserDetails:
            () => _openPage(
              AdminUserDetailsPage(
                onLanguageChanged: widget.onLanguageChanged,
                currentLocale: activeLocale,
              ),
            ),
        onFeedback: () => Navigator.pop(context),
        onSettings:
            () => _openPage(
              AdminProfilePage(
                onLanguageChanged: widget.onLanguageChanged,
                currentLocale: activeLocale,
              ),
            ),
        onLogout: _logout,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.feedbackPageTitle,
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
            (Navigator.of(context).canPop() ? Icons.arrow_back : Icons.menu),
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.textDark,
          ),
          onPressed: Navigator.of(context).canPop() ? () => Navigator.of(context).maybePop() : () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: SafeArea(child: _buildFeedbackList(localizations)),
    );
  }

  Widget _buildFeedbackList(AppLocalizations localizations) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final mutedText =
        isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary;
    final headerBg = isDark ? const Color(0xFF2A2A2A) : AppColors.borderLight;
    return Padding(
      padding: AppLayout.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('feedback').onValue,
              builder: (context, snapshot) {
                final data = snapshot.data?.snapshot.value;
                final allItems = _mapFeedback(data);
                final feedbackItems = _filterItems(allItems);
                return Column(
                  children: [
                    if (_selectionMode) ...[
                      _SelectionActionsBar(
                        onDeleteSelected: _deleteSelectedOnly,
                        onSelectAll: () => _selectAll(feedbackItems),
                        onCancel: _clearSelection,
                      ),
                      const SizedBox(height: 10),
                    ],
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppLayout.pagePaddingH + 2,
                        vertical: AppLayout.pagePaddingV + 2,
                      ),
                      decoration: BoxDecoration(
                        color: headerBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.feedbackHeaderWithCount(
                              feedbackItems.length,
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            localizations.userFeedbackSubtitle,
                            style: TextStyle(color: mutedText, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FilterChips(
                      filters: [
                        _FeedbackFilterChipData(
                          key: 'all',
                          label: localizations.allFeedback,
                          color: const Color(0xFF5DAAFB),
                        ),
                        _FeedbackFilterChipData(
                          key: 'replied',
                          label: localizations.feedbackReplied,
                          color: const Color(0xFF2E9D57),
                        ),
                        _FeedbackFilterChipData(
                          key: 'pending',
                          label: localizations.feedbackNotReplied,
                          color: const Color(0xFFD64545),
                        ),
                        _FeedbackFilterChipData(
                          key: 'skipped',
                          label: localizations.feedbackSkipped,
                          color: const Color(0xFF7D7D7D),
                        ),
                      ],
                      selectedKey: _filter,
                      onChanged: (value) => setState(() => _filter = value),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child:
                          feedbackItems.isEmpty
                              ? Center(
                                child: Text(
                                  localizations.noDataFound,
                                  style: TextStyle(color: mutedText),
                                ),
                              )
                              : ListView.separated(
                                itemCount: feedbackItems.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final item = feedbackItems[index];
                                  return _FeedbackCard(
                                    item: item,
                                    selected: _selectedKeys.contains(item.key),
                                    selectionMode: _selectionMode,
                                    onTap: () => _onItemTap(item),
                                    onLongPress: () => _onItemLongPress(item),
                                  );
                                },
                              ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<_FeedbackItem> _mapFeedback(Object? data) {
    final items = <_FeedbackItem>[];
    if (data is Map) {
      data.forEach((key, value) {
        if (value is Map) {
          final name = value['userName']?.toString() ?? 'User';
          final message = value['message']?.toString() ?? '';
          final rating =
              double.tryParse(value['rating']?.toString() ?? '') ?? 0;
          final createdAt = int.tryParse(value['createdAt']?.toString() ?? '');
          final adminReply = value['adminReply']?.toString() ?? '';
          final adminReplyAt =
              int.tryParse(value['adminReplyAt']?.toString() ?? '') ?? 0;
          String status = value['status']?.toString() ?? 'pending';
          if (adminReply.trim().isNotEmpty) {
            status = 'replied';
          } else if (status != 'skipped') {
            status = 'pending';
          }
          items.add(
            _FeedbackItem(
              key: key.toString(),
              name: name,
              message: message,
              rating: rating,
              adminReply: adminReply,
              adminReplyAt: adminReplyAt,
              status: status,
              createdAt: createdAt ?? 0,
            ),
          );
        }
      });
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<_FeedbackItem> _filterItems(List<_FeedbackItem> items) {
    if (_filter == 'all') return items;
    return items.where((item) => item.status == _filter).toList();
  }

  void _onItemLongPress(_FeedbackItem item) {
    setState(() {
      _selectionMode = true;
      if (_selectedKeys.contains(item.key)) {
        _selectedKeys.remove(item.key);
      } else {
        _selectedKeys.add(item.key);
      }
      if (_selectedKeys.isEmpty) _selectionMode = false;
    });
  }

  void _onItemTap(_FeedbackItem item) {
    if (!_selectionMode) {
      _showFeedbackDetails(item);
      return;
    }
    setState(() {
      if (_selectedKeys.contains(item.key)) {
        _selectedKeys.remove(item.key);
      } else {
        _selectedKeys.add(item.key);
      }
      if (_selectedKeys.isEmpty) _selectionMode = false;
    });
  }

  void _selectAll(List<_FeedbackItem> items) {
    setState(() {
      _selectionMode = true;
      _selectedKeys
        ..clear()
        ..addAll(items.map((e) => e.key));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedKeys.clear();
    });
  }

  Future<void> _deleteSelectedOnly() async {
    final keys = _selectedKeys.toList();
    if (keys.isEmpty) return;
    for (final key in keys) {
      await FirebaseDatabase.instance.ref('feedback/$key').remove();
    }
    if (!mounted) return;
    _clearSelection();
  }

  Future<void> _submitReply(_FeedbackItem item, String reply) async {
    if (_isReplying || item.adminReply.trim().isNotEmpty) return;
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    if (reply.trim().isEmpty) {
      AppSnackBar.showError(context, localizations.replyRequired);
      return;
    }
    setState(() => _isReplying = true);
    try {
      await FirebaseDatabase.instance.ref('feedback/${item.key}').update({
        'adminReply': reply.trim(),
        'adminReplyAt': ServerValue.timestamp,
        'status': 'replied',
      });
    } finally {
      if (mounted) setState(() => _isReplying = false);
    }
  }

  Future<void> _markSkipped(_FeedbackItem item) async {
    if (item.adminReply.trim().isNotEmpty) return;
    await FirebaseDatabase.instance.ref('feedback/${item.key}').update({
      'status': 'skipped',
      'skippedAt': ServerValue.timestamp,
    });
  }

  Future<void> _markUnskipped(_FeedbackItem item) async {
    if (item.adminReply.trim().isNotEmpty) return;
    await FirebaseDatabase.instance.ref('feedback/${item.key}').update({
      'status': 'pending',
      'skippedAt': null,
    });
  }

  Future<void> _showFeedbackDetails(_FeedbackItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => _FeedbackDetailsPage(
              item: item,
              onReply: (value) => _submitReply(item, value),
              onSkip: () => _markSkipped(item),
              onUnskip: () => _markUnskipped(item),
            ),
      ),
    );
  }

  void _goHome() {
    final currentLocale = widget.currentLocale ?? const Locale('en');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder:
            (context) => AdminHome(
              onLanguageChanged: widget.onLanguageChanged,
              currentLocale: currentLocale,
            ),
      ),
      (route) => false,
    );
  }

  void _openPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  Future<void> _logout() async {
    await AccountActions.showLogoutConfirmAndExecute(context);
  }
}

class _FeedbackItem {
  final String key;
  final String name;
  final String message;
  final double rating;
  final String adminReply;
  final int adminReplyAt;
  final String status;
  final int createdAt;

  const _FeedbackItem({
    required this.key,
    required this.name,
    required this.message,
    required this.rating,
    required this.adminReply,
    required this.adminReplyAt,
    required this.status,
    required this.createdAt,
  });
}

class _FeedbackCard extends StatelessWidget {
  final _FeedbackItem item;
  final bool selected;
  final bool selectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _FeedbackCard({
    required this.item,
    required this.selected,
    required this.selectionMode,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final cardColor = _cardColor(isDark);
    final borderColor = _borderColor(isDark);
    final nameColor = isDark ? Colors.white : AppColors.textDark;
    final msgColor = isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary;
    final initials =
        item.name.isNotEmpty
            ? item.name.trim().split(' ').map((e) => e[0]).take(2).join()
            : 'U';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppLayout.pagePaddingH + 2,
            vertical: AppLayout.pagePaddingV + 2,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF4A90E2),
            child: Text(
              initials.toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: nameColor,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _StarsRow(rating: item.rating),
                        const SizedBox(height: 6),
                        Text(
                          _statusLabel(localizations),
                          style: TextStyle(
                            color: _statusColor(isDark),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.message,
                  style: TextStyle(color: msgColor),
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${localizations.feedbackSentAt}: ${_formatTimestamp(item.createdAt, localizations.locale)}',
                  style: TextStyle(color: msgColor, fontSize: 12),
                ),
              ],
            ),
          ),
          if (selectionMode) ...[
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? const Color(0xFF2E9D57) : Colors.grey,
            ),
          ],
            ],
          ),
        ),
      ),
    );
  }

  Color _borderColor(bool isDark) {
    switch (item.status) {
      case 'replied':
        return isDark ? const Color(0xFF3FAF6A) : const Color(0xFF2E9D57);
      case 'skipped':
        return isDark ? const Color(0xFF7D7D7D) : const Color(0xFF9B9B9B);
      default:
        return isDark ? const Color(0xFFC05656) : const Color(0xFFD64545);
    }
  }

  Color _cardColor(bool isDark) {
    switch (item.status) {
      case 'replied':
        return isDark ? const Color(0xFF16231B) : const Color(0xFFEAF8EE);
      case 'skipped':
        return isDark ? const Color(0xFF232323) : const Color(0xFFF2F2F2);
      default:
        return isDark ? const Color(0xFF2A1919) : const Color(0xFFFDECEC);
    }
  }

  Color _statusColor(bool isDark) {
    switch (item.status) {
      case 'replied':
        return isDark ? const Color(0xFF6EE49C) : const Color(0xFF2E9D57);
      case 'skipped':
        return isDark ? const Color(0xFFC0C0C0) : const Color(0xFF7D7D7D);
      default:
        return isDark ? const Color(0xFFFF8B8B) : const Color(0xFFD64545);
    }
  }

  String _statusLabel(AppLocalizations localizations) {
    switch (item.status) {
      case 'replied':
        return localizations.feedbackReplied;
      case 'skipped':
        return localizations.feedbackSkipped;
      default:
        return localizations.feedbackNotReplied;
    }
  }

}

class _StarsRow extends StatelessWidget {
  final double rating;
  final double size;

  const _StarsRow({required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (index) => Icon(
          _iconForIndex(index),
          size: size,
          color: const Color(0xFFF2C94C),
        ),
      ),
    );
  }

  IconData _iconForIndex(int index) {
    final starNumber = index + 1.0;
    if (rating >= starNumber) return Icons.star;
    if (rating >= starNumber - 0.5) return Icons.star_half;
    return Icons.star_border;
  }
}

String _formatTimestamp(int timestampMs, Locale locale) {
  if (timestampMs <= 0) return '--';
  final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
  return DateFormat('EEEE, yyyy-MM-dd hh:mm a', locale.toString()).format(dt);
}

class _FeedbackFilterChipData {
  final String key;
  final String label;
  final Color color;

  const _FeedbackFilterChipData({
    required this.key,
    required this.label,
    required this.color,
  });
}

class _FilterChips extends StatelessWidget {
  final List<_FeedbackFilterChipData> filters;
  final String selectedKey;
  final ValueChanged<String> onChanged;
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
    return Center(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children:
            filters.map((item) {
              final selected = item.key == selectedKey;
              return ChoiceChip(
                backgroundColor: chipBg,
                label: Text(item.label),
                selected: selected,
                selectedColor: item.color,
                onSelected: (_) => onChanged(item.key),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : labelColorUnselected,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                showCheckmark: false,
              );
            }).toList(),
      ),
    );
  }
}

class _SelectionActionsBar extends StatelessWidget {
  final VoidCallback onDeleteSelected;
  final VoidCallback onSelectAll;
  final VoidCallback onCancel;

  const _SelectionActionsBar({
    required this.onDeleteSelected,
    required this.onSelectAll,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _actionButton(
          icon: Icons.delete_outline,
          label: localizations.deleteSelected,
          onPressed: onDeleteSelected,
          isDestructive: true,
        ),
        _actionButton(
          icon: Icons.check_circle_outline,
          label: localizations.selectAll,
          onPressed: onSelectAll,
        ),
        _actionButton(
          icon: Icons.close_rounded,
          label: localizations.cancel,
          onPressed: onCancel,
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: isDestructive ? AppColors.error : null,
      ),
    );
  }
}

class _FeedbackDetailsPage extends StatefulWidget {
  final _FeedbackItem item;
  final Future<void> Function(String) onReply;
  final Future<void> Function() onSkip;
  final Future<void> Function() onUnskip;

  const _FeedbackDetailsPage({
    required this.item,
    required this.onReply,
    required this.onSkip,
    required this.onUnskip,
  });

  @override
  State<_FeedbackDetailsPage> createState() => _FeedbackDetailsPageState();
}

class _FeedbackDetailsPageState extends State<_FeedbackDetailsPage> {
  final TextEditingController _replyController = TextEditingController();
  bool _isSubmitting = false;
  late String _currentStatus;
  late String _currentReply;
  late int _currentReplyAt;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.item.status;
    _currentReply = widget.item.adminReply.trim();
    _currentReplyAt = widget.item.adminReplyAt;
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final cardColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final status = _currentStatus;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        title: Text(
          localizations.feedbackPageTitle,
          style: TextStyle(color: textColor),
        ),
      ),
      body: Padding(
        padding: AppLayout.pagePadding,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          child: Column(
            children: [
              Center(child: _StarsRow(rating: widget.item.rating, size: 24)),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        isDark
                            ? const Color(0xFF353535)
                            : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: _ChatMessageRow(
                        alignRight: true,
                        avatarText: _avatarText(widget.item.name),
                        avatarColor: const Color(0xFF4A90E2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _MessageBubble(
                              text: widget.item.message,
                              sender: widget.item.name,
                              timeLabel: _formatTimestamp(
                                widget.item.createdAt,
                                localizations.locale,
                              ),
                              color:
                                  isDark
                                      ? const Color(0xFF23466A)
                                      : const Color(0xFFDDEEFF),
                              textColor: textColor,
                              alignRight: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_currentReply.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _ChatMessageRow(
                          alignRight: false,
                          avatarText: 'A',
                          avatarColor: const Color(0xFF2E9D57),
                          child: _MessageBubble(
                            text: _currentReply,
                            sender: localizations.adminReplyLabel,
                            timeLabel:
                                _currentReplyAt > 0
                                    ? _formatTimestamp(
                                      _currentReplyAt,
                                      localizations.locale,
                                    )
                                    : '--',
                            color:
                                isDark
                                    ? const Color(0xFF2A2A2A)
                                    : const Color(0xFFF3F4F6),
                            textColor: textColor,
                            alignRight: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (status == 'pending' && _currentReply.isEmpty) ...[
                      TextField(
                        controller: _replyController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: localizations.feedbackReplyHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _actionButtons(localizations, status),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButtons(AppLocalizations localizations, String status) {
    if (status == 'replied') {
      return Text(
        localizations.feedbackReplied,
        style: TextStyle(color: Theme.of(context).hintColor),
      );
    }

    final commonStyle = ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(46),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    );

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: commonStyle.copyWith(
              backgroundColor: WidgetStateProperty.all(const Color(0xFF7D7D7D)),
              foregroundColor: WidgetStateProperty.all(Colors.white),
            ),
            onPressed: _isSubmitting
                ? null
                : () async {
                    setState(() => _isSubmitting = true);
                    try {
                      if (status == 'skipped') {
                        await widget.onUnskip();
                        if (mounted) {
                          setState(() => _currentStatus = 'pending');
                        }
                      } else {
                        await widget.onSkip();
                        if (mounted) {
                          setState(() => _currentStatus = 'skipped');
                        }
                      }
                    } finally {
                      if (mounted) setState(() => _isSubmitting = false);
                    }
                  },
            child: Text(status == 'skipped' ? localizations.unskip : localizations.feedbackSkipped),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            style: commonStyle,
            onPressed: _isSubmitting || status != 'pending'
                ? null
                : () async {
                    final reply = _replyController.text.trim();
                    if (reply.isEmpty) {
                      AppSnackBar.showError(context, localizations.replyRequired);
                      return;
                    }
                    FocusScope.of(context).unfocus();
                    setState(() => _isSubmitting = true);
                    try {
                      await widget.onReply(reply);
                      if (mounted) {
                        setState(() {
                          _currentReply = reply;
                          _currentStatus = 'replied';
                          _currentReplyAt = DateTime.now().millisecondsSinceEpoch;
                          _replyController.clear();
                        });
                      }
                    } finally {
                      if (mounted) setState(() => _isSubmitting = false);
                    }
                  },
            child: Text(localizations.sendReply),
          ),
        ),
      ],
    );
  }
}

String _avatarText(String name) {
  final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return 'U';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

class _ChatMessageRow extends StatelessWidget {
  final bool alignRight;
  final String avatarText;
  final Color avatarColor;
  final Widget child;

  const _ChatMessageRow({
    required this.alignRight,
    required this.avatarText,
    required this.avatarColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: avatarColor,
      child: Text(
        avatarText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return Row(
      mainAxisAlignment:
          alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: alignRight
          ? [Flexible(child: child), const SizedBox(width: 8), avatar]
          : [avatar, const SizedBox(width: 8), Flexible(child: child)],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final String sender;
  final String timeLabel;
  final Color color;
  final Color textColor;
  final bool alignRight;

  const _MessageBubble({
    required this.text,
    required this.sender,
    required this.timeLabel,
    required this.color,
    required this.textColor,
    required this.alignRight,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300, minWidth: 180),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: color,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(alignRight ? 14 : 4),
            bottomRight: Radius.circular(alignRight ? 4 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              sender,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: textColor,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Text(text, style: TextStyle(color: textColor)),
            const SizedBox(height: 8),
            Text(
              timeLabel,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

