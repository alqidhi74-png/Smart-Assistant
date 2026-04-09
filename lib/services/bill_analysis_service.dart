import '../models/bill_analysis.dart';
import '../utils/billing_month_parser.dart';
import '../utils/text_normalize.dart';

class BillAnalysisService {
  /// Only water and electricity bills may continue to the review screen.
  static bool isAcceptedUtilityBill(BillAnalysisResult r) {
    return r.billType == 'Water' || r.billType == 'Electricity';
  }

  /// [displayRawText] is shown in [BillAnalysisResult.rawText] (e.g. original OCR);
  /// [text] is what gets normalized and parsed (typically NLP output).
  static BillAnalysisResult analyze(String text, {String? displayRawText}) {
    final normalized = _normalize(text);
    final lines = _mergeBrokenLines(
      normalized
          .split(RegExp(r'[\r\n]+'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(),
    );

    double? totalAmount;
    double? taxAmount;
    double? consumptionValue;
    String? consumptionUnit;
    String? periodText;
    String? billType;
    String? accountNumber;
    String? invoiceNumber;
    String? invoiceDate;
    final feeItems = <FeeItem>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      billType ??= _detectBillType(lower);

      if (invoiceNumber == null && _matchesAny(lower, _invoiceNumberMatchers)) {
        invoiceNumber = _extractInvoiceNumber(lines, i);
        if (invoiceNumber != null) {
          continue;
        }
      }

      if (invoiceDate == null && _matchesAny(lower, _invoiceDateMatchers)) {
        invoiceDate = _extractInvoiceDate(lines, i);
        if (invoiceDate != null) {
          continue;
        }
      }

      if (accountNumber == null && _matchesAny(lower, _accountMatchers)) {
        accountNumber = _extractAccountNumber(lines, i);
        if (accountNumber != null) {
          continue;
        }
      }

      if (totalAmount == null &&
          _isStrongTotalLine(lower, line) &&
          !_matchesAny(lower, _taxMatchers)) {
        final candidate = _extractNumberFromLines(lines, i);
        if (_isPlausibleBillAmount(candidate)) {
          totalAmount = candidate;
        }
        continue;
      }

      if (taxAmount == null && _matchesAny(lower, _taxMatchers)) {
        final candidate = _extractNumberFromLines(lines, i);
        if (_isPlausibleBillAmount(candidate)) {
          taxAmount = candidate;
        }
        continue;
      }

      if (consumptionValue == null && _isConsumptionLine(lower, line)) {
        final candidate = _extractNumberFromLines(lines, i);
        final unit =
            _detectConsumptionUnit(lower) ??
            (i + 1 < lines.length
                ? _detectConsumptionUnit(lines[i + 1].toLowerCase())
                : null);
        if (_isPlausibleConsumption(candidate, unit, billType)) {
          consumptionValue = candidate;
          consumptionUnit = unit;
        }
        continue;
      }

      if (periodText == null &&
          (_matchesAny(lower, _periodMatchers) || _hasDateRange(line))) {
        periodText = _extractPeriodFromLines(lines, i);
        continue;
      }

      if (_matchesAny(lower, _feeMatchers) &&
          !_matchesAny(lower, _totalStrongRe)) {
        feeItems.add(
          FeeItem(
            label: _cleanLabel(line, _feeKeywords),
            amount: _extractNumberFromLines(lines, i),
          ),
        );
      }
    }

    totalAmount ??= _extractTotalFromWeakLabels(lines);
    totalAmount ??= _extractTotalFromStrongLinesOnly(lines);
    totalAmount ??= _extractTotalFromNamaBarcodeLine(lines);
    if (totalAmount == null || !_isPlausibleBillAmount(totalAmount)) {
      final fb = _extractTotalFallback(lines);
      if (totalAmount == null) {
        totalAmount = fb;
      } else if (fb != null &&
          _isPlausibleBillAmount(fb) &&
          (totalAmount < 1 || totalAmount > 50000)) {
        totalAmount = fb;
      }
    }

    invoiceNumber ??= _extractInvoiceNumberFallback(lines);
    invoiceNumber ??= _extractNamaBarcodeInvoice(lines);
    invoiceNumber ??= _extractTwinLongInvoiceNumbers(lines);
    accountNumber ??= _extractAccountNumberFallback(lines);

    var inferredType = billType ?? _inferBillTypeFromUnit(consumptionUnit);
    inferredType ??= _inferBillTypeFromRawText(normalized.toLowerCase());
    var cUnit = consumptionUnit;
    var cVal = consumptionValue;
    cVal ??= _secondPassConsumption(lines, inferredType);
    totalAmount ??= _extractTypeAwareTotal(lines, inferredType);
    if (cVal != null) {
      if (inferredType == 'Electricity') {
        cUnit ??= 'kWh';
      } else if (inferredType == 'Water') {
        cUnit ??= 'm³';
      }
    }

    final currentMonthAmount = _extractCurrentMonthAmount(lines, totalAmount);
    final consumptionDays = _extractConsumptionDays(lines);

    var billingMonthText = BillingMonthParser.labelFromLines(lines);
    if (billingMonthText == null &&
        periodText != null &&
        periodText.length < 120) {
      billingMonthText = periodText;
    }
    var billingMonthKey = BillingMonthParser.monthKeyFromText(normalized);
    if (billingMonthKey == null && periodText != null) {
      billingMonthKey = BillingMonthParser.monthKeyFromText(periodText);
    }
    final invDate = invoiceDate ?? _findBestDate(lines);
    if (billingMonthKey == null && invDate != null) {
      billingMonthKey = BillingMonthParser.monthKeyFromText(invDate);
    }
    final totalAmountConfidence = _confidenceForAmount(totalAmount);
    final consumptionConfidence = _confidenceForConsumption(
      cVal,
      cUnit,
      inferredType,
    );
    final accountConfidence = _confidenceForAccount(accountNumber);
    final invoiceConfidence = _confidenceForInvoice(invoiceNumber);

    return BillAnalysisResult(
      rawText: (displayRawText ?? text).trim(),
      billType: inferredType,
      accountNumber: accountNumber,
      invoiceNumber: invoiceNumber,
      invoiceDate: invDate,
      totalAmount: totalAmount,
      taxAmount: taxAmount,
      consumptionValue: cVal,
      consumptionUnit: cUnit,
      periodText: periodText,
      feeItems: feeItems,
      billingMonthText: billingMonthText,
      billingMonthKey: billingMonthKey,
      currentMonthAmount: currentMonthAmount,
      consumptionDays: consumptionDays,
      totalAmountConfidence: totalAmountConfidence,
      consumptionConfidence: consumptionConfidence,
      accountConfidence: accountConfidence,
      invoiceConfidence: invoiceConfidence,
    );
  }

  static double? _extractTypeAwareTotal(List<String> lines, String? billType) {
    if (billType == null) return null;
    final waterHint = RegExp(
      r'(water|مياه|ماء|متر\s*مكعب|m3|m³)',
      caseSensitive: false,
    );
    final electricityHint = RegExp(
      r'(electric|كهرباء|kwh|kw)',
      caseSensitive: false,
    );
    final wantWater = billType == 'Water';
    double? best;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (!_matchesAny(lower, _totalStrongRe)) continue;
      final hasTypeHint =
          wantWater ? waterHint.hasMatch(line) : electricityHint.hasMatch(line);
      if (!hasTypeHint) continue;
      final n = _extractNumberFromLines(lines, i);
      if (_isPlausibleBillAmount(n) && n != null) {
        if (best == null || n > best) best = n;
      }
    }
    return best;
  }

