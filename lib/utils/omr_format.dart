import '../constants/language.dart';

abstract final class OmrFormat {
  static String amount(double value, AppLocalizations loc) {
    return '${value.toStringAsFixed(3)} ${loc.currencyOmr}';
  }

  static String? amountOrNull(double? value, AppLocalizations loc) {
    if (value == null) return null;
    return amount(value, loc);
  }
}
