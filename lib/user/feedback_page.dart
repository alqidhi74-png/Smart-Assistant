import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../constants/app_layout.dart';
import '../constants/colors.dart';
import '../constants/language.dart';
import '../utils/app_snackbar.dart';
import '../utils/loading_overlay.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _controller = TextEditingController();
  double _rating = 5;
  bool _isSubmitting = false;
  DateTime? _lastSubmittedAt;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final mutedText =
        isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary;
    final cardColor =
        isDark ? const Color(0xFF1E1E1E) : AppColors.backgroundWhite;
    final borderColor =
        isDark ? const Color(0xFF2C2C2C) : AppColors.borderLight;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          localizations.feedback,
          style: TextStyle(color: textColor),
        ),
        backgroundColor: background,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: textColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppLayout.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.feedbackPrompt,
                style: TextStyle(color: mutedText),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.rateYourExperience,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _RatingRow(
                      rating: _rating,
                      onChanged: (value) => setState(() => _rating = value),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.feedbackDetails,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controller,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: localizations.feedbackHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnDark,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child:
                            _isSubmitting
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: AppLoadingIndicator(
                                    size: AppLoadingSize.inline,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(localizations.sendFeedback),
                      ),
                    ),
                    if (_lastSubmittedAt != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        '${localizations.feedbackSentAt}: ${DateFormat('yyyy-MM-dd HH:mm').format(_lastSubmittedAt!)}',
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _MyFeedbackReplies(
                currentUserId: FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
                textColor: textColor,
                mutedText: mutedText,
                cardColor: cardColor,
                borderColor: borderColor,
                localizations: localizations,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final message = _controller.text.trim();
    if (message.isEmpty) {
      _showMessage(localizations.feedbackRequired, isSuccess: false);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'anonymous';
      final name = await _loadUserName(uid, user?.email);
      final ref = FirebaseDatabase.instance.ref('feedback').push();
      await ref.set({
        'userId': uid,
        'userName': name,
        'rating': _rating,
        'message': message,
        'status': 'pending',
        'createdAt': ServerValue.timestamp,
      });
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _rating = 5;
        _lastSubmittedAt = DateTime.now();
      });
      _showMessage(localizations.feedbackSent, isSuccess: true);
    } catch (_) {
      if (!mounted) return;
      _showMessage(localizations.feedbackError, isSuccess: false);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<String> _loadUserName(String uid, String? fallbackEmail) async {
    try {
      final snapshot =
          await FirebaseDatabase.instance.ref('users/$uid/fullName').get();
      final name = snapshot.value?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    } catch (_) {}
    return fallbackEmail ?? 'User';
  }

  void _showMessage(String message, {required bool isSuccess}) {
    if (isSuccess) {
      AppSnackBar.showSuccess(context, message);
    } else {
      AppSnackBar.showError(context, message);
    }
  }
}

class _MyFeedbackReplies extends StatefulWidget {
  final String currentUserId;
  final Color textColor;
  final Color mutedText;
  final Color cardColor;
  final Color borderColor;
  final AppLocalizations localizations;

  const _MyFeedbackReplies({
    required this.currentUserId,
    required this.textColor,
    required this.mutedText,
    required this.cardColor,
    required this.borderColor,
    required this.localizations,
  });

  @override
  State<_MyFeedbackReplies> createState() => _MyFeedbackRepliesState();
}

