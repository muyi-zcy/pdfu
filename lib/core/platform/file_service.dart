import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/picked_pdf_file.dart';
import 'pdf_file_access.dart';
import 'pdf_file_staging.dart';

class FileService {
  FileService({PdfFileStaging? staging})
      : _staging = staging ?? PdfFileStaging();

  static String? _lastImportDirectory;

  final PdfFileStaging _staging;

  static String? _validImportDirectory(String? directory) {
    if (directory == null || directory.isEmpty) return null;
    if (!Directory(directory).existsSync()) return null;
    return directory;
  }

  static void rememberImportDirectory(String filePath) {
    final directory = _validImportDirectory(p.dirname(filePath));
    if (directory != null) {
      _lastImportDirectory = directory;
    }
  }

  PickedPdfFile? pickedFileFromPath(String path) {
    if (!path.toLowerCase().endsWith('.pdf')) return null;

    final file = File(path);
    if (!file.existsSync()) return null;

    return PickedPdfFile(
      name: p.basename(path),
      path: path,
      sizeBytes: file.lengthSync(),
    );
  }

  List<PickedPdfFile> pickedFilesFromPaths(Iterable<String> paths) {
    final files = <PickedPdfFile>[];
    for (final path in paths) {
      final file = pickedFileFromPath(path);
      if (file != null) {
        files.add(file);
      }
    }
    return files;
  }

  Future<List<PickedPdfFile>> stageDroppedFiles(List<DropItem> items) async {
    final files = <PickedPdfFile>[];

    for (final item in items) {
      final path = item.path;
      if (path.isEmpty || !path.toLowerCase().endsWith('.pdf')) {
        continue;
      }

      rememberImportDirectory(path);

      files.add(
        await _staging.stage(
          sourcePath: path,
          name: item.name.isNotEmpty ? item.name : p.basename(path),
          appleBookmark: item.extraAppleBookmark,
        ),
      );
    }

    return files;
  }

  Future<PickedPdfFile?> pickSinglePdfFile() async {
    if (PdfFileAccess.isSupported) {
      return _pickSinglePdfFileMacOS();
    }

    return _pickSinglePdfFileDefault();
  }

  Future<PickedPdfFile?> _pickSinglePdfFileMacOS() async {
    try {
      final staged = await PdfFileAccess.pickPdfFile(
        initialDirectory: _validImportDirectory(_lastImportDirectory),
      );
      if (staged == null) return null;

      if (staged.sourceDirectory != null) {
        _lastImportDirectory =
            _validImportDirectory(staged.sourceDirectory) ?? _lastImportDirectory;
      }

      return PickedPdfFile(
        name: staged.name,
        path: staged.path,
        sizeBytes: staged.sizeBytes,
      );
    } on PlatformException catch (e) {
      throw FilePickException(e.message ?? '无法打开所选 PDF 文件');
    }
  }

  Future<PickedPdfFile?> _pickSinglePdfFileDefault() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
      withData: false,
      withReadStream: false,
      initialDirectory: _validImportDirectory(_lastImportDirectory),
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;
    if (file.path == null || file.path!.isEmpty) {
      return null;
    }

    rememberImportDirectory(file.path!);

    return _staging.stage(
      sourcePath: file.path!,
      name: file.name,
      sizeBytes: file.size,
    );
  }

  Future<List<String>> pickAndStageImageFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: false,
      withReadStream: false,
    );

    if (result == null || result.files.isEmpty) {
      return const [];
    }

    final stagedPaths = <String>[];
    for (final file in result.files) {
      final path = file.path;
      if (path == null || path.isEmpty) continue;

      rememberImportDirectory(path);
      stagedPaths.add(
        await _stageImageFile(
          sourcePath: path,
          name: file.name.isNotEmpty ? file.name : p.basename(path),
        ),
      );
    }

    return stagedPaths;
  }

  Future<String> _stageImageFile({
    required String sourcePath,
    required String name,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final imagesDir = Directory(p.join(tempDir.path, 'inserted_images'));
    if (!imagesDir.existsSync()) {
      await imagesDir.create(recursive: true);
    }

    final extension = p.extension(name).isEmpty
        ? p.extension(sourcePath)
        : p.extension(name);
    final safeName =
        p.basenameWithoutExtension(name).replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final destPath = p.join(
      imagesDir.path,
      '${DateTime.now().microsecondsSinceEpoch}_$safeName$extension',
    );
    await File(sourcePath).copy(destPath);
    return destPath;
  }
}

class FilePickException implements Exception {
  FilePickException(this.message);

  final String message;

  @override
  String toString() => message;
}
