import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrCandidateScore {
  final String path;
  final int score;
  final String text;

  const OcrCandidateScore({
    required this.path,
    required this.score,
    required this.text,
  });
}

class OcrBestTextResult {
  final String text;
  final String bestPath;
  final List<OcrCandidateScore> candidates;

  const OcrBestTextResult({
    required this.text,
    required this.bestPath,
    required this.candidates,
  });
}

/// On-device OCR using ML Kit [TextRecognitionScript.latin].
/// Arabic script on photos is weak; prefer PDF text extraction when possible.
class OcrService {
  final TextRecognizer _recognizer;

  OcrService({TextRecognitionScript script = TextRecognitionScript.latin})
    : _recognizer = TextRecognizer(script: script);

  Future<String> extractTextFromImagePath(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _recognizer.processImage(inputImage);
    final structured = _buildStructuredText(recognizedText);
    final raw = recognizedText.text.trim();
    if (structured.isEmpty) return raw;
    if (raw.length > structured.length + 80) {
      return raw;
    }
    return structured;
  }

  /// Runs OCR on multiple processed variants and returns the strongest text
  /// candidate using a lightweight invoice-aware heuristic.
  Future<String> extractBestTextFromImagePaths(List<String> imagePaths) async {
    final result = await extractBestTextResultFromImagePaths(imagePaths);
    return result.text;
  }

  Future<OcrBestTextResult> extractBestTextResultFromImagePaths(
    List<String> imagePaths,
  ) async {
    if (imagePaths.isEmpty) {
      return const OcrBestTextResult(text: '', bestPath: '', candidates: []);
    }
    var best = '';
    var bestPath = '';
    var bestScore = -1;
    final candidates = <OcrCandidateScore>[];

    for (final path in imagePaths) {
      final text = await extractTextFromImagePath(path);
      final score = scoreCandidateText(text);
      candidates.add(OcrCandidateScore(path: path, score: score, text: text));
      if (score > bestScore) {
        bestScore = score;
        best = text;
        bestPath = path;
      }
    }

    return OcrBestTextResult(
      text: best,
      bestPath: bestPath,
      candidates: candidates,
    );
  }

  static int scoreCandidateText(String text) {
    final t = text.trim();
    if (t.isEmpty) return 0;
    var score = t.length.clamp(0, 5000);
    final lower = t.toLowerCase();

    if (RegExp(r'(invoice|فاتورة|bill)').hasMatch(lower)) score += 120;
    if (RegExp(r'(amount|total|المبلغ|المستحق)').hasMatch(lower)) score += 120;
    if (RegExp(r'(electricity|water|كهرباء|مياه)').hasMatch(lower)) score += 100;
    if (RegExp(r'(kwh|m3|m³|kw)').hasMatch(lower)) score += 80;
    if (RegExp(r'(\d{2,}[./-]\d{1,2}[./-]\d{2,4})').hasMatch(lower)) score += 60;
    if (RegExp(r'(\d{4,})').hasMatch(lower)) score += 40;

    // Penalize obvious OCR gibberish where punctuation dominates.
    final punctuation = RegExp(r'[^\w\s\u0600-\u06FF]').allMatches(t).length;
    final lettersDigits =
        RegExp(r'[\w\u0600-\u06FF]').allMatches(t).length.clamp(1, 100000);
    if (punctuation > lettersDigits * 0.8) score -= 150;

    return score;
  }

  static String _buildStructuredText(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) {
      return recognizedText.text.trim();
    }
    final blocks = List<TextBlock>.from(recognizedText.blocks)..sort((a, b) {
      final dy = a.boundingBox.top.compareTo(b.boundingBox.top);
      if (dy != 0) return dy;
      return a.boundingBox.left.compareTo(b.boundingBox.left);
    });

    final buffer = StringBuffer();
    for (final block in blocks) {
      final lines = List<TextLine>.from(block.lines)..sort((a, b) {
        final dy = a.boundingBox.top.compareTo(b.boundingBox.top);
        if (dy != 0) return dy;
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      });
      for (final line in lines) {
        final t = line.text.trim();
        if (t.isNotEmpty) buffer.writeln(t);
      }
    }
    return buffer.toString().trim();
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }
}
