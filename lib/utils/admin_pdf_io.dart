//تحديد مكان حفظ الملفات (Downloads / Storage)
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Shared download folder for admin PDF exports (users, categories, …).
Future<Directory> getAdminDownloadDirectory() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    final downloads = await getDownloadsDirectory();
    if (downloads != null) {
      return downloads;
    }
  }
  if (Platform.isAndroid) {
    final downloads = Directory('/storage/emulated/0/Download');
    if (await downloads.exists()) {
      return downloads;
    }
    final external = await getExternalStorageDirectory();
    if (external != null) {
      return external;
    }
  }
  return getApplicationDocumentsDirectory();
}

/// Safe single-segment file name for exports (Latin slug).
String safeExportFileName(String input) {
  final trimmed = input.trim().toLowerCase();
  if (trimmed.isEmpty) {
    return 'export';
  }
  return trimmed.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
