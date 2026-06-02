import 'package:flutter/material.dart';

import '../../../core/models/picked_pdf_file.dart';
import '../../../core/pdf/source_utils.dart';
import '../../../core/theme/app_theme.dart';

class SelectedFileCard extends StatelessWidget {
  const SelectedFileCard({
    super.key,
    required this.file,
    required this.index,
    required this.accentColor,
    this.onRemove,
    this.showDragHandle = false,
  });

  final PickedPdfFile file;
  final int index;
  final Color accentColor;
  final VoidCallback? onRemove;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final label = sourceLabelForIndex(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: subtleBorderColor(context),
        ),
      ),
      child: Row(
        children: [
          if (showDragHandle)
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, right: 8),
                child: Icon(
                  Icons.drag_handle_rounded,
                  size: 22,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: accentColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  file.sizeLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: '移除',
              onPressed: onRemove,
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            )
          else
            Icon(
              Icons.check_rounded,
              size: 18,
              color: accentColor.withValues(alpha: 0.7),
            ),
        ],
      ),
    );
  }
}