  static double? _confidenceForAmount(double? value) {
    if (value == null) return null;
    if (value <= 0 || value > 50000) return 0.2;
    if (value < 1) return 0.4;
    if (value <= 3000) return 0.9;
    if (value <= 10000) return 0.75;
    return 0.6;
  }

  static double? _confidenceForConsumption(
    double? value,
    String? unit,
    String? billType,
  ) {
    if (value == null) return null;
    if (value <= 0) return 0.2;
    final u = unit?.trim() ?? '';
    if (billType == 'Water') {
      if (u != 'm³' && u.toLowerCase() != 'm3') return 0.45;
      if (value <= 300) return 0.9;
      if (value <= 1000) return 0.7;
      return 0.5;
    }
    if (billType == 'Electricity') {
      if (u.toLowerCase() != 'kwh') return 0.45;
      if (value <= 2500) return 0.9;
      if (value <= 7000) return 0.7;
      return 0.5;
    }
    return 0.6;
  }

  static double? _confidenceForAccount(String? account) {
    final a = account?.trim() ?? '';
    if (a.isEmpty) return null;
    final digits = RegExp(r'\d').allMatches(a).length;
    if (digits >= 8) return 0.9;
    if (digits >= 5) return 0.7;
    return 0.5;
  }

  static double? _confidenceForInvoice(String? invoice) {
    final i = invoice?.trim() ?? '';
    if (i.isEmpty) return null;
    final digits = RegExp(r'\d').allMatches(i).length;
    if (digits >= 8) return 0.9;
    if (digits >= 5) return 0.75;
    return 0.55;
  }

