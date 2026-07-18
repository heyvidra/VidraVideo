import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import 'log.dart';

/// Opens [filePath] with the OS default application (e.g. plays an .mp4 in
/// QuickTime). Returns false if the file is missing or couldn't be opened.
Future<bool> openFile(String filePath) async {
  if (!File(filePath).existsSync()) return false;
  try {
    return await launchUrl(Uri.file(filePath));
  } catch (e) {
    logD('FileReveal', 'openFile failed: $e');
    return false;
  }
}

/// Reveals [filePath] in the platform file manager (selecting the file where
/// supported). Returns false if the file is missing or the reveal failed.
Future<bool> revealInFileManager(String filePath) async {
  if (!File(filePath).existsSync()) return false;
  try {
    if (Platform.isMacOS) {
      await Process.run('open', ['-R', filePath]);
    } else if (Platform.isWindows) {
      await Process.run('explorer', ['/select,', filePath]);
    } else {
      await Process.run('xdg-open', [p.dirname(filePath)]);
    }
    return true;
  } catch (e) {
    logD('FileReveal', 'reveal failed: $e');
    return false;
  }
}
