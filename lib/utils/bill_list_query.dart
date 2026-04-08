import '../models/bill_summary.dart';
import 'bill_type_utils.dart';
import 'text_normalize.dart';

enum BillFilterMode { all, electricity, water }

enum BillSortOrder { newestFirst, oldestFirst }

abstract final class BillListQuery {
  /// Drops non–water/electricity rows (e.g. legacy types) so the app stays consistent.
  static List<BillSummary> utilityBillsOnly(List<BillSummary> bills) {
    return bills
        .where((b) => BillTypeUtils.isUtilityWaterOrElectricity(b.type))
        .toList();
  }

  static List<BillSummary> applyFilter(
    List<BillSummary> bills,
    BillFilterMode mode,
  ) {
    final base = utilityBillsOnly(bills);
    switch (mode) {
      case BillFilterMode.electricity:
        return base
            .where((bill) => BillTypeUtils.isElectricity(bill.type))
            .toList();
      case BillFilterMode.water:
        return base.where((bill) => BillTypeUtils.isWater(bill.type)).toList();
      case BillFilterMode.all:
        return base;
    }
  }

  static List<BillSummary> applySearch(List<BillSummary> bills, String query) {
    final q = TextNormalize.forChatMatching(query);
    if (q.isEmpty) return bills;
    return bills.where((bill) {
      final type = TextNormalize.forChatMatching(bill.type);
      final date = TextNormalize.forChatMatching(bill.dateText);
      final consumption = TextNormalize.forChatMatching(
        bill.consumptionValue?.toString() ?? '',
      );
      final account = TextNormalize.forChatMatching(bill.accountNumber ?? '');
      final invoice = TextNormalize.forChatMatching(bill.invoiceNumber ?? '');
      return type.contains(q) ||
          date.contains(q) ||
          consumption.contains(q) ||
          account.contains(q) ||
          invoice.contains(q);
    }).toList();
  }

  static List<BillSummary> applySort(
    List<BillSummary> bills,
    BillSortOrder order,
  ) {
    final list = List<BillSummary>.from(bills);
    switch (order) {
      case BillSortOrder.newestFirst:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case BillSortOrder.oldestFirst:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }
    return list;
  }
}
