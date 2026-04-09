import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImagePreprocessService {
  static const int _maxSide = 2048;
  static const int _jpegQuality = 85;

  /// Resize large photos and re-encode as JPEG to cut memory and upload/OCR time.
  Future<String> prepareForOcr(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) return imagePath;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return imagePath;
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return imagePath;
    var work = decoded;
    if (work.width > _maxSide || work.height > _maxSide) {
      if (work.width >= work.height) {
        work = img.copyResize(work, width: _maxSide);
      } else {
        work = img.copyResize(work, height: _maxSide);
      }
    }
    final jpg = img.encodeJpg(work, quality: _jpegQuality);
    final dir = await getTemporaryDirectory();
    final out = File(
      '${dir.path}/ocr_prep_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await out.writeAsBytes(jpg);
    return out.path;
  }

  /// Generate multiple enhanced image variants to improve OCR recall on
  /// difficult photos (low contrast, shadows, mild blur).
  Future<List<String>> prepareVariantsForOcr(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) return [imagePath];
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return [imagePath];
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return [imagePath];

    var base = decoded;
    if (base.width > _maxSide || base.height > _maxSide) {
      if (base.width >= base.height) {
        base = img.copyResize(base, width: _maxSide);
      } else {
        base = img.copyResize(base, height: _maxSide);
      }
    }

    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final outPaths = <String>[];

    Future<void> writeVariant(String suffix, img.Image variant) async {
      final path = '${dir.path}/ocr_prep_${ts}_$suffix.jpg';
      final encoded = img.encodeJpg(variant, quality: _jpegQuality);
      await File(path).writeAsBytes(encoded);
      outPaths.add(path);
    }

    await writeVariant('base', base);

    final gray = img.grayscale(base);
    await writeVariant('gray', gray);

    final contrast = img.adjustColor(base, contrast: 1.25);
    await writeVariant('contrast', contrast);

    final binarized = img.luminanceThreshold(gray, threshold: 145);
    await writeVariant('binary', binarized);

    return outPaths;
  }
}
