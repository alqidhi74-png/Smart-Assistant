import 'package:firebase_database/firebase_database.dart';

import '../core/utils.dart';

/// Removes all user bills under [my_bills] that match a category (electricity / water / internet).
abstract final class AdminBillCleanupService {
  static Future<void> deleteAllBillsForCategoryName(String categoryName) async {
    final kind = BillTypeUtils.billKindForCategoryName(categoryName);
    final targetKey = BillTypeUtils.canonicalTypeKey(categoryName);

    final root = FirebaseDatabase.instance.ref('my_bills');
    final snapshot = await root.get();
    if (!snapshot.exists || snapshot.value == null) return;

    final data = snapshot.value;
    if (data is! Map) return;

    final removals = <Future<void>>[];
    for (final uidEntry in data.entries) {
      final uid = uidEntry.key.toString();
      final userBills = uidEntry.value;
      if (userBills is! Map) continue;
      for (final billEntry in userBills.entries) {
        final billId = billEntry.key.toString();
        final raw = billEntry.value;
        if (raw is! Map) continue;
        final t = raw['type']?.toString() ?? '';
        final bool matches =
            kind != null
                ? BillTypeUtils.billMatchesKind(t, kind)
                : BillTypeUtils.canonicalTypeKey(t).toLowerCase() ==
                    targetKey.toLowerCase();
        if (matches) {
          removals.add(root.child('$uid/$billId').remove());
        }
      }
    }
    if (removals.isEmpty) return;
    await Future.wait(removals);
  }
}
