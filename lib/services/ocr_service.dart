import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

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
