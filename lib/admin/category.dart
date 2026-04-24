import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../constants/app_layout.dart';
import '../constants/colors.dart';
import '../constants/language.dart';
import '../services/admin_bill_cleanup_service.dart';
import '../services/categories_rtdb_hub.dart';
import '../utils/bill_type_utils.dart';
import '../utils/category_rtdb_style.dart';
import '../utils/admin_pdf_io.dart';
import '../utils/app_error_reporter.dart';
import '../utils/app_snackbar.dart';
import '../utils/account_actions.dart';
import '../utils/loading_overlay.dart';
import 'adminhome.dart';
import 'sidebar.dart';
import 'userdetails.dart';
import 'profile.dart';
import 'feedback.dart';

class AdminCategoryPage extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const AdminCategoryPage({
    super.key,
    this.onLanguageChanged,
    this.currentLocale,
  });

  @override
  State<AdminCategoryPage> createState() => _AdminCategoryPageState();
}

class _AdminCategoryPageState extends State<AdminCategoryPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DatabaseReference _categoriesRef = FirebaseDatabase.instance
      .ref()
      .child('categories');
  final DatabaseReference _billsRef = FirebaseDatabase.instance.ref().child(
    'my_bills',
  );
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child(
    'users',
  );

  @override
  void initState() {
    super.initState();
    _seedCategoriesIfEmpty();
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = widget.currentLocale ?? const Locale('en');
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    return Scaffold(
      key: _scaffoldKey,
      drawer: AdminSidebar(
        adminName: 'Admin',
        onHome: _goHome,
        onCategory: () => Navigator.pop(context),
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
      appBar: AppBar(
        title: Text(
          localizations.categoryPage,
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
            Navigator.of(context).canPop() ? Icons.arrow_back : Icons.menu,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.textDark,
          ),
          onPressed:
              Navigator.of(context).canPop()
                  ? () => Navigator.of(context).maybePop()
                  : () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppLayout.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddDialog(),
                  icon: const Icon(
                    Icons.add,
                    size: 16,
                    color: AppColors.textDark,
                  ),
                  label: Text(
                    localizations.addNewCategory,
                    style: const TextStyle(color: AppColors.textDark),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE6E6E6),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<DatabaseEvent>(
                stream: CategoriesRtdbHub.instance.stream,
                initialData: CategoriesRtdbHub.instance.latestEvent,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          localizations.categoriesLoadError,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    );
                  }
                  return StreamBuilder<DatabaseEvent>(
                    stream: _billsRef.onValue,
                    builder: (context, billsSnapshot) {
                      final billCounts = _countBillsByType(
                        billsSnapshot.data?.snapshot.value,
                      );
                      final items = _parseCategories(
                        snapshot.data?.snapshot.value,
                        billCounts,
                      );
                      if (items.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              localizations.noCategories,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: items.map(_buildCategoryCard).toList(),
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

  Widget _buildCategoryCard(_CategoryItem item) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final textOnCard =
        ThemeData.estimateBrightnessForColor(item.color) == Brightness.dark
            ? Colors.white
            : AppColors.textDark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.pagePaddingH + 2,
        vertical: AppLayout.pagePaddingV + 2,
      ),
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: item.iconColor, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textOnCard,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: textOnCard,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: item.badgeColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${item.billsCount} ${localizations.bills}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.backgroundWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildActionIcon(
                icon: Icons.download,
                color: const Color(0xFF5DA7FF),
                onTap: () => _downloadCategory(item),
              ),
              _buildActionIcon(
                icon: Icons.edit,
                color: const Color(0xFF6B7BFF),
                onTap: () => _showUpdateDialog(item),
              ),
              _buildActionIcon(
                icon: Icons.delete,
                color: const Color(0xFFE44B4B),
                onTap: () => _confirmDelete(item),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }

  Future<void> _downloadCategory(_CategoryItem item) async {
    final loc =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    LoadingOverlay.show(context);
    try {
      final snap = await _billsRef.get();
      final usersSnap = await _usersRef.get();
      final usersByUid = _extractUsersProfileMap(usersSnap.value);
      final rows = _collectBillRowsForCategory(
        snap.value,
        item.title,
        usersByUid,
      );
      if (rows.isEmpty) {
        rows.addAll(_collectAnyBillRows(snap.value, usersByUid));
      }
      if (rows.isEmpty) {
        rows.add(['Unknown User', '-', '-', '-', '-', '-', '-', '-', '-']);
      }
      rows.sort((a, b) {
        final aTs = _uploadedAtSortValue(a);
        final bTs = _uploadedAtSortValue(b);
        return bTs.compareTo(aTs);
      });
      final file = await _exportCategoryBillsToPdf(
        categoryTitle: item.title,
        categoryDescription: item.subtitle,
        rows: rows,
      );
      if (!mounted) return;
      AppSnackBar.showSuccess(
        context,
        '${loc.pdfExportSaved(file.path)}\nRows: ${rows.length}',
      );
    } catch (e, st) {
      AppErrorReporter.debug('category pdf export', e, st);
      if (mounted) {
        AppSnackBar.showError(context, loc.pdfExportFailed);
      }
    } finally {
      if (mounted) LoadingOverlay.hide();
    }
  }

  /// Rows without header:
  /// userName, email, billingMonth, date, consumption, amount, invoice, account, uploadedAt.
  List<List<String>> _collectBillRowsForCategory(
    Object? data,
    String categoryName,
    Map<String, _UserProfile> usersByUid,
  ) {
    final kind = BillTypeUtils.billKindForCategoryName(categoryName);
    final targetKey = BillTypeUtils.canonicalTypeKey(categoryName);
    final rows = <List<String>>[];
    if (data is Map) {
      for (final uidEntry in data.entries) {
        final uid = uidEntry.key.toString();
        _collectRowsFromNode(
          rows: rows,
          node: uidEntry.value,
          uid: uid,
          kind: kind,
          targetKey: targetKey,
          usersByUid: usersByUid,
        );
      }
    } else if (data is List) {
      for (var i = 0; i < data.length; i++) {
        _collectRowsFromNode(
          rows: rows,
          node: data[i],
          uid: '-',
          kind: kind,
          targetKey: targetKey,
          fallbackBillId: i.toString(),
          usersByUid: usersByUid,
        );
      }
    }
    if (rows.isEmpty && (kind == 'electricity' || kind == 'water')) {
      // Last-resort fallback for legacy rows that miss type/unit fields:
      // include rows with clear bill-like payload to avoid empty export.
      _collectFallbackBillLikeRows(rows, data, usersByUid);
    }
    return rows;
  }

  void _collectRowsFromNode({
    required List<List<String>> rows,
    required Object? node,
    required String uid,
    required String? kind,
    required String targetKey,
    required Map<String, _UserProfile> usersByUid,
    String? fallbackBillId,
  }) {
    if (node is Map) {
      final isDirectBillNode =
          node.containsKey('type') ||
          node.containsKey('dateText') ||
          node.containsKey('totalAmount');
      if (isDirectBillNode) {
        final row = _buildCategoryExportRow(
          raw: node,
          uid: uid,
          billId: fallbackBillId ?? uid,
          kind: kind,
          targetKey: targetKey,
          usersByUid: usersByUid,
        );
        if (row != null) rows.add(row);
        return;
      }
      for (final entry in node.entries) {
        _collectRowsFromNode(
          rows: rows,
          node: entry.value,
          uid: uid,
          kind: kind,
          targetKey: targetKey,
          fallbackBillId: entry.key.toString(),
          usersByUid: usersByUid,
        );
      }
      return;
    }
    if (node is List) {
      for (var i = 0; i < node.length; i++) {
        _collectRowsFromNode(
          rows: rows,
          node: node[i],
          uid: uid,
          kind: kind,
          targetKey: targetKey,
          fallbackBillId: '$uid-$i',
          usersByUid: usersByUid,
        );
      }
    }
  }

  void _collectFallbackBillLikeRows(
    List<List<String>> rows,
    Object? data,
    Map<String, _UserProfile> usersByUid,
  ) {
    void walk(Object? node, {required String uid, String billId = '-'}) {
      if (node is Map) {
        final hasBillShape =
            node.containsKey('totalAmount') ||
            node.containsKey('dateText') ||
            node.containsKey('consumptionValue');
        if (hasBillShape) {
          rows.add([
            _compactCell(_userNameForUid(uid, usersByUid), max: 18),
            _compactCell(_emailForUid(uid, usersByUid), max: 22),
            _billingMonthFromNode(node),
            node['dateText']?.toString() ?? '',
            _formatConsumptionValue(node['consumptionValue']),
            _formatAmountOmr(node['totalAmount']),
            node['invoiceNumber']?.toString() ?? '',
            node['accountNumber']?.toString() ?? '',
            _formatUploadedAt(node['createdAt']),
          ]);
          return;
        }
        for (final e in node.entries) {
          walk(e.value, uid: uid == '-' ? e.key.toString() : uid, billId: e.key.toString());
        }
      } else if (node is List) {
        for (var i = 0; i < node.length; i++) {
          walk(node[i], uid: uid, billId: '$billId-$i');
        }
      }
    }

    if (data is Map) {
      for (final e in data.entries) {
        walk(e.value, uid: e.key.toString(), billId: e.key.toString());
      }
    } else {
      walk(data, uid: '-');
    }
  }

  List<List<String>> _collectAnyBillRows(
    Object? data,
    Map<String, _UserProfile> usersByUid,
  ) {
    final rows = <List<String>>[];
    void walk(Object? node, {required String uid, String billId = '-'}) {
      if (node is Map) {
        final hasBillShape =
            node.containsKey('totalAmount') ||
            node.containsKey('dateText') ||
            node.containsKey('consumptionValue') ||
            node.containsKey('billingMonthKey');
        if (hasBillShape) {
          rows.add([
            _compactCell(_userNameForUid(uid, usersByUid), max: 18),
            _compactCell(_emailForUid(uid, usersByUid), max: 22),
            _billingMonthFromNode(node),
            node['dateText']?.toString() ?? '',
            _formatConsumptionValue(node['consumptionValue']),
            _formatAmountOmr(node['totalAmount']),
            node['invoiceNumber']?.toString() ?? '',
            node['accountNumber']?.toString() ?? '',
            _formatUploadedAt(node['createdAt']),
          ]);
          return;
        }
        for (final e in node.entries) {
          walk(
            e.value,
            uid: uid == '-' ? e.key.toString() : uid,
            billId: e.key.toString(),
          );
        }
      } else if (node is List) {
        for (var i = 0; i < node.length; i++) {
          walk(node[i], uid: uid, billId: '$billId-$i');
        }
      }
    }

    if (data is Map) {
      for (final e in data.entries) {
        walk(e.value, uid: e.key.toString(), billId: e.key.toString());
      }
    } else {
      walk(data, uid: '-');
    }
    return rows;
  }

  List<String>? _buildCategoryExportRow({
    required Map raw,
    required String uid,
    required String billId,
    required String? kind,
    required String targetKey,
    required Map<String, _UserProfile> usersByUid,
  }) {
    final t = raw['type']?.toString() ?? '';
    final canonicalBillType = BillTypeUtils.canonicalTypeKey(t).toLowerCase();
    final canonicalTargetType = targetKey.toLowerCase();
    final matchesKind = kind != null && BillTypeUtils.billMatchesKind(t, kind);
    final matchesCanonical = canonicalBillType == canonicalTargetType;
    final matchesByUnit = _matchesCategoryByUnit(
      raw['consumptionUnit']?.toString(),
      kind: kind,
      canonicalTargetType: canonicalTargetType,
    );
    final matches = matchesKind || matchesCanonical || matchesByUnit;
    if (!matches) return null;
    return [
      _compactCell(_userNameForUid(uid, usersByUid), max: 18),
      _compactCell(_emailForUid(uid, usersByUid), max: 22),
      _billingMonthFromNode(raw),
      raw['dateText']?.toString() ?? '',
      _formatConsumptionValue(raw['consumptionValue']),
      _formatAmountOmr(raw['totalAmount']),
      raw['invoiceNumber']?.toString() ?? '',
      raw['accountNumber']?.toString() ?? '',
      _formatUploadedAt(raw['createdAt']),
    ];
  }

  Future<File> _exportCategoryBillsToPdf({
    required String categoryTitle,
    required String categoryDescription,
    required List<List<String>> rows,
  }) async {
    final doc = pw.Document();
    final tableData = [
      [
        'User Name',
        'Email',
        'Billing Month',
        'Date',
        'Consumption',
        'Amount',
        'Invoice',
        'Account',
        'Uploaded At',
      ],
      ...rows,
    ];
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build:
            (context) => [
              pw.Text(
                'Category Bills Export',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                categoryTitle,
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Unit: ${_unitForCategoryTitle(categoryTitle)}',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Currency: OMR',
                style: const pw.TextStyle(fontSize: 11),
              ),
              if (categoryDescription.trim().isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  categoryDescription.trim(),
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
              pw.SizedBox(height: 12),
              pw.Text(
                'Rows: ${rows.length}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                data: tableData,
                headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF1E88E5),
                ),
                oddRowDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF4F8FF),
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 8),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.1),
                  1: const pw.FlexColumnWidth(1.2),
                  2: const pw.FlexColumnWidth(1.0),
                  3: const pw.FlexColumnWidth(1.1),
                  4: const pw.FlexColumnWidth(0.9),
                  5: const pw.FlexColumnWidth(1.1),
                  6: const pw.FlexColumnWidth(1.1),
                  7: const pw.FlexColumnWidth(1.1),
                  8: const pw.FlexColumnWidth(1.4),
                },
                cellPadding: const pw.EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 4,
                ),
              ),
            ],
      ),
    );
    final directory = await getAdminDownloadDirectory();
    final base = safeExportFileName(categoryTitle);
    final now = DateTime.now();
    final stamp =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}';
    final fileName =
        'Category-Bills_${base}_$stamp.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  String _formatUploadedAt(dynamic createdAtRaw) {
    final timestamp = int.tryParse(createdAtRaw?.toString() ?? '');
    if (timestamp == null || timestamp <= 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd hh:mm a').format(dt);
  }

  bool _matchesCategoryByUnit(
    String? rawUnit, {
    required String? kind,
    required String canonicalTargetType,
  }) {
    final unit = (rawUnit ?? '').trim().toLowerCase();
    if (unit.isEmpty) return false;
    final isElectricUnit = unit == 'kwh';
    final isWaterUnit = unit == 'm³' || unit == 'm3' || unit == 'م³';
    if (kind == 'electricity' || canonicalTargetType == 'electricity') {
      return isElectricUnit;
    }
    if (kind == 'water' || canonicalTargetType == 'water') {
      return isWaterUnit;
    }
    return false;
  }

  String _compactCell(String input, {int max = 16}) {
    final s = input.trim();
    if (s.length <= max) return s;
    return '${s.substring(0, max)}...';
  }

  String _unitForCategoryTitle(String categoryTitle) {
    final kind = BillTypeUtils.billKindForCategoryName(categoryTitle);
    if (kind == 'electricity') return 'kWh';
    if (kind == 'water') return 'm³';
    return '-';
  }

  String _formatConsumptionValue(dynamic rawValue) {
    final value = _toDouble(rawValue);
    if (value == null) return '-';
    return value.toStringAsFixed(3);
  }

  String _formatAmountOmr(dynamic rawValue) {
    final value = _toDouble(rawValue);
    if (value == null) return '-';
    return '${value.toStringAsFixed(3)} OMR';
  }

  double? _toDouble(dynamic rawValue) {
    if (rawValue == null) return null;
    if (rawValue is num) return rawValue.toDouble();
    final parsed = double.tryParse(rawValue.toString().trim());
    return parsed;
  }

  int _uploadedAtSortValue(List<String> row) {
    if (row.isEmpty) return 0;
    final raw = row.last.trim();
    if (raw.isEmpty || raw == '-') return 0;
    try {
      return DateFormat('yyyy-MM-dd hh:mm a').parse(raw).millisecondsSinceEpoch;
    } catch (_) {
      return 0;
    }
  }

  Map<String, _UserProfile> _extractUsersProfileMap(Object? value) {
    final result = <String, _UserProfile>{};
    if (value is! Map) return result;
    for (final e in value.entries) {
      final uid = e.key.toString();
      final raw = e.value;
      if (raw is! Map) continue;
      result[uid] = _UserProfile(
        fullName: raw['fullName']?.toString() ?? '',
        email: raw['email']?.toString() ?? '',
      );
    }
    return result;
  }

  String _userNameForUid(String uid, Map<String, _UserProfile> usersByUid) {
    if (uid == '-') return 'Unknown User';
    final profile = usersByUid[uid];
    final name = profile?.fullName.trim() ?? '';
    return name.isEmpty ? 'User $uid' : name;
  }

  String _emailForUid(String uid, Map<String, _UserProfile> usersByUid) {
    if (uid == '-') return '-';
    final profile = usersByUid[uid];
    final email = profile?.email.trim() ?? '';
    return email.isEmpty ? '-' : email;
  }

  String _billingMonthFromNode(Map node) {
    final text = (node['billingMonthText']?.toString() ?? '').trim();
    if (text.isNotEmpty) return text;
    final key = (node['billingMonthKey']?.toString() ?? '').trim();
    if (key.isNotEmpty) return key;
    return '-';
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

  void _showAddDialog() {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final fallback = CategoryRtdbStyle.fallbackForName('');
    _showCategoryEditorDialog(
      title: localizations.addCategory,
      primaryLabel: localizations.add,
      primaryColor: const Color(0xFF4CD964),
      initialName: '',
      initialDescription: '',
      initialColor: fallback.cardColor,
      initialIcon: fallback.icon,
      onSubmit: (name, description, colorArgb, iconCodePoint) {
        if (name.trim().isEmpty) return;
        _categoriesRef.push().set({
          'name': name.trim(),
          'description':
              description.trim().isEmpty ? '' : description.trim(),
          'billsCount': 0,
          'colorArgb': colorArgb,
          'iconCodePoint': iconCodePoint,
        });
      },
    );
  }

  void _showUpdateDialog(_CategoryItem item) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    _showCategoryEditorDialog(
      title: localizations.updateCategory,
      primaryLabel: localizations.update,
      primaryColor: const Color(0xFF4CD964),
      initialName: item.title,
      initialDescription: item.subtitle,
      initialColor: item.color,
      initialIcon: item.icon,
      onSubmit: (name, description, colorArgb, iconCodePoint) {
        if (name.trim().isEmpty) return;
        _categoriesRef.child(item.id).update({
          'name': name.trim(),
          'description':
              description.trim().isEmpty ? item.subtitle : description.trim(),
          'billsCount': item.billsCount,
          'colorArgb': colorArgb,
          'iconCodePoint': iconCodePoint,
        });
      },
    );
  }

  void _confirmDelete(_CategoryItem item) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(localizations.deleteCategory),
            content: Text(
              '${localizations.delete} "${item.title}"?\n\n'
              '${localizations.deleteCategoryCascadeBills}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.cancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteCategoryAndBills(item);
                },
                child: Text(
                  localizations.delete,
                  style: const TextStyle(color: Color(0xFFE44B4B)),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteCategoryAndBills(_CategoryItem item) async {
    LoadingOverlay.show(context);
    try {
      await AdminBillCleanupService.deleteAllBillsForCategoryName(item.title);
      await _categoriesRef.child(item.id).remove();
      if (!mounted) return;
      final loc =
          AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
      AppSnackBar.showSuccess(
        context,
        loc.categoryAndRelatedBillsRemoved,
        duration: const Duration(seconds: 2),
      );
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          AppLocalizations.of(context)?.billProcessingError ??
              'Could not complete delete.',
        );
      }
    } finally {
      if (mounted) LoadingOverlay.hide();
    }
  }

  void _showCategoryEditorDialog({
    required String title,
    required String primaryLabel,
    required Color primaryColor,
    required String initialName,
    required String initialDescription,
    required Color initialColor,
    required IconData initialIcon,
    required void Function(
      String name,
      String description,
      int colorArgb,
      int iconCodePoint,
    )
    onSubmit,
  }) {
    final loc =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder:
          (dialogContext) => _CategoryEditorDialog(
            title: title,
            primaryLabel: primaryLabel,
            primaryColor: primaryColor,
            initialName: initialName,
            initialDescription: initialDescription,
            initialColor: initialColor,
            initialIcon: initialIcon,
            localizations: loc,
            onSubmit: onSubmit,
          ),
    );
  }

  Future<void> _seedCategoriesIfEmpty() async {
    final snapshot = await _categoriesRef.get();
    if (snapshot.exists) return;
    await _categoriesRef.push().set({
      'name': 'Electricity',
      'description': 'Electricity Bills and Invoices',
      'billsCount': 0,
      'colorArgb': colorToArgb(const Color(0xFFFFA25B)),
      'iconCodePoint': Icons.flash_on.codePoint,
    });
    await _categoriesRef.push().set({
      'name': 'Water',
      'description': 'Water Bills and Invoices',
      'billsCount': 0,
      'colorArgb': colorToArgb(const Color(0xFF63B0FF)),
      'iconCodePoint': Icons.water_drop.codePoint,
    });
  }

  List<_CategoryItem> _parseCategories(
    Object? value,
    Map<String, int> billCounts,
  ) {
    if (value == null) return [];
    final data = value as Map<dynamic, dynamic>;
    final rawItems =
        data.entries.map((entry) {
          final raw = entry.value as Map<dynamic, dynamic>;
          return _RawCategory(
            id: entry.key.toString(),
            name: (raw['name'] ?? '').toString(),
            description: (raw['description'] ?? '').toString(),
            billsCount: (raw['billsCount'] as num?)?.toInt() ?? 0,
            raw: raw,
          );
        }).toList();
    return rawItems.map((raw) {
      final style = CategoryRtdbStyle.fromMap(raw.raw, raw.name);
      final dynamicCount = _countForCategoryName(raw.name, billCounts);
      return _CategoryItem(
        id: raw.id,
        title: raw.name,
        subtitle: raw.description,
        billsCount: dynamicCount,
        color: style.cardColor,
        iconColor: style.iconTint,
        badgeColor: style.badgeColor,
        icon: style.icon,
      );
    }).toList();
  }

  Map<String, int> _countBillsByType(Object? data) {
    final counts = <String, int>{};
    if (data is Map) {
      for (final userEntry in data.values) {
        if (userEntry is Map) {
          for (final billEntry in userEntry.values) {
            if (billEntry is Map) {
              final rawType = billEntry['type']?.toString() ?? '';
              final key = BillTypeUtils.canonicalTypeKey(rawType);
              if (key.isEmpty) continue;
              counts[key] = (counts[key] ?? 0) + 1;
            }
          }
        }
      }
    }
    return counts;
  }

  int _countForCategoryName(String name, Map<String, int> billCounts) {
    final key = BillTypeUtils.canonicalTypeKey(name);
    return billCounts[key] ?? 0;
  }
}

