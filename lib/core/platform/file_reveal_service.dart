import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;

class FileRevealService {
  const FileRevealService();

  Future<bool> revealInFolder(String filePath) async {
    if (kIsWeb) return false;

    if (Directory(filePath).existsSync()) {
      if (Platform.isMacOS) {
        final result = await Process.run('open', [filePath]);
        return result.exitCode == 0;
      }

      if (Platform.isLinux) {
        final result = await Process.run('xdg-open', [filePath]);
        return result.exitCode == 0;
      }

      if (Platform.isWindows) {
        final normalized = filePath.replaceAll('/', '\\');
        final result = await Process.run('explorer', [normalized]);
        return result.exitCode == 0;
      }

      return false;
    }

    if (!File(filePath).existsSync()) return false;

    if (Platform.isMacOS) {
      final result = await Process.run('open', ['-R', filePath]);
      return result.exitCode == 0;
    }

    if (Platform.isWindows) {
      final normalized = filePath.replaceAll('/', '\\');
      final result = await Process.run('explorer', ['/select,', normalized]);
      return result.exitCode == 0;
    }

    if (Platform.isLinux) {
      final result = await Process.run('xdg-open', [p.dirname(filePath)]);
      return result.exitCode == 0;
    }

    return false;
  }
}
