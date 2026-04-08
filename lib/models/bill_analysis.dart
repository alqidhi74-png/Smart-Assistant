class FeeItem {
  final String label;
  final double? amount;

  const FeeItem({required this.label, this.amount});
}

class BillAnalysisResult {
  final String rawText;
  final String? billType;
  final String? accountNumber;
  final String? invoiceNumber;
  final String? invoiceDate;
  final double? totalAmount;
  final double? taxAmount;
  final double? consumptionValue;
  final String? consumptionUnit;
  final String? periodText;
  final List<FeeItem> feeItems;
  final String? billingMonthText;
  final String? billingMonthKey;
  final double? currentMonthAmount;
  final int? consumptionDays;

  const BillAnalysisResult({
    required this.rawText,
    this.billType,
    this.accountNumber,
    this.invoiceNumber,
    this.invoiceDate,
    this.totalAmount,
    this.taxAmount,
    this.consumptionValue,
    this.consumptionUnit,
    this.periodText,
    this.feeItems = const [],
    this.billingMonthText,
    this.billingMonthKey,
    this.currentMonthAmount,
    this.consumptionDays,
  });
}