  static List<String> _mergeBrokenLines(List<String> raw) {
    if (raw.length <= 1) return raw;
    final merged = <String>[raw[0]];
    for (var i = 1; i < raw.length; i++) {
      final cur = raw[i].trim();
      final last = merged.last;
      if (cur.isEmpty) continue;
      if (RegExp(r'[:\-=]\s*$', caseSensitive: false).hasMatch(last) &&
          cur.length < 48 &&
          (_extractNumber(cur) != null ||
              RegExp(r'^[\d\s.,٫٬،]+$').hasMatch(cur.replaceAll(' ', '')))) {
        merged[merged.length - 1] = '$last $cur'.trim();
        continue;
      }
      if (RegExp(r'[،,\-–]\s*$').hasMatch(last) &&
          RegExp(r'^\d').hasMatch(cur) &&
          cur.length < 24) {
        merged[merged.length - 1] = '${last.trimRight()} $cur'.trim();
        continue;
      }
      final lastL = last.toLowerCase();
      final curL = cur.toLowerCase();
      if (RegExp(
            r'total\s+payable\s*$',
            caseSensitive: false,
          ).hasMatch(lastL) &&
          RegExp(r'^amount\s*$', caseSensitive: false).hasMatch(curL)) {
        merged[merged.length - 1] = '$last $cur'.trim();
        continue;
      }
      merged.add(cur);
    }
    return merged;
  }

