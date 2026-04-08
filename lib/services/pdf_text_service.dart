import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfTextService {
  String extractText(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const PdfTextException();
    }
    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: bytes);
      return PdfTextExtractor(document).extractText();
    } catch (_) {
      throw const PdfTextException();
    } finally {
      document?.dispose();
    }
  }
}

class PdfTextException implements Exception {
  const PdfTextException();
}
