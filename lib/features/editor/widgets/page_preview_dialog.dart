import 'package:flutter/material.dart';

import '../../../core/pdf/page_schedule.dart';
import '../../../core/pdf/pdf_page_ref.dart';
import '../../../core/pdf/pdf_thumbnail_service.dart';

Future<void> showPagePreviewDialog({
  required BuildContext context,
  required PdfThumbnailService service,
  required PdfPageRef pageRef,
  required List<PdfLoadedSource> sources,
  required int outputIndex,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 920),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        pageRef.isImagePage
                            ? '输出第 ${outputIndex + 1} 页 · 插入图片'
                            : '输出第 ${outputIndex + 1} 页 · ${pageRef.sourceId} 第 ${pageRef.pageIndex + 1} 页',
                        style: Theme.of(dialogContext)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: FutureBuilder<OrientedPageImage?>(
                    future: service.renderOrientedPage(
                      pageRef: pageRef,
                      sources: sources,
                      slotWidth: 480,
                      rotation: pageRef.rotation,
                      pixelRatio: MediaQuery.devicePixelRatioOf(context),
                      highQuality: true,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(48),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: Text('无法加载页面预览'),
                        );
                      }

                      final image = snapshot.data!;

                      return InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 5,
                        child: Image.memory(
                          image.bytes,
                          width: image.frameSize.width,
                          height: image.frameSize.height,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
