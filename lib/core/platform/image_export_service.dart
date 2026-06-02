import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;

class ImageExportService {
  Future<String?> pickOutputDirectory() async {
    if (kIsWeb) {
      return null;
    }

    return FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择图片保存文件夹',
    );
  }

  Future<String> createOutputFolder({
    required String parentDirectory,
    required String folderName,
  }) async {
    final sanitized = folderName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    final baseName = sanitized.isEmpty ? 'pdf-images' : sanitized;
    var candidate = p.join(parentDirectory, baseName);

    if (!Directory(candidate).existsSync()) {
      await Directory(candidate).create(recursive: true);
      return candidate;
    }

    for (var index = 2; index < 100; index++) {
      candidate = p.join(parentDirectory, '$baseName-$index');
      if (!Directory(candidate).existsSync()) {
        await Directory(candidate).create(recursive: true);
        return candidate;
      }
    }

    throw StateError('无法创建输出文件夹');
  }
}
