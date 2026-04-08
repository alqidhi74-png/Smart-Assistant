class ImagePreprocessService {
  /// Placeholder preprocessing step.
  /// Returns original image path when no native/image pipeline is configured.
  Future<String> prepareForOcr(String imagePath) async {
    return imagePath;
  }
}
