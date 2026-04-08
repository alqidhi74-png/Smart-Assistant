import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../constants/app_layout.dart';
import '../constants/colors.dart';
import '../constants/language.dart';
import '../core/utils.dart';
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
            Icons.menu,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.textDark,
          ),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
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
    return Padding(
      padding: AppLayout.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppLayout.pagePaddingH + 2,
              vertical: AppLayout.pagePaddingV + 2,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE6E6E6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  localizations.filterByStatus,
                  style: TextStyle(color: mutedText),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _filter,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text(localizations.allFeedback),
                    ),
                  ],
                  onChanged:
                      (value) => setState(() => _filter = value ?? 'all'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('feedback').onValue,
              builder: (context, snapshot) {
                final data = snapshot.data?.snapshot.value;
                final feedbackItems = _mapFeedback(data);
                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppLayout.pagePaddingH + 2,
                        vertical: AppLayout.pagePaddingV + 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
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
                                  return _FeedbackCard(item: item);
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
          final rating = int.tryParse(value['rating']?.toString() ?? '') ?? 0;
          final createdAt = int.tryParse(value['createdAt']?.toString() ?? '');
          items.add(
            _FeedbackItem(
              name: name,
              message: message,
              rating: rating,
              createdAt: createdAt ?? 0,
            ),
          );
        }
      });
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
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
    await AccountActions.showLogoutChoiceAndExecute(context);
  }
}

class _FeedbackItem {
  final String name;
  final String message;
  final int rating;
  final int createdAt;

  const _FeedbackItem({
    required this.name,
    required this.message,
    required this.rating,
    required this.createdAt,
  });
}

class _FeedbackCard extends StatelessWidget {
  final _FeedbackItem item;

  const _FeedbackCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final initials =
        item.name.isNotEmpty
            ? item.name.trim().split(' ').map((e) => e[0]).take(2).join()
            : 'U';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.pagePaddingH + 2,
        vertical: AppLayout.pagePaddingV + 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E4EA)),
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
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _StarsRow(rating: item.rating),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.message,
                  style: const TextStyle(color: AppColors.textSecondary),
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarsRow extends StatelessWidget {
  final int rating;

  const _StarsRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (index) => Icon(
          index < rating ? Icons.star : Icons.star_border,
          size: 16,
          color: const Color(0xFFF2C94C),
        ),
      ),
    );
  }
}
