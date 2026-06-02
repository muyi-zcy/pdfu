import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/picked_pdf_file.dart';
import 'page_image_utils.dart';
import 'pdf_page_ref.dart';
import 'page_schedule.dart';
import 'source_utils.dart';

export 'page_image_utils.dart'
    show pageAspectRatio, pageIsLandscape, pageOutputSize, thumbnailFrameSize;

class PdfLoader {
  Future<List<PdfLoadedSource>> loadSources(List<PickedPdfFile> files) async {
    final sources = <PdfLoadedSource>[];
    final labels = sourceLabelsForCount(files.length);

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final bytes = await File(file.path).readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      document.dispose();

      if (pageCount == 0) {
        throw PdfProcessException('文件 ${file.name} 没有可用页面');
      }

      sources.add(
        PdfLoadedSource(
          id: labels[i],
          file: file,
          pageCount: pageCount,
        ),
      );
    }

    return sources;
  }
}

class PdfMerger {
  Future<Uint8List> render({
    required List<PdfLoadedSource> sources,
    required List<PdfPageRef> schedule,
  }) async {
    if (schedule.isEmpty) {
      throw PdfProcessException('页序为空，无法导出');
    }

    final documents = <String, PdfDocument>{};
    try {
      for (final source in sources) {
        final bytes = await File(source.file.path).readAsBytes();
        documents[source.id] = PdfDocument(inputBytes: bytes);
      }

      final output = PdfDocument()..pageSettings.setMargins(0);

      for (final ref in schedule) {
        if (ref.isImagePage) {
          await _appendImagePage(output, ref);
          continue;
        }

        final sourceDoc = documents[ref.sourceId];
        if (sourceDoc == null) {
          throw PdfProcessException('找不到源文件 ${ref.sourceId}');
        }

        if (ref.pageIndex < 0 || ref.pageIndex >= sourceDoc.pages.count) {
          throw PdfProcessException('页面索引无效：${pageRefLabel(ref)}');
        }

        final source = sources.firstWhere((item) => item.id == ref.sourceId);
        final sourcePage = sourceDoc.pages[ref.pageIndex];
        final visualSize = await _readVisualPageSize(
          source.file.path,
          ref.pageIndex,
        );
        final outputSize = pageOutputSize(visualSize, ref.rotation);

        output.pageSettings
          ..size = outputSize
          ..orientation = outputSize.width > outputSize.height
              ? PdfPageOrientation.landscape
              : PdfPageOrientation.portrait
          ..setMargins(0);
        final newPage = output.pages.add();

        await _drawPageContent(
          graphics: newPage.graphics,
          source: source,
          sourcePage: sourcePage,
          pageIndex: ref.pageIndex,
          visualSize: visualSize,
          rotation: ref.rotation,
          outputSize: outputSize,
        );
      }

      final result = Uint8List.fromList(output.saveSync());
      output.dispose();
      return result;
    } finally {
      for (final document in documents.values) {
        document.dispose();
      }
    }
  }

  Future<void> _appendImagePage(PdfDocument output, PdfPageRef ref) async {
    final imagePath = ref.imagePath;
    if (imagePath == null || !File(imagePath).existsSync()) {
      throw PdfProcessException('插入的图片不存在');
    }

    final rawBytes = await File(imagePath).readAsBytes();
    final orientedBytes =
        ref.rotation == 0 ? rawBytes : await rotatePngBytes(rawBytes, ref.rotation);
    final bitmap = PdfBitmap(orientedBytes);
    final outputSize = Size(bitmap.width.toDouble(), bitmap.height.toDouble());

    output.pageSettings
      ..size = outputSize
      ..orientation = outputSize.width > outputSize.height
          ? PdfPageOrientation.landscape
          : PdfPageOrientation.portrait
      ..setMargins(0);
    final newPage = output.pages.add();
    newPage.graphics.drawImage(
      PdfBitmap(orientedBytes),
      Rect.fromLTWH(0, 0, outputSize.width, outputSize.height),
    );
  }

