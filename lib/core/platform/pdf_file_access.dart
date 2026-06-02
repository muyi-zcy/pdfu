import 'dart:io';

import 'package:flutter/services.dart';

class StagedPdfFile {
  const StagedPdfFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    this.sourceDirectory,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final String? sourceDirectory;

  factory StagedPdfFile.fromMap(Map<Object?, Object?> map) {
    return StagedPdfFile(
      path: map['path']! as String,
      name: map['name']! as String,
      sizeBytes: map['size']! as int,
      sourceDirectory: map['sourceDirectory'] as String?,
    );
  }
}

class PdfFileAccess {
  PdfFileAccess._();

  static const _channel = MethodChannel('pdf_edit/file_access');

  static bool get isSupported => Platform.isMacOS;

  static Future<StagedPdfFile?> pickPdfFile({String? initialDirectory}) async {
    if (!isSupported) return null;

    final result = await _channel.invokeMethod<Object?>(
      'pickPdfFile',
      {
        if (initialDirectory != null && initialDirectory.isNotEmpty)
          'initialDirectory': initialDirectory,
      },
    );

    if (result == null) return null;
    return StagedPdfFile.fromMap(result as Map<Object?, Object?>);
  }

  static Future<StagedPdfFile> stagePdfFile({
    required String sourcePath,
    required String name,
    Uint8List? bookmark,
  }) async {
    if (!isSupported) {
      throw UnsupportedError('Native PDF staging is only available on macOS');
    }

    final result = await _channel.invokeMethod<Object?>(
      'stagePdfFile',
      {
        'sourcePath': sourcePath,
        'name': name,
        'bookmark': ?bookmark,
      },
    );

    return StagedPdfFile.fromMap(result as Map<Object?, Object?>);
  }
}
