import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'page_schedule.dart';
import 'page_selection.dart';
import 'pdf_image_options.dart';
import 'pdf_merger.dart';
import 'pdf_page_ref.dart';
import 'pdf_thumbnail_service.dart';

class PdfToImageProgress {
  const PdfToImageProgress({
    required this.currentPage,
    required this.totalPages,
  });

  final int currentPage;
  final int totalPages;

  double get fraction =>
      totalPages == 0 ? 0 : currentPage.clamp(0, totalPages) / totalPages;
}

class PdfToImageResult {
  const PdfToImageResult({
    required this.outputDirectory,
    required this.savedCount,
    required this.imagePaths,
  });

  final String outputDirectory;
  final int savedCount;
  final List<String> imagePaths;
}

class PdfToImageService {
  Future<PdfToImageResult> exportSchedule({
    required List<PdfPageRef> schedule,
    required List<PdfLoadedSource> sources,
    required PdfThumbnailService thumbnailService,
    required List<int> pageIndices,
    required String outputDirectory,
    required String fileBaseName,
    required PdfImageFormat format,
    required PdfImageScale scale,
    int jpegQuality = 88,
    void Function(PdfToImageProgress progress)? onProgress,
  }) async {
    if (pageIndices.isEmpty) {
      throw PdfProcessException('未选择任何页面');
    }

    final outputDir = Directory(outputDirectory);
    if (!outputDir.existsSync()) {
      await outputDir.create(recursive: true);
    }

    final imagePaths = <String>[];
    for (var exportIndex = 0; exportIndex < pageIndices.length; exportIndex++) {
      final scheduleIndex = pageIndices[exportIndex];
      if (scheduleIndex < 0 || scheduleIndex >= schedule.length) {
        continue;
      }

      onProgress?.call(
        PdfToImageProgress(
          currentPage: exportIndex + 1,
          totalPages: pageIndices.length,
        ),
      );

      final pageRef = schedule[scheduleIndex];
      final rendered = await thumbnailService.renderPageRefForExport(
        pageRef: pageRef,
        sources: sources,
        scale: scale,
      );
      if (rendered == null) {
        throw PdfProcessException('第 ${scheduleIndex + 1} 页渲染失败');
      }

      final bytes = format == PdfImageFormat.png
          ? rendered
          : _encodeJpeg(rendered, jpegQuality);

      final fileName =
          '$fileBaseName-${(exportIndex + 1).toString().padLeft(3, '0')}.${format.extension}';
      final outputPath = p.join(outputDirectory, fileName);
      await File(outputPath).writeAsBytes(bytes, flush: true);
      imagePaths.add(outputPath);
    }

    if (imagePaths.isEmpty) {
      throw PdfProcessException('没有成功导出的图片');
    }

    return PdfToImageResult(
      outputDirectory: outputDirectory,
      savedCount: imagePaths.length,
      imagePaths: imagePaths,
    );
  }

  List<int> resolvePageIndices({
    required int totalPages,
    required PageSelectionMode mode,
    int? rangeStart,
    int? rangeEnd,
    String? specific,
  }) {
    return PageSelection.resolve(
      totalPages: totalPages,
      mode: mode,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      specific: specific,
    );
  }

  Uint8List _encodeJpeg(Uint8List pngBytes, int quality) {
    final decoded = img.decodePng(pngBytes);
    if (decoded == null) {
      throw PdfProcessException('无法编码 JPEG 图片');
    }
    return Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
  }
}
