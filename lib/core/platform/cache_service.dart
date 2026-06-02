import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Clears on-disk temporary files created during PDF import and editing.
class CacheService {
  static const _stagingDirName = 'pdf_staging';
  static const _insertedImagesDirName = 'inserted_images';

  Future<void> clearCache() async {
    final tempDir = await getTemporaryDirectory();
    await _deleteDirectoryContents(
      Directory(p.join(tempDir.path, _stagingDirName)),
    );
    await _deleteDirectoryContents(
      Directory(p.join(tempDir.path, _insertedImagesDirName)),
    );
  }

  Future<void> _deleteDirectoryContents(Directory directory) async {
    if (!directory.existsSync()) {
      return;
    }

    for (final entity in directory.listSync()) {
      await entity.delete(recursive: true);
    }
  }
}
