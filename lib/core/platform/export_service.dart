import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'export_io.dart' if (dart.library.html) 'export_io_stub.dart' as export_io;

class ExportService {
  Future<String?> savePdf({
    required Uint8List bytes,
    required String suggestedName,
  }) async {
    if (kIsWeb) {
      return FilePicker.platform.saveFile(
        dialogTitle: '保存 PDF',
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );
    }

    final path = await FilePicker.platform.saveFile(
      dialogTitle: '保存 PDF',
      fileName: suggestedName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (path == null) {
      return null;
    }

    final outputPath = path.toLowerCase().endsWith('.pdf') ? path : '$path.pdf';
    await export_io.writePdfBytes(outputPath, bytes);
    return outputPath;
  }
}

@Deprecated('Use SettingsNotifier.buildExportName or formatExportFileName')
String buildExportFileName({
  required String baseName,
  required String suffix,
}) {
  final sanitized =
      baseName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
  return '$sanitized-$suffix.pdf';
}
