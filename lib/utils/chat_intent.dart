import 'text_normalize.dart';

enum ChatIntentKind { consumption, billRelated, helpSupport, unknown }

abstract final class ChatIntent {
  static const List<String> _helpHints = [
    'help',
    'support',
    'contact',
    'customer service',
    'مساعدة',
    'دعم',
    'تواصل',
    'اتصل',
    'هاتف',
    'بريد',
    'email',
    'phone',
    'problem',
    'issue',
    'error',
    'خطأ',
    'مشكلة',
    'لا يعمل',
    'not working',
  ];

  static const List<String> _consumptionHints = [
    'consumption',
    'usage',
    'units consumed',
    'kilowatt',
    'kwh',
    'kw ',
    ' kw',
    'كيلو',
    'ك.و',
    'استهلاك',
    'استخدام',
    'واط',
    'm3',
    'm³',
    'cubic',
    'متر مكعب',
    'water usage',
  ];

  static const List<String> _billHints = [
    'bill',
    'bills',
    'invoice',
    'فاتورة',
    'فواتير',
    'upload',
    'رفع',
    'scan',
    'مسح',
    'camera',
    'كاميرا',
    'gallery',
    'معرض',
    'pdf',
    'تحليل',
    'analyze',
    'analysis',
    'ocr',
    'nama',
    'electricity bill',
    'water bill',
    'فاتورة الكهرباء',
    'فاتورة المياه',
    'my bills',
    'فواتيري',
    'total',
    'amount due',
    'المبلغ',
    'المستحق',
  ];

  static ChatIntentKind classify(String raw) {
    final q = TextNormalize.forChatMatching(raw);
    if (q.isEmpty) return ChatIntentKind.unknown;

    if (_anyContains(q, _helpHints)) return ChatIntentKind.helpSupport;
    if (_anyContains(q, _billHints)) return ChatIntentKind.billRelated;
    if (_anyContains(q, _consumptionHints)) return ChatIntentKind.consumption;
    return ChatIntentKind.unknown;
  }

  static bool _anyContains(String haystack, List<String> needles) {
    for (final n in needles) {
      if (haystack.contains(n)) return true;
    }
    return false;
  }
}
