import 'package:flutter/material.dart';

import '../../../core/pdf/page_schedule.dart';
import '../../../core/pdf/pdf_page_ref.dart';
import '../../../core/pdf/pdf_thumbnail_service.dart';

class PdfPageThumbnail extends StatelessWidget {
  const PdfPageThumbnail({
    super.key,
    required this.service,
    required this.pageRef,
    required this.sources,
    required this.slotWidth,
    this.onTap,
    this.highQuality = false,
  });

  final PdfThumbnailService service;
  final PdfPageRef pageRef;
  final List<PdfLoadedSource> sources;
  final double slotWidth;
  final VoidCallback? onTap;
  final bool highQuality;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    return FutureBuilder<OrientedPageImage?>(
      future: service.renderPageRef(
        pageRef: pageRef,
        sources: sources,
        slotWidth: slotWidth,
        pixelRatio: pixelRatio,
        highQuality: highQuality,
      ),
      builder: (context, snapshot) {
        Widget child;

        if (snapshot.connectionState != ConnectionState.done) {
          child = const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data == null) {
          child = Icon(
            Icons.broken_image_outlined,
            size: 28,
            color: colorScheme.onSurfaceVariant,
          );
        } else {
          final image = snapshot.data!;
          child = Image.memory(
            image.bytes,
            width: image.frameSize.width,
            height: image.frameSize.height,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          );
        }

        final frameSize = snapshot.data?.frameSize ??
            Size(slotWidth, slotWidth * 1.414);

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: frameSize.width,
              height: frameSize.height,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
