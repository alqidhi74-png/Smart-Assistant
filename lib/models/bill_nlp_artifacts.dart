/// Output of the on-device NLP pass that runs **after OCR** and **before**
/// structured field extraction ([BillAnalysisService]).
class BillNlpArtifacts {
  /// Raw OCR text as received (trimmed). Shown to the user as bill text.
  final String originalText;

  /// Normalized text used for extraction (digits, punctuation, spacing).
  final String normalizedText;

  /// Heuristic primary script / language mix in the document.
  final BillTextLanguageHint languageHint;

  /// Heuristic signal whether the text looks like a utility bill (water/electricity).
  final UtilityBillDocumentHint utilityHint;

  const BillNlpArtifacts({
    required this.originalText,
    required this.normalizedText,
    required this.languageHint,
    required this.utilityHint,
  });

  static BillNlpArtifacts empty() => const BillNlpArtifacts(
        originalText: '',
        normalizedText: '',
        languageHint: BillTextLanguageHint.unknown,
        utilityHint: UtilityBillDocumentHint.none,
      );

  bool get isEmpty => originalText.isEmpty;
}

/// Rough document language profile (character-level heuristic, not a full classifier).
enum BillTextLanguageHint {
  arabicPrimary,
  englishPrimary,
  mixed,
  unknown,
}

/// Lightweight document-level hint from keyword presence (not a replacement for field extraction).
enum UtilityBillDocumentHint {
  electricityDominant,
  waterDominant,
  bothUtilities,
  ambiguous,
  none,
}