  static double? _secondPassConsumption(List<String> lines, String? billType) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('units consumed')) {
        final unit =
            _detectConsumptionUnit(lower) ??
            (lower.contains('m3') || lower.contains('m³') ? 'm³' : 'kWh');
        final n = _extractNumber(line);
        if (n != null && _isPlausibleConsumption(n, unit, billType)) {
          return n;
        }
      }
    }
    for (final line in lines) {
      final lower = line.toLowerCase();
      final unit = _detectConsumptionUnit(lower);
      if (unit == null) continue;
      final n = _extractNumber(line);
      if (n != null && _isPlausibleConsumption(n, unit, billType)) {
        return n;
      }
    }
    return null;
  }

  static double? _extractTotalFromStrongLinesOnly(List<String> lines) {
    double? best;
    for (var i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      if (!_matchesAny(lower, _totalStrongRe)) continue;
      if (_matchesAny(lower, _taxMatchers)) continue;
      if (_looksLikeNonTotalContext(lower)) continue;
      final n = _extractNumberFromLines(lines, i);
      if (_isPlausibleBillAmount(n) && n != null) {
        if (best == null || n > best) best = n;
      }
    }
    return best;
  }

  static double? _extractCurrentMonthAmount(
    List<String> lines,
    double? totalAmount,
  ) {
    for (var i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      if (!_matchesAny(lower, _currentMonthRe)) continue;
      if (_isStrongTotalLine(lower, lines[i])) continue;
      final candidate = _extractNumberFromLines(lines, i);
      if (!_isPlausibleBillAmount(candidate)) continue;
      if (totalAmount != null &&
          candidate != null &&
          candidate > totalAmount * 1.1) {
        continue;
      }
      return candidate;
    }
    return null;
  }

  static int? _extractConsumptionDays(List<String> lines) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      final hasDayHint =
          lower.contains('day') ||
          line.contains('يوم') ||
          line.contains('أيام') ||
          line.contains('ايام');
      if (!hasDayHint) continue;
      if (lower.contains('birth') || lower.contains('to day')) continue;
      if (_matchesAny(lower, _consumptionDaysLabelRe)) {
        final n = _extractIntFromLine(line);
        if (n != null && n >= 1 && n <= 366) return n;
      }
      final m = RegExp(
        r'(\d{1,3})\s*(days?|أيام|أيام?|يوم)',
        caseSensitive: false,
      ).firstMatch(line);
      if (m != null) {
        final n = int.tryParse(m.group(1)!);
        if (n != null && n >= 1 && n <= 366) return n;
      }
    }
    return null;
  }

  static int? _extractIntFromLine(String line) {
    final sep = RegExp(r'[:=]\s*').firstMatch(line);
    if (sep != null) {
      final tail = line.substring(sep.end);
      final n = _extractNumber(tail);
      if (n != null) return n.round();
    }
    final matches = RegExp(r'\b(\d{1,3})\b').allMatches(line).toList();
    if (matches.isEmpty) return null;
    return int.tryParse(matches.last.group(1)!);
  }

  static bool _isStrongTotalLine(String lower, String originalLine) {
    if (_looksLikeNonTotalContext(lower)) return false;
    if (_matchesAny(lower, _totalStrongRe)) return true;
    if (_matchesAny(lower, _totalWeakRe)) {
      return _currencyPattern.hasMatch(originalLine) ||
          _looksLikeMoneyAmount(originalLine);
    }
    return false;
  }

  static bool _looksLikeMoneyAmount(String line) {
    return RegExp(r'[.,]\d{2}\b').hasMatch(line) ||
        RegExp(r'\b\d+[.,]\d{3}\b').hasMatch(line);
  }

  static bool _looksLikeNonTotalContext(String lower) {
    for (final n in _nonTotalNoiseSubstrings) {
      if (lower.contains(n)) return true;
    }
    return false;
  }

  static double? _extractTotalFromWeakLabels(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      if (_looksLikeNonTotalContext(lower)) continue;
      if (!_matchesAny(lower, _totalWeakRe)) continue;
      if (_matchesAny(lower, _taxMatchers)) continue;
      final candidate = _extractNumberFromLines(lines, i);
      if (_isPlausibleBillAmount(candidate)) return candidate;
    }
    return null;
  }

  static bool _isConsumptionLine(String lower, String originalLine) {
    if (_looksLikeNonTotalContext(lower)) return false;
    if (_detectConsumptionUnit(lower) != null) {
      return true;
    }
    if (_matchesAny(lower, _consumptionStrictRe)) return true;
    if (_matchesAny(lower, _consumptionLooseRe)) {
      return _hasUnitNearby(lower, originalLine);
    }
    return false;
  }

  static bool _hasUnitNearby(String lower, String originalLine) {
    return _detectConsumptionUnit(lower) != null ||
        lower.contains('kwh') ||
        lower.contains('kw ') ||
        originalLine.contains('³') ||
        lower.contains('m3') ||
        lower.contains('استهلاك');
  }

  static bool _matchesAny(String input, List<RegExp> matchers) {
    return matchers.any((matcher) => matcher.hasMatch(input));
  }

  static String _normalize(String input) {
    return TextNormalize.forBillAnalysis(input);
  }

  static double? _extractNumberFromLines(List<String> lines, int index) {
    final fromLabel = _extractNumberAfterLabel(lines[index]);
    if (fromLabel != null) return fromLabel;
    final current = _extractNumber(lines[index]);
    if (current != null) return current;
    if (index + 1 < lines.length) {
      return _extractNumber(lines[index + 1]);
    }
    return null;
  }

  static double? _extractNumberAfterLabel(String line) {
    final sep = RegExp(r'[:=]\s*').firstMatch(line);
    if (sep == null) return null;
    final tail = line.substring(sep.end);
    return _extractNumber(tail);
  }

  static double? _extractTotalFallback(List<String> lines) {
    final currencyLines =
        lines.where((line) => _currencyPattern.hasMatch(line)).toList();
    final strongTotalLines =
        lines
            .where(
              (line) =>
                  _matchesAny(line.toLowerCase(), _totalStrongRe) &&
                  !_looksLikeNonTotalContext(line.toLowerCase()),
            )
            .toList();
    final candidates = <String>{...currencyLines, ...strongTotalLines}.toList();
    final scan = candidates.isNotEmpty ? candidates : lines;
    final values = <double>[];
    for (final line in scan) {
      final lower = line.toLowerCase();
      if (_looksLikeNonTotalContext(lower)) continue;
      if (_matchesAny(lower, _accountMatchers) ||
          lower.contains('vatin') ||
          lower.contains('vat') ||
          _matchesAny(lower, _taxMatchers)) {
        continue;
      }
      final value = _extractNumber(line);
      if (value == null || !_isPlausibleBillAmount(value)) continue;
      if (value == value.roundToDouble() && value >= 100000) continue;
      values.add(value);
    }
    if (values.isEmpty) return null;
    values.sort();
    return values.last;
  }

  static bool _isPlausibleBillAmount(double? value) {
    if (value == null || value <= 0) return false;
    if (value > 500000) return false;
    return true;
  }

  static bool _isPlausibleConsumption(
    double? value,
    String? unit,
    String? billType,
  ) {
    if (value == null || value < 0) return false;
    if (unit == 'kWh' || billType == 'Electricity') {
      if (value > 200000) return false;
    }
    if (unit == 'm³' || unit == 'م³' || billType == 'Water') {
      if (value > 100000) return false;
    }
    if (value == 0) return false;
    return true;
  }

  static double? _extractNumber(String line) {
    var s = line;
    for (var k = 0; k < 8; k++) {
      final next = s.replaceAllMapped(
        RegExp(r'(\d)\s+(\d)'),
        (m) => '${m.group(1)}${m.group(2)}',
      );
      if (next == s) break;
      s = next;
    }
    final match = _numberPattern.allMatches(s).toList();
    if (match.isEmpty) return null;
    final numbers =
        match
            .map((m) => m.group(0))
            .whereType<String>()
            .map(_normalizeNumberString)
            .map(double.tryParse)
            .whereType<double>()
            .toList();
    if (numbers.isEmpty) return null;
    numbers.sort();
    return numbers.last;
  }

  static String _normalizeNumberString(String value) {
    var normalized = value.replaceAll(' ', '');
    if (normalized.contains(',') && normalized.contains('.')) {
      normalized = normalized.replaceAll(',', '');
    } else if (normalized.contains(',') && !normalized.contains('.')) {
      final parts = normalized.split(',');
      if (parts.length == 2 && parts[1].length == 3) {
        normalized = normalized.replaceAll(',', '');
      } else {
        normalized = normalized.replaceAll(',', '.');
      }
    }
    return normalized;
  }

  static String? _detectConsumptionUnit(String line) {
    if (line.contains('(kwh') ||
        line.contains('kwh)') ||
        line.contains('kwh') ||
        line.contains('kw h') ||
        line.contains('kw-h')) {
      return 'kWh';
    }
    if (line.contains('m3') || line.contains('m³') || line.contains('m^3')) {
      return 'm³';
    }
    if (line.contains('م3') || line.contains('م³')) return 'م³';
    if (line.contains('كيلو') || line.contains('ك.و') || line.contains('ك و')) {
      return 'kWh';
    }
    return null;
  }

  static bool _hasDateRange(String line) {
    return _datePattern.allMatches(line).length >= 2 ||
        (line.toLowerCase().contains('from') &&
            line.toLowerCase().contains('to') &&
            _datePattern.hasMatch(line)) ||
        (line.contains('من') &&
            line.contains('إلى') &&
            _datePattern.hasMatch(line));
  }

  static String? _extractPeriodFromLines(List<String> lines, int index) {
    final current = lines[index].trim();
    if (current.length > 3 && _datePattern.hasMatch(current)) {
      return current;
    }
    if (index + 1 < lines.length) {
      final next = lines[index + 1].trim();
      if (next.length > 3 && _datePattern.hasMatch(next)) {
        return next;
      }
    }
    return current.length > 3 ? current : null;
  }

  static String? _detectBillType(String line) {
    if (_matchesAny(line, _electricityMatchers)) return 'Electricity';
    if (_matchesAny(line, _waterMatchers)) return 'Water';
    return null;
  }

  static String? _inferBillTypeFromUnit(String? unit) {
    if (unit == null) return null;
    if (unit == 'kWh') return 'Electricity';
    if (unit == 'م³' || unit == 'm³') return 'Water';
    return null;
  }

  static String? _extractAccountNumber(List<String> lines, int index) {
    final current = _extractAccountFromLine(lines[index]);
    if (current != null) return current;
    if (index + 1 < lines.length) {
      final next = _extractAccountFromLine(lines[index + 1]);
      if (next != null) return next;
    }
    return null;
  }

  static String? _extractAccountFromLine(String line) {
    final match = _accountPattern.firstMatch(line);
    if (match == null) return null;
    final value = match.group(1);
    if (value == null) return null;
    return value.replaceAll(RegExp(r'\s+'), '');
  }

  static String? _extractAccountNumberFallback(List<String> lines) {
    for (final line in lines) {
      if (_datePattern.hasMatch(line)) continue;
      if (_invoiceNumberPattern.hasMatch(line)) continue;
      final match = _longNumberPattern.firstMatch(line);
      if (match != null) {
        return match.group(0);
      }
    }
    return null;
  }

  static String? _extractInvoiceNumber(List<String> lines, int index) {
    final current = _extractInvoiceNumberFromLine(lines[index]);
    if (current != null) return current;
    if (index + 1 < lines.length) {
      return _extractInvoiceNumberFromLine(lines[index + 1]);
    }
    return null;
  }

  static String? _extractInvoiceNumberFromLine(String line) {
    final match = _invoiceNumberPattern.firstMatch(line);
    if (match == null) return null;
    final value = match.group(1);
    if (value == null) return null;
    return value.replaceAll(RegExp(r'\s+'), '');
  }

  static String? _extractInvoiceNumberFallback(List<String> lines) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (!_matchesAny(lower, _invoiceNumberMatchers) &&
          !lower.contains('invoice') &&
          !line.contains('فاتورة')) {
        continue;
      }
      final match = _longNumberPattern.firstMatch(line);
      if (match != null) return match.group(0);
    }
    return null;
  }

  static String? _extractNamaBarcodeInvoice(List<String> lines) {
    for (final line in lines) {
      final m = _namaBarcodeInvoiceRe.firstMatch(line);
      if (m != null) return m.group(1);
    }
    return null;
  }

  static String? _extractTwinLongInvoiceNumbers(List<String> lines) {
    for (final line in lines) {
      final matches =
          RegExp(
            r'\b\d{12,16}\b',
          ).allMatches(line).map((m) => m.group(0)!).toList();
      if (matches.length >= 2) return matches[1];
    }
    return null;
  }

  static String? _extractInvoiceDate(List<String> lines, int index) {
    final current = _extractDateFromLine(lines[index]);
    if (current != null) return current;
    if (index + 1 < lines.length) {
      return _extractDateFromLine(lines[index + 1]);
    }
    return null;
  }

  static String? _extractDateFromLine(String line) {
    final iso = _isoDatePattern.firstMatch(line);
    if (iso != null) return iso.group(0);
    final match = _datePattern.firstMatch(line);
    return match?.group(0);
  }

  static String? _findBestDate(List<String> lines) {
    String? best;
    for (final line in lines) {
      final iso = _isoDatePattern.firstMatch(line);
      if (iso != null) return iso.group(0);
    }
    for (final line in lines) {
      final match = _datePattern.firstMatch(line);
      if (match != null) {
        best ??= match.group(0);
      }
    }
    return best;
  }

  static String? _inferBillTypeFromRawText(String lower) {
    if (RegExp(
      r'nama\s+water|water\s+services\s+bill|water\s+and\s+wastwater|فاتورة\s+المياه|diam|haya\s+water|public\s+authority\s+for\s+water|paw\s+water',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return 'Water';
    }
    if (RegExp(
      r'nama\s+electricity|nama\s+supply|namasupply|electricity\s+bill|electricity\s+supply|supply\.nama|oneic|majan|nama\s+electricity\s+supply',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return 'Electricity';
    }
    if (RegExp(
      r'units\s+consumed|consumption\s*\(kwh|kwh\s*units|\(kwh',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return 'Electricity';
    }
    if (lower.contains('kwh') || lower.contains('kilowatt')) {
      return 'Electricity';
    }
    if (lower.contains(' m3') ||
        lower.contains('m³') ||
        RegExp(r'consumption\s*\(m3', caseSensitive: false).hasMatch(lower)) {
      return 'Water';
    }
    return null;
  }

  static double? _extractTotalFromNamaBarcodeLine(List<String> lines) {
    for (final line in lines) {
      if (!line.toUpperCase().contains('EPC')) continue;
      final tail = RegExp(
        r'(\d+[.,]\d{1,5})\s*[Nn]?\s*~\s*$',
      ).firstMatch(line.trim());
      if (tail != null) {
        final v = double.tryParse(_normalizeNumberString(tail.group(1)!));
        if (_isPlausibleBillAmount(v)) return v;
      }
      final mid = RegExp(r'®+(\d+[.,]\d{2,6})').firstMatch(line);
      if (mid != null) {
        final v = double.tryParse(_normalizeNumberString(mid.group(1)!));
        if (_isPlausibleBillAmount(v)) return v;
      }
    }
    return null;
  }

  static String _cleanLabel(String line, List<String> keywords) {
    var cleaned = line;
    for (final keyword in keywords) {
      cleaned = cleaned.replaceAll(keyword, '');
    }
    cleaned = cleaned.replaceAll(RegExp(r'\d+([.,]\d+)?'), '').trim();
    return cleaned.isEmpty ? line : cleaned;
  }
}

final _numberPattern = RegExp(
  r'\d{1,3}(?:[ ,]\d{3})*(?:[.,]\d+)?|\d+(?:[.,]\d+)?',
);

final _datePattern = RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b');
final _isoDatePattern = RegExp(r'\b\d{4}[/-]\d{1,2}[/-]\d{1,2}\b');
final _longNumberPattern = RegExp(r'\b\d{6,}\b');
final _currencyPattern = RegExp(
  r'\b(omr|r\.?o\.?|rial|riyal|ريال|ر\.ع|ر\s*ع)\b',
  caseSensitive: false,
);
final _accountPattern = RegExp(
  r'(?:account|acct|subscriber|customer|رقم\s*الحساب|رقم\s*المشترك|رقم\s*الاشتراك)\s*[:#\-]?\s*([0-9]{6,})',
  caseSensitive: false,
);
final _invoiceNumberPattern = RegExp(
  r'(?:invoice\s*no|invoice\s*number|bill\s*no|bill\s*number|رقم\s*الفاتورة|فاتورة\s*رقم|فاتورة\s*[:#])\s*[:#\-]?\s*([0-9A-Za-z\-]+)',
  caseSensitive: false,
);

final _namaBarcodeInvoiceRe = RegExp(
  r'EPC[A-Za-z]?\d*[A-Za-z]?-0[^\d]{0,8}(\d{10,})',
  caseSensitive: false,
);

const _totalStrongKeywords = [
  'grand total',
  'amount due',
  'total due',
  'total payable',
  'total payable amount',
  'total outstanding',
  'net amount',
  'balance due',
  'المجموع',
  'الإجمالي',
  'الاجمالي',
  'إجمالي المستحقات',
  'اجمالي المستحقات',
  'المبلغ المستحق',
  'إجمالي المبلغ',
  'الصافي',
  'المستحق',
  'قيمة الفاتورة',
];

const _totalWeakKeywords = [
  'total',
  'net charge',
  'total amount',
  'amount payable',
  'balance',
  'payable',
];

final _totalStrongRe =
    _totalStrongKeywords.map((k) => RegExp(_keywordToPattern(k))).toList();
final _totalWeakRe =
    _totalWeakKeywords.map((k) => RegExp(_keywordToPattern(k))).toList();

const _nonTotalNoiseSubstrings = [
  'previous',
  'opening',
  'advance',
  'deposit',
  'phone',
  'tel',
  'mobile',
  'meter no',
  'meter number',
  'previous reading',
  'current reading',
  'meter reading',
  'reading/date',
  'charge rate',
  'geo code',
  'رصيد سابق',
  'دفعة',
  'مقدم',
  'عربون',
  'قراءة العداد',
  'قراءة عداد',
  'subtotal',
  'intermediate',
  'brought forward',
  'carried',
  'minimum',
  'credit',
  // Oman utility bills: subsidy / intermediate lines (not final payable)
  'net charge to customer',
  'قيمة الاستهلاك للمشترك',
  'consumed energy cost',
  'consumed quantity cost',
  'تكلفة الطاقة المستهلكة',
  'تكلفة الكمية المستهلكة',
  'government subsidy',
  'الدعم الحكومي',
  'total current month dues before',
  'before vat',
  'after vat',
];

const _taxKeywords = [
  'tax',
  'vat',
  'ضريبة',
  'قيمة مضافة',
  'ضريبة القيمة المضافة',
  'vatable',
];

const _consumptionStrictKeywords = [
  'kwh',
  'kw h',
  'kilowatt',
  'consumption',
  'units consumed',
  'consumed quantities',
  'متر مكعب',
  'استهلاك',
  'الكميات المستهلكة',
  'كيلو واط',
  'ك.و',
];

const _consumptionLooseKeywords = ['usage', 'm3', 'm³'];

const _periodKeywords = [
  'billing period',
  'billing',
  'from',
  'to',
  'الفترة',
  'من',
  'إلى',
];

const _feeKeywords = [
  'fee',
  'fees',
  'charge',
  'charges',
  'service',
  'رسوم',
  'خدمة',
  'أتعاب',
  'غرامة',
  'اعادة',
  'إعادة',
  'إعادة توصيل',
  'فصل',
];

const _invoiceNumberKeywords = [
  'invoice no',
  'invoice number',
  'month invoice no',
  'bill no',
  'bill number',
  'vat invoice no',
  'vatinv',
  'رقم الفاتورة',
  'الرقم الضريبي للفاتورة',
];

/// Excludes due date so we capture invoice/issue date (Oman bills often list both).
const _invoiceDateKeywords = [
  'invoice date',
  'bill date',
  'issue date',
  'تاريخ الفاتورة',
  'تاريخ الاصدار',
  'تاريخ الإصدار',
];

const _accountKeywords = [
  'account',
  'acct',
  'subscriber',
  'customer',
  'رقم الحساب',
  'رقم المشترك',
  'رقم الاشتراك',
];

const _electricityKeywords = [
  'electricity',
  'electric',
  'power',
  'kwh',
  'nama electricity',
  'nama supply',
  'majan',
  'كهرباء',
  'الكهرباء',
  'طاقة',
  'شركة كهرباء',
];

const _waterKeywords = [
  'water',
  'water supply',
  'nama water',
  'diam',
  'haya water',
  'haya',
  'public authority for water',
  'm3',
  'm³',
  'مياه',
  'المياه',
  'شركة مياه',
  'صرف',
];

final _taxMatchers =
    _taxKeywords.map((k) => RegExp(_keywordToPattern(k))).toList();
final _consumptionStrictRe =
    _consumptionStrictKeywords
        .map((k) => RegExp(_keywordToPattern(k)))
        .toList();
final _consumptionLooseRe =
    _consumptionLooseKeywords.map((k) => RegExp(_keywordToPattern(k))).toList();
final _periodMatchers =
    _periodKeywords.map((k) => RegExp(_keywordToPattern(k))).toList();
final _feeMatchers =
    _feeKeywords.map((k) => RegExp(_keywordToPattern(k))).toList();
final _accountMatchers =
    _accountKeywords.map((k) => RegExp(_keywordToPattern(k))).toList();
final _electricityMatchers =
    _electricityKeywords.map((k) => RegExp(_keywordToPattern(k))).toList();
final _waterMatchers =
    _waterKeywords.map((k) => RegExp(_keywordToPattern(k))).toList();
final _invoiceNumberMatchers =
    _invoiceNumberKeywords.map((k) => RegExp(_keywordToPattern(k))).toList();
final _invoiceDateMatchers =
    _invoiceDateKeywords.map((k) => RegExp(_keywordToPattern(k))).toList();

const _currentMonthKeywords = [
  'current month',
  'current bill amount',
  'monthly charge',
  'month charges',
  'current charges',
  'charges for month',
  'this month',
  'month amount',
  'رسوم الشهر',
  'مبلغ الشهر',
  'الشهر الحالي',
  'المستحقات الشهرية',
  'مستحقات الشهر',
  'مبلغ الشهر الحالي',
];

const _consumptionDaysLabelKeywords = [
  'number of days',
  'billing days',
  'days of consumption',
  'no of days',
  'no. of days',
  'عدد الأيام',
  'عدد ايام',
  'أيام الاستهلاك',
  'ايام الاستهلاك',
  'مدة الاستهلاك',
];

String _keywordToPattern(String keyword) {
  final escaped = RegExp.escape(keyword.toLowerCase());
  if (RegExp(r'[a-z]').hasMatch(escaped)) {
    return r'\b' + escaped + r'\b';
  }
  return escaped;
}

final _currentMonthRe =
    _currentMonthKeywords.map((k) => RegExp(_keywordToPattern(k))).toList();
final _consumptionDaysLabelRe =
    _consumptionDaysLabelKeywords
        .map((k) => RegExp(_keywordToPattern(k)))
        .toList();
