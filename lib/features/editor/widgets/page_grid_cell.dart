import 'package:flutter/material.dart';

import '../../../core/pdf/page_image_utils.dart';
import '../../../core/pdf/page_schedule.dart';
import '../../../core/pdf/pdf_page_ref.dart';
import '../../../core/pdf/pdf_thumbnail_service.dart';
import 'pdf_page_thumbnail.dart';

class PageGridCell extends StatelessWidget {
  const PageGridCell({
    super.key,
    required this.index,
    required this.pageRef,
    required this.service,
    required this.sources,
    required this.thumbnailWidth,
    required this.cellExtent,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  final int index;
  final PdfPageRef pageRef;
  final PdfThumbnailService service;
  final List<PdfLoadedSource> sources;
  final double thumbnailWidth;
  final double cellExtent;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final maxThumbHeight = thumbnailWidth * pageAspectRatio;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: cellExtent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? colorScheme.error : colorScheme.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SizedBox(
                width: thumbnailWidth,
                height: maxThumbHeight,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: PdfPageThumbnail(
                    service: service,
                    pageRef: pageRef,
                    sources: sources,
                    slotWidth: thumbnailWidth,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '第 ${index + 1} 页',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                height: 1.2,
              ),
            ),
            if (pageRef.isImagePage)
              Text(
                '插入图片',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  height: 1.2,
                  color: accentColor,
                ),
              )
            else if (sources.length > 1)
              Text(
                '${pageRef.sourceId}·${pageRef.pageIndex + 1}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  height: 1.2,
                  color: accentColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

int gridCrossAxisCount(double width) {
  if (width >= 1200) return 8;
  if (width >= 960) return 7;
  if (width >= 800) return 6;
  if (width >= 640) return 5;
  if (width >= 480) return 4;
  return 3;
}

double gridThumbnailWidth(double width, int crossAxisCount) {
  const horizontalPadding = 32.0;
  const spacing = 12.0;
  final available = width - horizontalPadding - spacing * (crossAxisCount - 1);
  return (available / crossAxisCount).clamp(72.0, 130.0);
}

double gridCellExtent(double thumbnailWidth, {required bool multiSource}) {
  final thumbHeight = thumbnailWidth * pageAspectRatio;
  const spacing = 6.0;
  const primaryLabel = 18.0;
  const sourceLabel = 14.0;
  const border = 4.0;
  const buffer = 6.0;
  final labels = spacing + primaryLabel + (multiSource ? sourceLabel : 0);
  return thumbHeight + labels + border + buffer;
}
