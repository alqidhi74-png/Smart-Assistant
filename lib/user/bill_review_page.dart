import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;

import '../constants/app_layout.dart';
import '../constants/colors.dart';
import '../constants/language.dart';
import '../data/bill_store.dart';
import '../models/bill_analysis.dart';
import '../models/bill_summary.dart';
import '../services/bill_analysis_service.dart';
import '../services/category_policy_service.dart';
import '../core/utils.dart';

class BillReviewPage extends StatefulWidget {
  final BillAnalysisResult analysis;

  /// From [CategoryPolicyService.fetchAllowedUtilityKinds]: `electricity` / `water`.
  final Set<String> allowedUtilityKinds;

  const BillReviewPage({
    super.key,
    required this.analysis,
    required this.allowedUtilityKinds,
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
  }

  void _scheduleReject(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppSnackBar.showError(context, message);
      Navigator.of(context).pop(false);
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
      helpText:
          AppLocalizations.of(context)?.pickBillingMonthAction ??
          'Pick billing month',
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

  static int? _parseIntLoose(String raw) {
    final s = raw.trim().replaceAll(RegExp(r'\s'), '');
    if (s.isEmpty) return null;
    return int.tryParse(s);
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

  String _consumptionUnitForSave() {
    final u = _unitController.text.trim();
    if (u.isNotEmpty) return u;
    return _isWater ? 'm³' : 'kWh';
  }

  AppLocalizations get _loc =>
      AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));

  String? _validateRequired(String? v) {
    if (v == null || v.trim().isEmpty) return _loc.fieldRequired;
    return null;
  }

  String? _validatePositiveAmount(String? v) {
    final req = _validateRequired(v);
    if (req != null) return req;
    final n = _parseDoubleLoose(v!.trim());
    if (n == null || n <= 0) return _loc.billReviewErrInvalidNumber;
    return null;
  }

  String? _validateBillingKeyField(String? v) {
    final req = _validateRequired(v);
    if (req != null) return req;
    final norm = _normalizeBillingKey(v!.trim());
    if (norm == null || !RegExp(r'^\d{4}-\d{2}$').hasMatch(norm)) {
      return _loc.billReviewErrBillingKeyFormat;
    }
    return null;
  }

  String? _validateOptionalAmount(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    final n = _parseDoubleLoose(t);
    if (n == null || n < 0) return _loc.billReviewErrInvalidNumber;
    return null;
  }

  String? _validateOptionalDays(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    if (n == null || n < 1 || n > 366) {
      return _loc.billReviewErrInvalidNumber;
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final loc = _loc;
    final kind = _isWater ? 'water' : 'electricity';
    if (!widget.allowedUtilityKinds.contains(kind)) {
      AppSnackBar.showError(context, loc.billTypeRemovedByAdmin);
      return;
    }

    final total = _parseDoubleLoose(_totalController.text);
    final consumption = _parseDoubleLoose(_consumptionController.text);
    final currentMonth = _parseDoubleLoose(_currentMonthController.text);
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
                ? loc.noDataFound
                : _dateController.text.trim(),
        consumptionValue: consumption,
        consumptionUnit: consumption != null ? _consumptionUnitForSave() : null,
        totalAmount: total,
        accountNumber: account.isEmpty ? null : account,
        invoiceNumber: invoice.isEmpty ? null : invoice,
        billingMonthText: billingText.isEmpty ? null : billingText,
        billingMonthKey: normKey,
        currentMonthAmount: currentMonth,
        consumptionDays: _parseIntLoose(_consumptionDaysController.text),
        createdAt: createdAt,
      );
      await BillStore.instance.saveBill(summary);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, loc.billProcessingError);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final hintColor =
        isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary;

    InputDecoration deco(
      String label, {
      String? hint,
      String? suffixText,
      Widget? suffixIcon,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffixText,
        suffixIcon: suffixIcon,
        suffixStyle: TextStyle(color: hintColor, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      );
    }

    final consumptionSuffix = _isWater ? loc.chartUnitWater : loc.chartUnitKwh;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(loc.billReviewTitle),
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(
          color: textColor,
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppLayout.pagePaddingH + 6,
              0,
              AppLayout.pagePaddingH + 6,
              8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.billReviewHint,
                  style: TextStyle(color: hintColor, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  loc.billReviewChartHint,
                  style: TextStyle(color: hintColor, fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.pagePaddingH + 6,
                  vertical: AppLayout.pagePaddingV,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment<bool>(
                          value: false,
                          enabled: widget.allowedUtilityKinds.contains(
                            'electricity',
                          ),
                          label: Text(loc.billTypeElectricity),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          enabled: widget.allowedUtilityKinds.contains('water'),
                          label: Text(loc.billTypeWater),
                        ),
                      ],
                      selected: {_isWater},
                      onSelectionChanged:
                          _saving
                              ? null
                              : (s) {
                                _onBillTypeChanged(s.first);
                              },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: _saving ? null : () => _pickInvoiceDate(),
                      keyboardType: TextInputType.none,
                      validator: _validateRequired,
                      decoration: deco(
                        loc.invoiceDate,
                        hint: 'yyyy-MM-dd',
                        suffixIcon: IconButton(
                          tooltip: loc.pickInvoiceDateAction,
                          icon: Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          onPressed: _saving ? null : _pickInvoiceDate,
                        ),
                      ),
                      style: TextStyle(color: textColor),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _totalController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[\d.,٫٬،]'),
                        ),
                      ],
                      validator: _validatePositiveAmount,
                      decoration: deco(
                        loc.totalAmount,
                        hint: '0.000',
                        suffixText: loc.currencyOmr,
                      ),
                      style: TextStyle(color: textColor),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _currentMonthController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[\d.,٫٬،]'),
                        ),
                      ],
                      validator: _validateOptionalAmount,
                      decoration: deco(
                        loc.currentMonthCharge,
                        hint: '0.000',
                        suffixText: loc.currencyOmr,
                      ),
                      style: TextStyle(color: textColor),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _consumptionController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[\d.,٫٬،]'),
                        ),
                      ],
                      validator: _validatePositiveAmount,
                      decoration: deco(
                        loc.consumption,
                        hint: _isWater ? '0' : '0',
                        suffixText: consumptionSuffix,
                      ),
                      style: TextStyle(color: textColor),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _unitController,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.none,
                      validator: _validateRequired,
                      decoration: deco(
                        loc.consumptionUnitField,
                        hint:
                            _isWater
                                ? loc.consumptionWaterHint
                                : loc.consumptionElectricityHint,
                      ),
                      style: TextStyle(color: textColor),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _consumptionDaysController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      validator: _validateOptionalDays,
                      decoration: deco(loc.consumptionDaysLabel),
                      style: TextStyle(color: textColor),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _invoiceController,
                      keyboardType: TextInputType.text,
                      validator: _validateRequired,
                      decoration: deco(loc.invoiceNumberTitle),
                      style: TextStyle(color: textColor),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _accountController,
                      keyboardType: TextInputType.text,
                      validator: _validateRequired,
                      decoration: deco(loc.accountNumber),
                      style: TextStyle(color: textColor),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _billingMonthTextController,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.sentences,
                      validator: _validateRequired,
                      decoration: deco(loc.billingMonthTitle),
                      style: TextStyle(color: textColor),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _billingMonthKeyController,
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
                        LengthLimitingTextInputFormatter(7),
                      ],
                      validator: _validateBillingKeyField,
                      decoration: deco(
                        loc.billingMonthKeyField,
                        hint: '2025-03',
                        suffixIcon: IconButton(
                          tooltip: loc.pickBillingMonthAction,
                          icon: Icon(
                            Icons.date_range_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          onPressed: _saving ? null : _pickBillingMonth,
                        ),
                      ),
                      style: TextStyle(color: textColor),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: AppLayout.pagePadding,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _saving
                              ? null
                              : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(loc.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _saving
                              ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: AppLoadingIndicator(
                                  size: AppLoadingSize.inline,
                                  color: Colors.white,
                                ),
                              )
                              : Text(loc.save),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
