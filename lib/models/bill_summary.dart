class BillSummary {
  final String id;
  final String type;
  final String dateText;
  final double? consumptionValue;
  final String? consumptionUnit;
  final double? totalAmount;
  final String? accountNumber;
  final String? invoiceNumber;
  final String? billingMonthText;
  final String? billingMonthKey;
  final double? currentMonthAmount;
  final int? consumptionDays;
  final int createdAt;

  const BillSummary({
    required this.id,
    required this.type,
    required this.dateText,
    this.consumptionValue,
    this.consumptionUnit,
    this.totalAmount,
    this.accountNumber,
    this.invoiceNumber,
    this.billingMonthText,
    this.billingMonthKey,
    this.currentMonthAmount,
    this.consumptionDays,
    required this.createdAt,
  });
}