class _CategoryItem {
  final String id;
  final String title;
  final String subtitle;
  final int billsCount;
  final Color color;
  final Color iconColor;
  final Color badgeColor;
  final IconData icon;

  const _CategoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.billsCount,
    required this.color,
    required this.iconColor,
    required this.badgeColor,
    required this.icon,
  });
}
class _RawCategory {
  final String id;
  final String name;
  final String description;
  final int billsCount;
  final Map<dynamic, dynamic> raw;

  const _RawCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.billsCount,
    required this.raw,
  });
}

class _UserProfile {
  final String fullName;
  final String email;

  const _UserProfile({required this.fullName, required this.email});
}

/// Preset colors + icons for admin category editor (stored as [colorArgb] / [iconCodePoint] in RTDB).
const List<Color> _kCategoryPalette = [
  Color(0xFFFFA25B),
  Color(0xFF63B0FF),
  Color(0xFF61F26B),
  Color(0xFFB39DDB),
  Color(0xFFFF8A65),
  Color(0xFF4FC3F7),
  Color(0xFFFFD54F),
  Color(0xFF90A4AE),
  Color(0xFFFF5252),
  Color(0xFF26A69A),
  Color(0xFF5C6BC0),
  Color(0xFFFFB74D),
];

const List<IconData> _kCategoryIconChoices = [
  Icons.flash_on,
  Icons.water_drop,
  Icons.wifi,
  Icons.receipt_long,
  Icons.local_fire_department,
  Icons.bolt,
  Icons.home,
  Icons.phone_android,
  Icons.electric_bolt,
  Icons.shower,
  Icons.router,
  Icons.savings,
  Icons.eco,
  Icons.ac_unit,
  Icons.lightbulb,
];

