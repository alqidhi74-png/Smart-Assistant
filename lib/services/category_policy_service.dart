import 'package:firebase_database/firebase_database.dart';

import '../core/utils.dart';

/// Which utility kinds the admin currently exposes under [categories] (`electricity` / `water`).
abstract final class CategoryPolicyService {
  /// Returns `null` if the categories node could not be read (network / permission).
  /// Empty set means no electricity/water categories exist.
  static Future<Set<String>?> fetchAllowedUtilityKinds() async {
    try {
      final snap = await FirebaseDatabase.instance.ref('categories').get();
      if (!snap.exists || snap.value == null) return {};
      final data = snap.value;
      if (data is! Map) return {};
      final allowed = <String>{};
      for (final v in data.values) {
        if (v is Map) {
          final name = v['name']?.toString() ?? '';
          final k = BillTypeUtils.billKindForCategoryName(name);
          if (k == 'electricity') {
            allowed.add('electricity');
          } else if (k == 'water') {
            allowed.add('water');
          }
        }
      }
      return allowed;
    } catch (_) {
      return null;
    }
  }

  /// [billType] from analysis: `Electricity` or `Water`.
  static bool isBillTypeAllowedByCategories(
    String? billType,
    Set<String> allowedKinds,
  ) {
    if (billType == 'Electricity') {
      return allowedKinds.contains('electricity');
    }
    if (billType == 'Water') {
      return allowedKinds.contains('water');
    }
    return false;
  }
}
