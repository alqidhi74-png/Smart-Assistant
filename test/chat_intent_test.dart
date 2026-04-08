import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant/utils/chat_intent.dart';
import 'package:smart_assistant/utils/text_normalize.dart';

void main() {
  group('TextNormalize', () {
    test('forBillAnalysis strips invisible and maps digits', () {
      expect(TextNormalize.forBillAnalysis('\u200c١٢٫٣\u200d'), '12.3');
    });

    test('forChatMatching lowercases and collapses spaces', () {
      expect(TextNormalize.forChatMatching('  Bill  HELP  '), 'bill help');
    });

    test('forDateParsing maps digits without lowercasing', () {
      expect(TextNormalize.forDateParsing('٢٠٢٥-٠٦-١٥'), '2025-06-15');
    });
  });

  group('ChatIntent', () {
    test('classifies bill before consumption when both keywords appear', () {
      expect(ChatIntent.classify('فاتورة المياه'), ChatIntentKind.billRelated);
    });

    test('classifies consumption', () {
      expect(
        ChatIntent.classify('What is normal consumption?'),
        ChatIntentKind.consumption,
      );
      expect(
        ChatIntent.classify('كم استهلاك الكهرباء'),
        ChatIntentKind.consumption,
      );
    });

    test('classifies help', () {
      expect(
        ChatIntent.classify('contact support please'),
        ChatIntentKind.helpSupport,
      );
      expect(
        ChatIntent.classify('عندي مشكلة في التطبيق'),
        ChatIntentKind.helpSupport,
      );
    });

    test('classifies bill-related', () {
      expect(
        ChatIntent.classify('how to upload pdf bill'),
        ChatIntentKind.billRelated,
      );
    });

    test('unknown when no match', () {
      expect(ChatIntent.classify('hello world xyz'), ChatIntentKind.unknown);
    });
  });
}