class _CategoryEditorDialog extends StatefulWidget {
  final String title;
  final String primaryLabel;
  final Color primaryColor;
  final String initialName;
  final String initialDescription;
  final Color initialColor;
  final IconData initialIcon;
  final AppLocalizations localizations;
  final void Function(
    String name,
    String description,
    int colorArgb,
    int iconCodePoint,
  )
  onSubmit;

  const _CategoryEditorDialog({
    required this.title,
    required this.primaryLabel,
    required this.primaryColor,
    required this.initialName,
    required this.initialDescription,
    required this.initialColor,
    required this.initialIcon,
    required this.localizations,
    required this.onSubmit,
  });

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late Color _selectedColor;
  late IconData _selectedIcon;
  late List<IconData> _iconChoices;
  late List<Color> _colorChoices;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descController = TextEditingController(text: widget.initialDescription);
    _selectedColor = widget.initialColor;
    _selectedIcon = widget.initialIcon;
    _iconChoices = List<IconData>.from(_kCategoryIconChoices);
    if (!_iconChoices.any((i) => i.codePoint == _selectedIcon.codePoint)) {
      _iconChoices.insert(0, _selectedIcon);
    }
    _colorChoices = List<Color>.from(_kCategoryPalette);
    if (!_colorChoices.any((c) => c == _selectedColor)) {
      _colorChoices.insert(0, _selectedColor);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.localizations;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.92,
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFECECEC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDialogField(
                  controller: _nameController,
                  icon: Icons.category,
                  hint: loc.categoryName,
                ),
                const SizedBox(height: 10),
                _buildDialogField(
                  controller: _descController,
                  icon: Icons.description,
                  hint: loc.descriptionOptional,
                ),
                const SizedBox(height: 12),
                Text(
                  loc.categoryColor,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _colorChoices.map((c) {
                        final selected = c == _selectedColor;
                        return InkWell(
                          onTap: () => setState(() => _selectedColor = c),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    selected
                                        ? AppColors.textDark
                                        : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  loc.categoryIcon,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children:
                      _iconChoices.map((icon) {
                        final selected = icon.codePoint == _selectedIcon.codePoint;
                        return InkWell(
                          onTap: () => setState(() => _selectedIcon = icon),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  selected
                                      ? const Color(0xFFD1D1D1)
                                      : const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    selected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Icon(icon, size: 22, color: AppColors.textDark),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildDialogButton(
                      label: loc.cancel,
                      color: const Color(0xFFE44B4B),
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    _buildDialogButton(
                      label: widget.primaryLabel,
                      color: widget.primaryColor,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSubmit(
                          _nameController.text,
                          _descController.text,
                          colorToArgb(_selectedColor),
                          _selectedIcon.codePoint,
                        );
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

  Widget _buildDialogField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFD1D1D1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          icon: Icon(icon, size: 16, color: AppColors.textDark),
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDialogButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