class _MyFeedbackRepliesState extends State<_MyFeedbackReplies> {
  bool _selectionMode = false;
  final Set<String> _selectedKeys = <String>{};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('feedback').onValue,
      builder: (context, snapshot) {
        final items = _mapItems(snapshot.data?.snapshot.value);
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.localizations.feedback,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: widget.textColor,
              ),
            ),
            const SizedBox(height: 10),
            if (_selectionMode) ...[
              _SelectionActionsBarUser(
                onDeleteSelected: _deleteSelectedOnly,
                onSelectAll: () => _selectAll(items),
                onCancel: _clearSelection,
              ),
              const SizedBox(height: 8),
            ],
            ...items.map((item) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _onItemTap(item),
                  onLongPress: () => _onItemLongPress(item),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                DateFormat('yyyy-MM-dd hh:mm a').format(
                                  DateTime.fromMillisecondsSinceEpoch(item.createdAt),
                                ),
                                style: TextStyle(color: widget.mutedText, fontSize: 12),
                              ),
                            ),
                            _RatingRowReadOnly(rating: item.rating),
                            if (_selectionMode) ...[
                              const SizedBox(width: 8),
                              Icon(
                                _selectedKeys.contains(item.key)
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color:
                                    _selectedKeys.contains(item.key)
                                        ? const Color(0xFF2E9D57)
                                        : Colors.grey,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.message,
                          style: TextStyle(color: widget.textColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.adminReply.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.localizations.adminReplyLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E9D57),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  void _onItemLongPress(_UserFeedbackItem item) {
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

  void _onItemTap(_UserFeedbackItem item) {
    if (!_selectionMode) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => _UserFeedbackDetailsPage(
                item: item,
                localizations: widget.localizations,
              ),
        ),
      );
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

  void _selectAll(List<_UserFeedbackItem> items) {
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

  List<_UserFeedbackItem> _mapItems(Object? data) {
    final items = <_UserFeedbackItem>[];
    if (data is! Map) return items;
    data.forEach((rawKey, value) {
      if (value is Map) {
        final userId = value['userId']?.toString() ?? '';
        if (userId != widget.currentUserId) return;
        final message = value['message']?.toString() ?? '';
        final rating = double.tryParse(value['rating']?.toString() ?? '') ?? 0;
        final createdAt = int.tryParse(value['createdAt']?.toString() ?? '') ?? 0;
        final adminReply = value['adminReply']?.toString() ?? '';
        final adminReplyAt =
            int.tryParse(value['adminReplyAt']?.toString() ?? '') ?? 0;
        if (message.trim().isEmpty || createdAt <= 0) return;
        items.add(
          _UserFeedbackItem(
            key: rawKey.toString(),
            message: message,
            rating: rating,
            createdAt: createdAt,
            adminReply: adminReply,
            adminReplyAt: adminReplyAt,
          ),
        );
      }
    });
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }
}

class _UserFeedbackItem {
  final String key;
  final String message;
  final double rating;
  final int createdAt;
  final String adminReply;
  final int adminReplyAt;

  const _UserFeedbackItem({
    required this.key,
    required this.message,
    required this.rating,
    required this.createdAt,
    required this.adminReply,
    required this.adminReplyAt,
  });
}

class _SelectionActionsBarUser extends StatelessWidget {
  final VoidCallback onDeleteSelected;
  final VoidCallback onSelectAll;
  final VoidCallback onCancel;

  const _SelectionActionsBarUser({
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

class _RatingRowReadOnly extends StatelessWidget {
  final double rating;
  final double size;

  const _RatingRowReadOnly({required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (index) => Icon(
          _iconForIndex(index),
          color: const Color(0xFFF2C94C),
          size: size,
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

class _UserFeedbackDetailsPage extends StatelessWidget {
  final _UserFeedbackItem item;
  final AppLocalizations localizations;

  const _UserFeedbackDetailsPage({
    required this.item,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final pageBg = Theme.of(context).scaffoldBackgroundColor;
    final panelBg = isDark ? const Color(0xFF1B1B1B) : Colors.white;
    final panelBorder =
        isDark ? const Color(0xFF343434) : const Color(0xFFE5E7EB);
    final userBubble = isDark ? const Color(0xFF26435E) : const Color(0xFFDDEEFF);
    final adminBubble =
        isDark ? const Color(0xFF2C3C31) : const Color(0xFFEAF8EE);
    final adminBorder =
        isDark ? const Color(0xFF4A6E59) : const Color(0xFFBFE7CF);
    final muted = isDark ? const Color(0xFFBBBBBB) : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        title: Text(localizations.feedback),
      ),
      body: Padding(
        padding: AppLayout.pagePadding,
        child: Column(
          children: [
            Center(child: _RatingRowReadOnly(rating: item.rating, size: 24)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: panelBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: panelBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _FeedbackChatRow(
                      alignRight: false,
                      avatarText: 'U',
                      avatarColor: const Color(0xFF4A90E2),
                      child: _FeedbackBubble(
                        title: localizations.feedback,
                        message: item.message,
                        time: DateFormat(
                          'yyyy-MM-dd hh:mm a',
                        ).format(DateTime.fromMillisecondsSinceEpoch(item.createdAt)),
                        bgColor: userBubble,
                        borderColor: Colors.transparent,
                        textColor: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (item.adminReply.trim().isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: _FeedbackChatRow(
                        alignRight: true,
                        avatarText: 'A',
                        avatarColor: const Color(0xFF2E9D57),
                        child: _FeedbackBubble(
                          title: localizations.adminReplyLabel,
                          message: item.adminReply,
                          time:
                              item.adminReplyAt > 0
                                  ? DateFormat('yyyy-MM-dd hh:mm a').format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                      item.adminReplyAt,
                                    ),
                                  )
                                  : '--',
                          bgColor: adminBubble,
                          borderColor: adminBorder,
                          textColor: textColor,
                        ),
                      ),
                    )
                  else
                    Text(
                      localizations.feedbackNotReplied,
                      style: TextStyle(color: muted),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackBubble extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _FeedbackBubble({
    required this.title,
    required this.message,
    required this.time,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: textColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(message, style: TextStyle(color: textColor)),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                time,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.75),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedbackChatRow extends StatelessWidget {
  final bool alignRight;
  final String avatarText;
  final Color avatarColor;
  final Widget child;

  const _FeedbackChatRow({
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
      children:
          alignRight
              ? [Flexible(child: child), const SizedBox(width: 8), avatar]
              : [avatar, const SizedBox(width: 8), Flexible(child: child)],
    );
  }
}

class _RatingRow extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onChanged;

  const _RatingRow({required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (index) => GestureDetector(
          onTapDown: (details) {
            final isLeftHalf = details.localPosition.dx <= 18;
            final value = index + (isLeftHalf ? 0.5 : 1.0);
            onChanged(value);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Icon(
              _iconForIndex(index),
              color: const Color(0xFFF2C94C),
              size: 32,
            ),
          ),
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
