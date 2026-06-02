import 'dart:io';

import 'package:flutter/services.dart';

import '../models/picked_pdf_file.dart';
import 'file_service.dart';
import 'pdf_file_access.dart';

/// Copies user-selected PDFs into app-accessible storage on macOS sandbox.
class PdfFileStaging {
  Future<PickedPdfFile> stage({
    required String sourcePath,
    required String name,
    int? sizeBytes,
    Uint8List? appleBookmark,
  }) async {
    if (PdfFileAccess.isSupported) {
      try {
        final staged = await PdfFileAccess.stagePdfFile(
          sourcePath: sourcePath,
          name: name,
          bookmark: appleBookmark,
        );
        return PickedPdfFile(
          name: staged.name,
          path: staged.path,
          sizeBytes: staged.sizeBytes,
        );
      } on PlatformException catch (e) {
        throw FilePickException(
          e.message ?? '无法读取文件 $name',
        );
      }
    }

    final source = File(sourcePath);
    return PickedPdfFile(
      name: name,
      path: sourcePath,
      sizeBytes: sizeBytes ?? await source.length(),
    );
  }
}
