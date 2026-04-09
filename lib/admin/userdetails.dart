import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../constants/app_layout.dart';
import '../constants/colors.dart';
import '../constants/language.dart';
import '../utils/app_snackbar.dart';
import '../utils/loading_overlay.dart';
import '../utils/account_actions.dart';
import 'adminhome.dart';
import 'sidebar.dart';
import 'category.dart';
import 'profile.dart';
import 'feedback.dart';

class AdminUserDetailsPage extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const AdminUserDetailsPage({
    super.key,
    this.onLanguageChanged,
    this.currentLocale,
  });

  @override
  State<AdminUserDetailsPage> createState() => _AdminUserDetailsPageState();
}

class _AdminUserDetailsPageState extends State<AdminUserDetailsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child(
    'users',
  );
  List<_UserEntry> _lastUsers = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeLocale = widget.currentLocale ?? const Locale('en');
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE6E6E6);
    final borderColor =
        isDark ? const Color(0xFF2E2E2E) : const Color(0xFFBDBDBD);
    final primaryText = isDark ? Colors.white : AppColors.textDark;
    final secondaryText =
        isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary;
    final searchFill =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE6E6E6);

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
        onUserDetails: () => Navigator.pop(context),
        onFeedback:
            () => _openPage(
              AdminFeedbackPage(
                onLanguageChanged: widget.onLanguageChanged,
                currentLocale: activeLocale,
              ),
            ),
        onSettings:
            () => _openPage(
              AdminProfilePage(
                onLanguageChanged: widget.onLanguageChanged,
                currentLocale: activeLocale,
              ),
            ),
        onLogout: _logout,
      ),
      appBar: AppBar(
        title: Text(
          localizations.userDetailsPage,
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: AppLayout.pagePadding,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 420;
                  final searchField = Container(
                    height: 40,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppLayout.pagePaddingH + 2,
                    ),
                    decoration: BoxDecoration(
                      color: searchFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    alignment: Alignment.center,
                    child: TextField(
                      controller: _searchController,
                      onChanged:
                          (value) => setState(() {
                            _searchQuery = value.trim().toLowerCase();
                          }),
                      style: TextStyle(fontSize: 12, color: primaryText),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: searchFill,
                        icon: Icon(
                          Icons.search,
                          size: 16,
                          color: secondaryText,
                        ),
                        hintText: localizations.searchForUser,
                        hintStyle: TextStyle(color: secondaryText),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  );
                  if (isNarrow) {
                    return Column(
                      children: [
                        searchField,
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _buildDownloadAllButton(
                            localizations,
                            cardColor,
                            primaryText,
                          ),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: searchField),
                      const SizedBox(width: 8),
                      _buildDownloadAllButton(
                        localizations,
                        cardColor,
                        primaryText,
                      ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: _usersRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const IosStyleLoading();
                  }

                  final users = _parseUsers(snapshot.data?.snapshot.value);
                  final filtered = _filterUsers(users);
                  _lastUsers = users;

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppLayout.pagePaddingH + 6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${localizations.allUsers} (${filtered.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          localizations.viewManageUserAccounts,
                          style: TextStyle(fontSize: 11, color: secondaryText),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child:
                              filtered.isEmpty
                                  ? Center(
                                    child: Text(
                                      localizations.noUsersFound,
                                      style: TextStyle(color: secondaryText),
                                    ),
                                  )
                                  : ListView.builder(
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) {
                                      return _buildUserCard(
                                        filtered[index],
                                        localizations,
                                        cardColor,
                                        borderColor,
                                        primaryText,
                                        secondaryText,
                                        isDark,
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadAllButton(
    AppLocalizations localizations,
    Color cardColor,
    Color textColor,
  ) {
    return InkWell(
      onTap: _downloadAllUsers,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 36,
        padding: EdgeInsets.symmetric(horizontal: AppLayout.pagePaddingH),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.download, size: 16, color: textColor),
            const SizedBox(width: 6),
            Text(
              localizations.downloadAllData,
              style: TextStyle(fontSize: 11, color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  List<_UserEntry> _parseUsers(Object? value) {
    if (value == null) return [];
    final data = value as Map<dynamic, dynamic>;
    return data.entries.map((entry) {
      final raw = entry.value as Map<dynamic, dynamic>;
      final createdAt = _parseTimestamp(raw['createdAt']);
      final adminValue = (raw['admin'] ?? 'N').toString();
      return _UserEntry(
        uid: entry.key.toString(),
        fullName: (raw['fullName'] ?? '').toString(),
        email: (raw['email'] ?? '').toString(),
        phone: (raw['phone'] ?? '').toString(),
        isBlocked: (raw['blocked'] ?? false) == true,
        isAdmin: adminValue == 'Y',
        createdAt: createdAt,
      );
    }).toList();
  }

  List<_UserEntry> _filterUsers(List<_UserEntry> users) {
    if (_searchQuery.isEmpty) return users;
    final query = _normalizeSearch(_searchQuery);
    return users.where((user) {
      final fullName = _normalizeSearch(user.fullName);
      final email = _normalizeSearch(user.email);
      final phone = _normalizeSearch(user.phone);
      return fullName.contains(query) ||
          email.contains(query) ||
          phone.contains(query) ||
          user.uid.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildUserCard(
    _UserEntry user,
    AppLocalizations localizations,
    Color cardColor,
    Color borderColor,
    Color primaryText,
    Color secondaryText,
    bool isDark,
  ) {
    return InkWell(
      onTap: () => _showUserDetails(user),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(AppLayout.pagePaddingH + 2),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF4B8BFF),
                  child: Text(
                    _initials(user.fullName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
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
                              user.fullName.isEmpty
                                  ? 'Unknown User'
                                  : user.fullName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryText,
                              ),
                            ),
                          ),
                          _buildStatusPill(user),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildInfoRow(Icons.email, user.email, secondaryText),
                      _buildInfoRow(Icons.phone, user.phone, secondaryText),
                      _buildInfoRow(
                        Icons.calendar_today,
                        _formatJoinedDate(user.createdAt),
                        secondaryText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 420;
                if (isNarrow) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: constraints.maxWidth,
                        child: _buildUserActionButton(
                          label: localizations.download,
                          icon: Icons.download,
                          color:
                              isDark
                                  ? const Color(0xFF2C2C2C)
                                  : const Color(0xFFDCDCDC),
                          textColor: primaryText,
                          onTap: () => _downloadUser(user),
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth,
                        child: _buildUserActionButton(
                          label:
                              user.isBlocked
                                  ? localizations.unblock
                                  : localizations.block,
                          icon: user.isBlocked ? Icons.check_circle : Icons.block,
                          color:
                              user.isBlocked
                                  ? const Color(0xFF7BE27B)
                                  : const Color(0xFFFF7B7B),
                          textColor: primaryText,
                          onTap: () => _toggleBlockUser(user, localizations),
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth,
                        child: _buildUserActionButton(
                          label:
                              user.isAdmin
                                  ? localizations.revokeAdmin
                                  : localizations.makeAdmin,
                          icon:
                              user.isAdmin
                                  ? Icons.remove_moderator
                                  : Icons.admin_panel_settings,
                          color:
                              user.isAdmin
                                  ? (isDark
                                      ? const Color(0xFF2C2C2C)
                                      : const Color(0xFFDCDCDC))
                                  : const Color(0xFFB9D7FF),
                          textColor: primaryText,
                          onTap: () => _toggleAdminUser(user, localizations),
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: _buildUserActionButton(
                        label: localizations.download,
                        icon: Icons.download,
                        color:
                            isDark
                                ? const Color(0xFF2C2C2C)
                                : const Color(0xFFDCDCDC),
                        textColor: primaryText,
                        onTap: () => _downloadUser(user),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildUserActionButton(
                        label:
                            user.isBlocked
                                ? localizations.unblock
                                : localizations.block,
                        icon: user.isBlocked ? Icons.check_circle : Icons.block,
                        color:
                            user.isBlocked
                                ? const Color(0xFF7BE27B)
                                : const Color(0xFFFF7B7B),
                        textColor: primaryText,
                        onTap: () => _toggleBlockUser(user, localizations),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildUserActionButton(
                        label:
                            user.isAdmin
                                ? localizations.revokeAdmin
                                : localizations.makeAdmin,
                        icon:
                            user.isAdmin
                                ? Icons.remove_moderator
                                : Icons.admin_panel_settings,
                        color:
                            user.isAdmin
                                ? (isDark
                                    ? const Color(0xFF2C2C2C)
                                    : const Color(0xFFDCDCDC))
                                : const Color(0xFFB9D7FF),
                        textColor: primaryText,
                        onTap: () => _toggleAdminUser(user, localizations),
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
  }

  Widget _buildStatusPill(_UserEntry user) {
    final isBlocked = user.isBlocked;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.pagePaddingH - 2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isBlocked ? const Color(0xFFFF8A80) : const Color(0xFF7CE57C),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isBlocked
            ? (AppLocalizations.of(context) ??
                    AppLocalizations(const Locale('en')))
                .blocked
            : (AppLocalizations.of(context) ??
                    AppLocalizations(const Locale('en')))
                .active,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(fontSize: 11, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minHeight: 34),
        padding: AppLayout.pagePadding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: textColor),
                const SizedBox(width: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: textColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadAllUsers() async {
    final file = await _exportUsersToPdf(_lastUsers, 'all_users');
    if (!mounted) return;
    AppSnackBar.showSuccess(context, 'Saved to ${file.path}');
  }

  Future<void> _downloadUser(_UserEntry user) async {
    final file = await _exportUsersToPdf([user], _safeFileName(user.fullName));
    if (!mounted) return;
    AppSnackBar.showSuccess(context, 'Saved to ${file.path}');
  }

  void _toggleBlockUser(_UserEntry user, AppLocalizations localizations) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder:
          (context) => Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECECEC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.isBlocked
                          ? localizations.unblockUser
                          : localizations.blockUser,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user.isBlocked
                          ? '${localizations.unblockUser} ${user.fullName}?'
                          : '${localizations.blockUser} ${user.fullName}?',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.isBlocked
                          ? localizations.unblockUser
                          : localizations.blockUser,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildUserActionButton(
                          label: localizations.cancel,
                          icon: Icons.close,
                          color: const Color(0xFFE0E0E0),
                          textColor: AppColors.textDark,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        _buildUserActionButton(
                          label:
                              user.isBlocked
                                  ? localizations.unblockUser
                                  : localizations.blockUser,
                          icon:
                              user.isBlocked ? Icons.check_circle : Icons.block,
                          color:
                              user.isBlocked
                                  ? const Color(0xFF7BE27B)
                                  : const Color(0xFFFF7B7B),
                          textColor: AppColors.textDark,
                          onTap: () async {
                            Navigator.pop(context);
                            await _usersRef.child(user.uid).update({
                              'blocked': !user.isBlocked,
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  void _toggleAdminUser(_UserEntry user, AppLocalizations localizations) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder:
          (context) => Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECECEC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.isAdmin
                          ? localizations.revokeAdmin
                          : localizations.makeAdmin,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user.isAdmin
                          ? '${localizations.revokeAdmin} ${user.fullName}?'
                          : '${localizations.makeAdmin} ${user.fullName}?',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.isAdmin
                          ? localizations.revokeAdmin
                          : localizations.makeAdmin,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildUserActionButton(
                          label: localizations.cancel,
                          icon: Icons.close,
                          color: const Color(0xFFE0E0E0),
                          textColor: AppColors.textDark,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        _buildUserActionButton(
                          label:
                              user.isAdmin
                                  ? localizations.revokeAdmin
                                  : localizations.makeAdmin,
                          icon:
                              user.isAdmin
                                  ? Icons.remove_moderator
                                  : Icons.admin_panel_settings,
                          color:
                              user.isAdmin
                                  ? const Color(0xFFDCDCDC)
                                  : const Color(0xFFB9D7FF),
                          textColor: AppColors.textDark,
                          onTap: () async {
                            Navigator.pop(context);
                            await _usersRef.child(user.uid).update({
                              'admin': user.isAdmin ? 'N' : 'Y',
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Future<File> _exportUsersToPdf(
    List<_UserEntry> users,
    String baseName,
  ) async {
    final doc = pw.Document();
    final rows = [
      ['Full Name', 'Email', 'Phone', 'Status', 'Joined'],
      ...users.map(
        (user) => [
          user.fullName.isEmpty ? 'Unknown User' : user.fullName,
          user.email,
          user.phone,
          user.isBlocked ? 'blocked' : 'active',
          _formatJoinedDate(user.createdAt),
        ],
      ),
    ];
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'User Details Export',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                data: rows,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF1E88E5),
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellPadding: const pw.EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 6,
                ),
              ),
            ],
          );
        },
      ),
    );
    final directory = await _getDownloadDirectory();
    final fileName =
        '${_safeFileName(baseName)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  String _normalizeSearch(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        return downloads;
      }
    }
    if (Platform.isAndroid) {
      final downloads = Directory('/storage/emulated/0/Download');
      if (await downloads.exists()) {
        return downloads;
      }
      final external = await getExternalStorageDirectory();
      if (external != null) {
        return external;
      }
    }
    final documents = await getApplicationDocumentsDirectory();
    return documents;
  }

  void _showUserDetails(_UserEntry user) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder:
          (context) => Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECECEC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isEmpty ? 'User Details' : user.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(localizations.email, user.email),
                    _buildDetailRow(localizations.phoneNumber, user.phone),
                    _buildDetailRow(
                      localizations.status,
                      user.isBlocked
                          ? localizations.blocked
                          : localizations.active,
                    ),
                    _buildDetailRow(
                      localizations.admin,
                      user.isAdmin
                          ? localizations.adminYes
                          : localizations.adminNo,
                    ),
                    _buildDetailRow('UID', user.uid),
                    _buildDetailRow(
                      localizations.joined,
                      _formatJoinedDate(user.createdAt),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _buildUserActionButton(
                        label: localizations.close,
                        icon: Icons.close,
                        color: const Color(0xFFDCDCDC),
                        textColor: AppColors.textDark,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 11, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  String _safeFileName(String input) {
    final trimmed = input.trim().toLowerCase();
    if (trimmed.isEmpty) return 'user';
    return trimmed.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  int? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _formatJoinedDate(int? timestampMs) {
    if (timestampMs == null) return '-';
    final date = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
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

class _UserEntry {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final bool isBlocked;
  final bool isAdmin;
  final int? createdAt;

  const _UserEntry({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.isBlocked,
    required this.isAdmin,
    required this.createdAt,
  });
}

