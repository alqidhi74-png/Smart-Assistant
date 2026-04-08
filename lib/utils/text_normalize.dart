abstract final class TextNormalize {
  static const Map<String, String> arabicDigitMap = {
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
  };

  static final RegExp _invisibleChars = RegExp(r'[\u200b\u200c\u200d\ufeff]');

  static String stripInvisible(String input) {
    return input.replaceAll(_invisibleChars, '');
  }

  static String mapArabicDigits(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(arabicDigitMap[char] ?? char);
    }
    return buffer.toString();
  }

  static String unifyPunctuation(String input) {
    return input
        .replaceAll('٫', '.')
        .replaceAll('٬', ',')
        .replaceAll('،', ',')
        .replaceAll('−', '-')
        .replaceAll('–', '-');
  }

  static String forBillAnalysis(String input) {
    var s = stripInvisible(input);
    s = mapArabicDigits(s);
    return unifyPunctuation(s);
  }

  static String forChatMatching(String input) {
    var s = stripInvisible(input);
    s = mapArabicDigits(s);
    s = unifyPunctuation(s);
    return s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String forDateParsing(String input) {
    var s = stripInvisible(input);
    s = mapArabicDigits(s);
    s = unifyPunctuation(s);
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
