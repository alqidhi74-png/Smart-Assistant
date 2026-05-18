import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../constants/colors.dart';
import '../constants/language.dart';
import '../data/bill_store.dart';
import '../models/bill_analysis.dart';
import '../models/bill_summary.dart';
import '../services/bill_analysis_service.dart';
import '../services/category_policy_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/bill_date_utils.dart';

class BillReviewPage extends StatefulWidget {
  final BillAnalysisResult analysis;
  final Set<String> allowedUtilityKinds;
  final String? imagePath;

  const BillReviewPage({
    super.key,
    required this.analysis,
    required this.allowedUtilityKinds,
    this.imagePath,
  });

  @override
  State<BillReviewPage> createState() => _BillReviewPageState();
}

class _BillReviewPageState extends State<BillReviewPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dateController;
  late final TextEditingController _totalController;
  late final TextEditingController _consumptionController;
  late final TextEditingController _unitController;
  late final TextEditingController _invoiceController;
  late final TextEditingController _accountController;
  late final TextEditingController _billingMonthTextController;
  late final TextEditingController _billingMonthKeyController;
  late final TextEditingController _currentMonthController;
  late final TextEditingController _consumptionDaysController;
  late final TextEditingController _taxController;

  late bool _isWater;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.analysis;
    final allowE = widget.allowedUtilityKinds.contains('electricity');
    final allowW = widget.allowedUtilityKinds.contains('water');

    if (!BillAnalysisService.isAcceptedUtilityBill(a)) {
      _isWater = false;
      _initControllersForAnalysis(a);
      _scheduleReject(_loc.billOnlyWaterElectricAllowed);
      return;
    }
    if (widget.allowedUtilityKinds.isEmpty) {
      _isWater = a.billType == 'Water';
      _initControllersForAnalysis(a);
      _scheduleReject(_loc.noUtilityCategoriesConfigured);
      return;
    }
    if (!CategoryPolicyService.isBillTypeAllowedByCategories(
      a.billType,
      widget.allowedUtilityKinds,
    )) {
      _isWater = a.billType == 'Water';
      _initControllersForAnalysis(a);
      _scheduleReject(_loc.billTypeRemovedByAdmin);
      return;
    }

    if (allowW && !allowE) {
      _isWater = true;
    } else if (allowE && !allowW) {
      _isWater = false;
    } else {
      _isWater = a.billType == 'Water';
    }
    _initControllersForAnalysis(a);
  }

  void _initControllersForAnalysis(BillAnalysisResult a) {
    final effectiveType = _isWater ? 'Water' : 'Electricity';
    _dateController = TextEditingController(
      text: _normalizeDateDisplay(a.invoiceDate ?? a.periodText ?? ''),
    );
    _totalController = TextEditingController(text: _formatNum(a.totalAmount));
    _consumptionController = TextEditingController(
      text: _formatNum(a.consumptionValue),
    );
    _unitController = TextEditingController(
      text: _defaultUnitForType(effectiveType, a.consumptionUnit),
    );
    _invoiceController = TextEditingController(text: a.invoiceNumber ?? '');
    _accountController = TextEditingController(text: a.accountNumber ?? '');
    _billingMonthTextController = TextEditingController(
      text: a.billingMonthText ?? '',
    );
    _billingMonthKeyController = TextEditingController(
      text: a.billingMonthKey ?? '',
    );
    _currentMonthController = TextEditingController(
      text: _formatNum(a.currentMonthAmount),
    );
    _consumptionDaysController = TextEditingController(
      text: a.consumptionDays?.toString() ?? '',
    );
    _taxController = TextEditingController(text: _formatNum(a.taxAmount));
  }

  void _scheduleReject(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppSnackBar.showError(context, message);
      Navigator.of(context).pop();
    });
  }

  static String _defaultUnitForType(String? billType, String? unit) {
    final u = unit?.trim() ?? '';
    if (u.isNotEmpty) return u;
    if (billType == 'Water') return 'm³';
    return 'kWh';
  }

  static String _normalizeDateDisplay(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    final p = BillDateUtils.parseDateText(t);
    if (p != null) {
      return intl.DateFormat('yyyy-MM-dd').format(p);
    }
    return t;
  }

  static String _formatNum(double? v) {
    if (v == null) return '';
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toString();
  }

  void _onBillTypeChanged(bool water) {
    setState(() {
      _isWater = water;
      _unitController.text = water ? 'm³' : 'kWh';
    });
  }

  Future<void> _pickInvoiceDate() async {
    final locale = Localizations.localeOf(context);
    DateTime initial = DateTime.now();
    final parsed = BillDateUtils.parseDateText(_dateController.text);
    if (parsed != null) initial = parsed;

    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: locale,
    );
    if (!mounted || d == null) return;

    setState(() {
      _dateController.text = intl.DateFormat('yyyy-MM-dd').format(d);
      if (_billingMonthKeyController.text.trim().isEmpty) {
        _billingMonthKeyController.text =
            '${d.year}-${d.month.toString().padLeft(2, '0')}';
      }
      if (_billingMonthTextController.text.trim().isEmpty) {
        _billingMonthTextController.text = _formatMonthLabel(d, locale);
      }
    });
  }

  Future<void> _pickBillingMonth() async {
    final locale = Localizations.localeOf(context);
    DateTime initial = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final key = _billingMonthKeyController.text.trim();
    final parts = key.split('-');
    if (parts.length == 2) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (y != null && m != null && m >= 1 && m <= 12) {
        initial = DateTime(y, m, 1);
      }
    } else {
      final fromDate = BillDateUtils.parseDateText(_dateController.text);
      if (fromDate != null) {
        initial = DateTime(fromDate.year, fromDate.month, 1);
      }
    }

    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: locale,
      helpText: _loc.pickBillingMonthAction,
    );
    if (!mounted || d == null) return;

    setState(() {
      _billingMonthKeyController.text =
          '${d.year}-${d.month.toString().padLeft(2, '0')}';
      _billingMonthTextController.text = _formatMonthLabel(d, locale);
    });
  }

  static String _formatMonthLabel(DateTime d, Locale locale) {
    try {
      return intl.DateFormat.yMMMM(
        locale.toString(),
      ).format(DateTime(d.year, d.month, 1));
    } catch (_) {
      return '${d.month}/${d.year}';
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _totalController.dispose();
    _consumptionController.dispose();
    _unitController.dispose();
    _invoiceController.dispose();
    _accountController.dispose();
    _billingMonthTextController.dispose();
    _billingMonthKeyController.dispose();
    _currentMonthController.dispose();
    _consumptionDaysController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  static double? _parseDoubleLoose(String raw) {
    var s = raw.trim().replaceAll('٫', '.').replaceAll(' ', '');
    if (s.isEmpty) return null;
    if (s.contains(',') && s.contains('.')) {
      s = s.replaceAll(',', '');
    } else if (s.contains(',') && !s.contains('.')) {
      final p = s.split(',');
      if (p.length == 2 && p[1].length <= 3) {
        s = '${p[0]}.${p[1]}';
      } else {
        s = s.replaceAll(',', '');
      }
    }
    return double.tryParse(s);
  }

  static String? _normalizeBillingKey(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    final m = RegExp(r'^(20\d{2})-(\d{1,2})$').firstMatch(s);
    if (m != null) {
      final y = m.group(1)!;
      final mo = int.tryParse(m.group(2)!);
      if (mo != null && mo >= 1 && mo <= 12) {
        return '$y-${mo.toString().padLeft(2, '0')}';
      }
    }
    return s;
  }

  AppLocalizations get _loc =>
      AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final kind = _isWater ? 'water' : 'electricity';
    if (!widget.allowedUtilityKinds.contains(kind)) {
      AppSnackBar.showError(context, _loc.billTypeRemovedByAdmin);
      return;
    }

    final total = _parseDoubleLoose(_totalController.text);
    final consumption = _parseDoubleLoose(_consumptionController.text);
    final currentMonth = _parseDoubleLoose(_currentMonthController.text);
    final tax = _parseDoubleLoose(_taxController.text);
    final invoice = _invoiceController.text.trim();
    final billingKeyRaw = _billingMonthKeyController.text.trim();
    final billingText = _billingMonthTextController.text.trim();
    final account = _accountController.text.trim();

    setState(() => _saving = true);
    try {
      final createdAt = DateTime.now().millisecondsSinceEpoch;
      final normKey = _normalizeBillingKey(billingKeyRaw);
      final summary = BillSummary(
        id: createdAt.toString(),
        type: _isWater ? 'Water' : 'Electricity',
        dateText:
            _dateController.text.trim().isEmpty
                ? _loc.noDataFound
                : _dateController.text.trim(),
        consumptionValue: consumption,
        consumptionUnit: consumption != null ? (_isWater ? 'm³' : 'kWh') : null,
        totalAmount: total,
        taxAmount: tax,
        accountNumber: account.isEmpty ? null : account,
        invoiceNumber: invoice.isEmpty ? null : invoice,
        billingMonthText: billingText.isEmpty ? null : billingText,
        billingMonthKey: normKey,
        currentMonthAmount: currentMonth,
        consumptionDays: int.tryParse(_consumptionDaysController.text),
        createdAt: createdAt,
      );
      final updated = await BillStore.instance.saveBill(summary);
      if (mounted) {
        Navigator.of(context).pop({
          'status': updated ? 'updated' : 'created',
          'billType': _isWater ? 'Water' : 'Electricity',
          'billingMonthKey': _billingMonthKeyController.text.trim(),
        });
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, _loc.billProcessingError);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final subtextColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final hintColor = isDark ? Colors.grey[500] : Colors.grey[600];

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          _loc.billReviewTitle,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        backgroundColor: background,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(
          color: textColor,
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  Text(
                    _loc.billReviewTitle,
                    style: TextStyle(color: subtextColor, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _loc.billReviewHint,
                    style: TextStyle(color: hintColor, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  _buildToggle(isDark: isDark),
                  const SizedBox(height: 24),
                  _buildField(_loc.invoiceDate, _dateController, isDark: isDark, icon: Icons.calendar_today_outlined, onTap: _pickInvoiceDate),
                  _buildField(_loc.totalAmount, _totalController, isDark: isDark, suffix: 'OMR', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  _buildField(_loc.consumption, _consumptionController, isDark: isDark, suffix: _isWater ? 'm³' : 'kWh', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  _buildField(_loc.invoiceNumberTitle, _invoiceController, isDark: isDark, keyboardType: TextInputType.text),
                  _buildField(_loc.accountNumber, _accountController, isDark: isDark, keyboardType: TextInputType.number),
                  _buildField(_loc.billingMonthTitle, _billingMonthTextController, isDark: isDark, icon: Icons.calendar_month_outlined, onTap: _pickBillingMonth),
                ],
              ),
            ),
          ),
          _buildBottomActions(isDark: isDark, background: background),
        ],
      ),
    );
  }

  Widget _buildToggle({required bool isDark}) {
    final cardColor =
        isDark ? const Color(0xFF1E1E1E) : AppColors.backgroundWhite;
    final borderColor =
        isDark ? const Color(0xFF2C2C2C) : AppColors.borderLight;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _toggleItem(
              _loc.billTypeElectricity,
              !_isWater,
              isDark,
              () => _onBillTypeChanged(false),
            ),
          ),
          Expanded(
            child: _toggleItem(
              _loc.billTypeWater,
              _isWater,
              isDark,
              () => _onBillTypeChanged(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleItem(
    String label,
    bool active,
    bool isDark,
    VoidCallback onTap,
  ) {
    final inactiveText =
        isDark ? Colors.white70 : AppColors.textSecondary;
    return GestureDetector(
      onTap: active ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active) ...[
              const Icon(Icons.check, color: Colors.white, size: 16),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : inactiveText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    required bool isDark,
    String? suffix,
    IconData? icon,
    VoidCallback? onTap,
    TextInputType? keyboardType,
  }) {
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final labelColor = isDark ? Colors.white54 : AppColors.textSecondary;
    final fillColor =
        isDark ? const Color(0xFF1E1E1E) : AppColors.backgroundWhite;
    final borderColor =
        isDark ? const Color(0xFF2C2C2C) : AppColors.borderLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        style: TextStyle(color: textColor, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: labelColor, fontSize: 14),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          suffixText: suffix,
          suffixStyle: TextStyle(color: labelColor),
          suffixIcon:
              icon != null
                  ? Icon(icon, color: AppColors.primary, size: 20)
                  : null,
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions({
    required bool isDark,
    required Color background,
  }) {
    final cardColor =
        isDark ? const Color(0xFF1E1E1E) : AppColors.backgroundWhite;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(color: background),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _loc.cancel,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _saving
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        _loc.save,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