  Future<void> _drawPageContent({
    required PdfGraphics graphics,
    required PdfLoadedSource source,
    required PdfPage sourcePage,
    required int pageIndex,
    required Size visualSize,
    required int rotation,
    required Size outputSize,
  }) async {
    if (rotation != 0) {
      try {
        final rawBytes = await _rasterizePage(
          source.file.path,
          pageIndex,
          visualSize,
        );
        final orientedBytes = await rotatePngBytes(rawBytes, rotation);
        graphics.drawImage(
          PdfBitmap(orientedBytes),
          Rect.fromLTWH(
            0,
            0,
            outputSize.width,
            outputSize.height,
          ),
        );
        return;
      } catch (_) {
        // 降级为矢量绘制。
      }
    }

    final contentSize = rotation == 0
        ? contentSizeOf(sourcePage)
        : visualSize;

    try {
      final template = sourcePage.createTemplate();
      if (rotation == 0) {
        graphics.drawPdfTemplate(template, Offset.zero, contentSize);
        return;
      }

      drawRotatedPage(
        graphics: graphics,
        template: template,
        contentSize: contentSize,
        rotation: rotation,
      );
    } catch (_) {
      final rawBytes = await _rasterizePage(
        source.file.path,
        pageIndex,
        visualSize,
      );
      final bytes =
          rotation == 0 ? rawBytes : await rotatePngBytes(rawBytes, rotation);
      graphics.drawImage(
        PdfBitmap(bytes),
        Rect.fromLTWH(0, 0, outputSize.width, outputSize.height),
      );
    }
  }

  Future<Size> _readVisualPageSize(String path, int pageIndex) async {
    try {
      final document = await pdfx.PdfDocument.openFile(path);
      final page = await document.getPage(pageIndex + 1);
      try {
        return Size(page.width, page.height);
      } finally {
        await page.close();
        if (!document.isClosed) {
          await document.close();
        }
      }
    } catch (_) {
      final bytes = await File(path).readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      try {
        return contentSizeOf(document.pages[pageIndex]);
      } finally {
        document.dispose();
      }
    }
  }

  Future<Uint8List> _rasterizePage(
    String path,
    int pageIndex,
    Size visualSize,
  ) async {
    final document = await pdfx.PdfDocument.openFile(path);
    final page = await document.getPage(pageIndex + 1);

    try {
      final renderWidth =
          (visualSize.width * 2).round().clamp(240, 2400);
      final renderHeight =
          (renderWidth * visualSize.height / visualSize.width)
              .round()
              .clamp(240, 3400);

      final image = await page.render(
        width: renderWidth.toDouble(),
        height: renderHeight.toDouble(),
        format: pdfx.PdfPageImageFormat.png,
        backgroundColor: '#ffffff',
      );

      if (image == null) {
        throw PdfProcessException('无法渲染第 ${pageIndex + 1} 页');
      }

      return image.bytes;
    } finally {
      await page.close();
      if (!document.isClosed) {
        await document.close();
      }
    }
  }
}

Size contentSizeOf(PdfPage page) {
  final size = page.size;
  if (size.width > 0 && size.height > 0) {
    return size;
  }

  final clientSize = page.getClientSize();
  if (clientSize.width > 0 && clientSize.height > 0) {
    return clientSize;
  }

  return PdfPageSize.a4;
}

void drawRotatedPage({
  required PdfGraphics graphics,
  required PdfTemplate template,
  required Size contentSize,
  required int rotation,
}) {
  final width = contentSize.width;
  final height = contentSize.height;
  final drawSize = Size(width, height);
  final swappedSize = Size(height, width);

  switch (rotation % 360) {
    case 90:
      graphics.save();
      graphics.translateTransform(0, height);
      graphics.rotateTransform(-90);
      graphics.drawPdfTemplate(template, Offset.zero, swappedSize);
      graphics.restore();
    case 180:
      graphics.save();
      graphics.translateTransform(width, height);
      graphics.rotateTransform(-180);
      graphics.drawPdfTemplate(template, Offset.zero, drawSize);
      graphics.restore();
    case 270:
      graphics.save();
      graphics.translateTransform(width, 0);
      graphics.rotateTransform(-270);
      graphics.drawPdfTemplate(template, Offset.zero, swappedSize);
      graphics.restore();
    default:
      graphics.drawPdfTemplate(template, Offset.zero, drawSize);
  }
}

class PdfProcessException implements Exception {
  PdfProcessException(this.message);

  final String message;

  @override
  String toString() => message;
}
