import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:pdfx/pdfx.dart';

import 'page_image_utils.dart';
import 'page_schedule.dart';
import 'pdf_image_options.dart';
import 'pdf_page_ref.dart';

class OrientedPageImage {
  const OrientedPageImage({
    required this.bytes,
    required this.visualSize,
    required this.frameSize,
  });

  final Uint8List bytes;
  final ui.Size visualSize;
  final ui.Size frameSize;
}

class PdfThumbnailService {
  final Map<String, PdfDocument> _documents = {};
  final Map<String, Uint8List> _cache = {};
  final Map<String, ui.Size> _sizeCache = {};

  Future<void> preloadSources(List<PdfLoadedSource> sources) async {
    for (final source in sources) {
      await _openDocument(source.file.path);
    }
  }

  Future<ui.Size?> getVisualPageSize({
    required PdfPageRef pageRef,
    required List<PdfLoadedSource> sources,
  }) async {
    if (pageRef.isImagePage) {
      return _readImageVisualSize(pageRef.imagePath!);
    }

    final source = _findSource(pageRef.sourceId, sources);
    if (source == null) {
      return null;
    }

    final cacheKey = '${source.file.path}:${pageRef.pageIndex}';
    final cached = _sizeCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final document = await _openDocument(source.file.path);
    final page = await document.getPage(pageRef.pageIndex + 1);
    try {
      final size = ui.Size(page.width, page.height);
      _sizeCache[cacheKey] = size;
      return size;
    } finally {
      await page.close();
    }
  }

  Future<OrientedPageImage?> renderPageRef({
    required PdfPageRef pageRef,
    required List<PdfLoadedSource> sources,
    required double slotWidth,
    double pixelRatio = 2.0,
    bool highQuality = false,
  }) {
    return renderOrientedPage(
      pageRef: pageRef,
      sources: sources,
      slotWidth: slotWidth,
      rotation: pageRef.rotation,
      pixelRatio: pixelRatio,
      highQuality: highQuality,
    );
  }

  /// 渲染与导出一致的朝向：pdfx 原图 → 内存旋转 → 返回最终预览图。
  Future<OrientedPageImage?> renderOrientedPage({
    required PdfPageRef pageRef,
    required List<PdfLoadedSource> sources,
    required double slotWidth,
    required int rotation,
    double pixelRatio = 2.0,
    bool highQuality = false,
  }) async {
    final visualSize = await getVisualPageSize(
      pageRef: pageRef,
      sources: sources,
    );
    if (visualSize == null) {
      return null;
    }

    final rawBytes = await renderThumbnail(
      pageRef: pageRef,
      sources: sources,
      displayWidth: slotWidth,
      pixelRatio: pixelRatio,
      highQuality: highQuality,
    );
    if (rawBytes == null) {
      return null;
    }

    final bytes =
        rotation == 0 ? rawBytes : await rotatePngBytes(rawBytes, rotation);

    return OrientedPageImage(
      bytes: bytes,
      visualSize: visualSize,
      frameSize: thumbnailFrameSize(visualSize, rotation, slotWidth),
    );
  }

  Future<Uint8List?> renderPageRefForExport({
    required PdfPageRef pageRef,
    required List<PdfLoadedSource> sources,
    required PdfImageScale scale,
  }) async {
    if (pageRef.isImagePage) {
      return _renderInsertedImageForExport(pageRef, scale);
    }

    final source = _findSource(pageRef.sourceId, sources);
    if (source == null) {
      return null;
    }

    final document = await _openDocument(source.file.path);
    final page = await document.getPage(pageRef.pageIndex + 1);

    try {
      final renderWidth = (page.width * scale.dpiFactor).round().clamp(120, 4800);
      final renderHeight =
          (page.height * scale.dpiFactor).round().clamp(120, 6800);

      final image = await page.render(
        width: renderWidth.toDouble(),
        height: renderHeight.toDouble(),
        format: PdfPageImageFormat.png,
        backgroundColor: '#ffffff',
      );

      if (image == null) {
        return null;
      }

      return pageRef.rotation == 0
          ? image.bytes
          : rotatePngBytes(image.bytes, pageRef.rotation);
    } finally {
      await page.close();
    }
  }

