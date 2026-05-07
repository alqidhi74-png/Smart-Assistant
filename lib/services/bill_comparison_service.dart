import '../models/bill_summary.dart';

class ComparisonResult {
  final double percentageChange;
  final bool isIncrease;
  final bool hasPrevious;
  final String type;

  ComparisonResult({
    required this.percentageChange,
    required this.isIncrease,
    required this.hasPrevious,
    required this.type,
  });
}

class BillComparisonService {
  static ComparisonResult compareWithPreviousMonth(
    BillSummary newBill,
    List<BillSummary> allBills,
  ) {
    final String? currentKey = newBill.billingMonthKey;
    if (currentKey == null || !currentKey.contains('-')) {
      return ComparisonResult(
        percentageChange: 0,
        isIncrease: false,
        hasPrevious: false,
        type: newBill.type,
      );
    }

    final parts = currentKey.split('-');
    int year = int.parse(parts[0]);
    int month = int.parse(parts[1]);

    // Calculate previous month key
    int prevYear = year;
    int prevMonth = month - 1;
    if (prevMonth == 0) {
      prevMonth = 12;
      prevYear--;
    }
    final String prevKey =
        '$prevYear-${prevMonth.toString().padLeft(2, '0')}';

    // Find previous bill of the same type
    final previousBill = allBills.firstWhere(
      (b) =>
          b.type.toLowerCase() == newBill.type.toLowerCase() &&
          b.billingMonthKey == prevKey,
      orElse: () => const BillSummary(
        id: '',
        type: '',
        dateText: '',
        createdAt: 0,
      ),
    );

    if (previousBill.id.isEmpty) {
      return ComparisonResult(
        percentageChange: 0,
        isIncrease: false,
        hasPrevious: false,
        type: newBill.type,
      );
    }

    // Compare consumption first, then total amount
    double? newValue = newBill.consumptionValue ?? newBill.totalAmount;
    double? prevValue = previousBill.consumptionValue ?? previousBill.totalAmount;

    if (newValue == null || prevValue == null || prevValue == 0) {
      return ComparisonResult(
        percentageChange: 0,
        isIncrease: false,
        hasPrevious: false,
        type: newBill.type,
      );
    }

    final double change = ((newValue - prevValue) / prevValue) * 100;

    return ComparisonResult(
      percentageChange: change.abs(),
      isIncrease: change > 0,
      hasPrevious: true,
      type: newBill.type,
    );
  }
}
