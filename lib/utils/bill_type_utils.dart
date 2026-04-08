abstract final class BillTypeUtils {
  static bool isElectricity(String type) {
    final t = type.toLowerCase();
    return t.contains('electric') || type.contains('كهرب');
  }

  static bool isWater(String type) {
    final t = type.toLowerCase();
    return t.contains('water') || type.contains('مياه');
  }

  static bool isInternet(String type) {
    final t = type.toLowerCase();
    return t.contains('internet') ||
        t.contains('wifi') ||
        t.contains('broadband') ||
        type.contains('انترنت') ||
        type.contains('إنترنت');
  }

  /// Bills shown in the app (water + electricity only).
  static bool isUtilityWaterOrElectricity(String type) {
    return isElectricity(type) || isWater(type);
  }

  /// Which stored bills to remove when an admin deletes a category with this [name].
  /// Returns null if the name does not map to a known bill family (no mass delete).
  static String? billKindForCategoryName(String categoryName) {
    final lower = categoryName.toLowerCase();
    if (lower.contains('electric') || categoryName.contains('كهرب')) {
      return 'electricity';
    }
    if (lower.contains('water') || categoryName.contains('مياه')) {
      return 'water';
    }
    if (lower.contains('internet') ||
        lower.contains('wifi') ||
        lower.contains('net') ||
        categoryName.contains('انترنت') ||
        categoryName.contains('إنترنت')) {
      return 'internet';
    }
    return null;
  }

  static bool billMatchesKind(String billType, String kind) {
    switch (kind) {
      case 'electricity':
        return isElectricity(billType);
      case 'water':
        return isWater(billType);
      case 'internet':
        return isInternet(billType);
      default:
        return false;
    }
  }

  /// Same grouping key used in admin charts and [canonicalTypeKey] for custom types.
  static String canonicalTypeKey(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('electric') || input.contains('كهرب')) {
      return 'Electricity';
    }
    if (lower.contains('water') || input.contains('مياه')) {
      return 'Water';
    }
    if (lower.contains('internet') ||
        lower.contains('wifi') ||
        lower.contains('net') ||
        input.contains('انترنت') ||
        input.contains('إنترنت')) {
      return 'Internet';
    }
    return input.trim();
  }
}
