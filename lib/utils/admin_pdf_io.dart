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

/// Open exported file using the OS default app.
Future<void> openExportedFile(String filePath) async {
  try {
    if (filePath.trim().isEmpty) return;
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', filePath], runInShell: true);
      return;
    }
    if (Platform.isMacOS) {
      await Process.run('open', [filePath], runInShell: true);
      return;
    }
    if (Platform.isLinux) {
      await Process.run('xdg-open', [filePath], runInShell: true);
      return;
    }
    if (Platform.isAndroid) {
      await Process.run(
        'am',
        ['start', '-a', 'android.intent.action.VIEW', '-d', 'file://$filePath'],
        runInShell: true,
      );
    }
  } catch (_) {
    // Keep export successful even if auto-open is unavailable.
  }
}