  /// [displayWidth] 为界面上的逻辑宽度；按 [pixelRatio] 放大渲染以保证清晰。
  Future<Uint8List?> renderThumbnail({
    required PdfPageRef pageRef,
    required List<PdfLoadedSource> sources,
    required double displayWidth,
    double pixelRatio = 2.0,
    bool highQuality = false,
  }) async {
    if (pageRef.isImagePage) {
      return _renderInsertedImageThumbnail(
        pageRef.imagePath!,
        displayWidth: displayWidth,
        pixelRatio: pixelRatio,
        highQuality: highQuality,
      );
    }

    final scale = highQuality ? pixelRatio * 2.5 : pixelRatio * 2;
    final renderWidth = (displayWidth * scale).round().clamp(180, 2400);

    final cacheKey =
        '${pageRef.sourceId}:${pageRef.pageIndex}:$renderWidth:${pageRef.imagePath}';
    final cached = _cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final source = _findSource(pageRef.sourceId, sources);
    if (source == null) {
      return null;
    }

    final document = await _openDocument(source.file.path);
    final page = await document.getPage(pageRef.pageIndex + 1);

    try {
      final aspect = page.height / page.width;
      final width = renderWidth;
      final height = (renderWidth * aspect).round().clamp(120, 3400);

      final image = await page.render(
        width: width.toDouble(),
        height: height.toDouble(),
        format: PdfPageImageFormat.png,
        backgroundColor: '#ffffff',
      );

      if (image == null) {
        return null;
      }

      _cache[cacheKey] = image.bytes;
      return image.bytes;
    } finally {
      await page.close();
    }
  }

  Future<Uint8List?> _renderInsertedImageForExport(
    PdfPageRef pageRef,
    PdfImageScale scale,
  ) async {
    final imagePath = pageRef.imagePath;
    if (imagePath == null || !File(imagePath).existsSync()) {
      return null;
    }

    final visualSize = await _readImageVisualSize(imagePath);
    if (visualSize == null) {
      return null;
    }

    final pngBytes = await _renderImageFileToPng(
      imagePath,
      targetWidth: (visualSize.width * scale.dpiFactor).round().clamp(120, 4800),
    );
    if (pngBytes == null) {
      return null;
    }

    return pageRef.rotation == 0
        ? pngBytes
        : rotatePngBytes(pngBytes, pageRef.rotation);
  }

  Future<Uint8List?> _renderInsertedImageThumbnail(
    String imagePath, {
    required double displayWidth,
    required double pixelRatio,
    required bool highQuality,
  }) async {
    final scale = highQuality ? pixelRatio * 2.5 : pixelRatio * 2;
    final renderWidth = (displayWidth * scale).round().clamp(180, 2400);
    final cacheKey = '$imagePath:$renderWidth';
    final cached = _cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final pngBytes = await _renderImageFileToPng(
      imagePath,
      targetWidth: renderWidth,
    );
    if (pngBytes == null) {
      return null;
    }

    _cache[cacheKey] = pngBytes;
    return pngBytes;
  }

  Future<Uint8List?> _renderImageFileToPng(
    String imagePath, {
    required int targetWidth,
  }) async {
    final bytes = await File(imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: targetWidth,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;

    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        return null;
      }
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<ui.Size?> _readImageVisualSize(String imagePath) async {
    final cacheKey = 'image-size:$imagePath';
    final cached = _sizeCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    if (!File(imagePath).existsSync()) {
      return null;
    }

    final bytes = await File(imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    try {
      final size = ui.Size(image.width.toDouble(), image.height.toDouble());
      _sizeCache[cacheKey] = size;
      return size;
    } finally {
      image.dispose();
    }
  }

  PdfLoadedSource? _findSource(
    String sourceId,
    List<PdfLoadedSource> sources,
  ) {
    for (final item in sources) {
      if (item.id == sourceId) {
        return item;
      }
    }
    return null;
  }

  Future<PdfDocument> _openDocument(String path) async {
    final existing = _documents[path];
    if (existing != null && !existing.isClosed) {
      return existing;
    }

    final document = await PdfDocument.openFile(path);
    _documents[path] = document;
    return document;
  }

  void dispose() {
    for (final document in _documents.values) {
      if (!document.isClosed) {
        document.close();
      }
    }
    _documents.clear();
    _cache.clear();
    _sizeCache.clear();
  }
}
