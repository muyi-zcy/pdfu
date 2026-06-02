import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A4 竖版宽高比（高 / 宽）。
const pageAspectRatio = 1.414;

bool pageIsLandscape(int rotation) => rotation % 180 == 90;

Size pageOutputSize(Size contentSize, int rotation) {
  if (pageIsLandscape(rotation)) {
    return Size(contentSize.height, contentSize.width);
  }
  return contentSize;
}

/// 按目标宽度缩放后的预览框尺寸（旋转后宽高已互换）。
Size thumbnailFrameSize(Size visualSize, int rotation, double slotWidth) {
  final oriented = pageOutputSize(visualSize, rotation);
  if (oriented.width <= 0 || oriented.height <= 0) {
    return Size(slotWidth, slotWidth * pageAspectRatio);
  }
  final scale = slotWidth / oriented.width;
  return Size(slotWidth, oriented.height * scale);
}

/// 顺时针旋转 PNG，与界面 RotatedBox quarterTurns 方向一致。
Future<Uint8List> rotatePngBytes(Uint8List bytes, int rotation) async {
  final normalized = rotation % 360;
  if (normalized == 0) {
    return bytes;
  }

  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;

  try {
    final swap = pageIsLandscape(normalized);
    final outWidth = swap ? image.height : image.width;
    final outHeight = swap ? image.width : image.height;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, outWidth.toDouble(), outHeight.toDouble()),
    );

    canvas.translate(outWidth / 2, outHeight / 2);
    canvas.rotate(normalized * math.pi / 180);
    canvas.translate(-image.width / 2, -image.height / 2);
    canvas.drawImage(image, Offset.zero, Paint());

    final picture = recorder.endRecording();
    final rotated = await picture.toImage(outWidth, outHeight);
    try {
      final data =
          await rotated.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw StateError('无法编码旋转后的页面图片');
      }
      return data.buffer.asUint8List();
    } finally {
      rotated.dispose();
    }
  } finally {
    image.dispose();
  }
}
