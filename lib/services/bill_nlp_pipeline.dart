import '../models/bill_analysis.dart';
import '../models/bill_nlp_artifacts.dart';
import 'bill_analysis_service.dart';
import '../utils/text_normalize.dart';

/// Natural-language preprocessing and light document understanding for bill text
/// produced by OCR (or PDF text extraction). This runs **before**
/// [BillAnalysisService] structured parsing.
abstract final class BillNlpPipeline {
  static final RegExp _arabicLetters = RegExp(r'[\u0600-\u06FF]');
  static final RegExp _latinLetters = RegExp(r'[A-Za-z]');

  static const List<String> _electricityLexicon = [
    'electricity',
    'electric',
    'kwh',
    'kw ',
    ' kw',
    'kilowatt',
    'nama',
    'meter',
    'كهرباء',
    'استهلاك كهرباء',
    'ك.و',
    'كيلوواط',
  ];

  static const List<String> _waterLexicon = [
    'water',
    'm3',
    'm³',
    'cubic',
    'gallon',
    'litre',
    'liter',
    'مياه',
    'ماء',
    'متر مكعب',
    'استهلاك مياه',
  ];

  /// Full path: NLP prepare → structured analysis. Preserves original OCR in [BillAnalysisResult.rawText].
  static BillAnalysisResult analyzeBill(String rawOcrText) {
    final prep = prepare(rawOcrText);
    return BillAnalysisService.analyze(
      prep.normalizedText,
      displayRawText: prep.originalText,
    );
  }

  /// Normalize bill text and attach lightweight NLP metadata for downstream use or logging.
  static BillNlpArtifacts prepare(String rawOcrText) {
    final original = rawOcrText.trim();
    if (original.isEmpty) {
      return BillNlpArtifacts.empty();
    }

    var normalized = TextNormalize.forBillAnalysis(original);
    normalized = _collapseRedundantBlankLines(normalized);

    final lower = normalized.toLowerCase();
    final lang = _detectLanguage(normalized);
    final utility = _utilityHint(lower);

    return BillNlpArtifacts(
      originalText: original,
      normalizedText: normalized,
      languageHint: lang,
      utilityHint: utility,
    );
  }

  static String _collapseRedundantBlankLines(String input) {
    return input.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  static BillTextLanguageHint _detectLanguage(String text) {
    final ar = _arabicLetters.allMatches(text).length;
    final en = _latinLetters.allMatches(text).length;
    if (ar == 0 && en == 0) {
      return BillTextLanguageHint.unknown;
    }
    if (ar >= en * 1.5) {
      return BillTextLanguageHint.arabicPrimary;
    }
    if (en >= ar * 1.5) {
      return BillTextLanguageHint.englishPrimary;
    }
    return BillTextLanguageHint.mixed;
  }

  static UtilityBillDocumentHint _utilityHint(String lower) {
    var eScore = 0;
    for (final w in _electricityLexicon) {
      if (lower.contains(w)) eScore++;
    }
    var wScore = 0;
    for (final w in _waterLexicon) {
      if (lower.contains(w)) wScore++;
    }

    if (eScore == 0 && wScore == 0) {
      return UtilityBillDocumentHint.none;
    }
    if (eScore >= 2 && wScore >= 2) {
      return UtilityBillDocumentHint.bothUtilities;
    }
    if (eScore > wScore + 1) {
      return UtilityBillDocumentHint.electricityDominant;
    }
    if (wScore > eScore + 1) {
      return UtilityBillDocumentHint.waterDominant;
    }
    if (eScore > 0 && wScore > 0) {
      return UtilityBillDocumentHint.bothUtilities;
    }
    if (eScore > 0) {
      return UtilityBillDocumentHint.electricityDominant;
    }
    if (wScore > 0) {
      return UtilityBillDocumentHint.waterDominant;
    }
    return UtilityBillDocumentHint.ambiguous;
  }
}
