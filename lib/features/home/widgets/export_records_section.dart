import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/pdf_feature.dart';
import '../../../core/platform/file_reveal_service.dart';
import '../../../core/settings/export_record.dart';
import '../../../core/theme/app_theme.dart';

class ExportRecordsSection extends StatelessWidget {
  const ExportRecordsSection({
    super.key,
    required this.records,
    required this.onRemove,
  });

  final List<ExportRecord> records;
  final void Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final visible = records.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '导出记录',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '点击在文件夹中打开',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        if (visible.isEmpty)
          _EmptyHint(text: '暂无导出记录')
        else
          ...visible.map((record) {
            final feature = pdfFeatures
                .firstWhere((item) => item.type == record.featureType);

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _ExportRecordTile(
                record: record,
                feature: feature,
                onTap: () => _onTap(context, record),
                onRemove: () => onRemove(record.id),
              ),
            );
          }),
      ],
    );
  }

  Future<void> _onTap(BuildContext context, ExportRecord record) async {
    final exists = File(record.outputPath).existsSync() ||
        Directory(record.outputPath).existsSync();
    if (!exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('文件已移动或删除')),
      );
      return;
    }

    const service = FileRevealService();
    final opened = await service.revealInFolder(record.outputPath);
    if (!context.mounted) return;

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法在文件夹中打开')),
      );
    }
  }
}

class _ExportRecordTile extends StatelessWidget {
  const _ExportRecordTile({
    required this.record,
    required this.feature,
    required this.onTap,
    required this.onRemove,
  });

  final ExportRecord record;
  final PdfFeature feature;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final exists = File(record.outputPath).existsSync() ||
        Directory(record.outputPath).existsSync();
    final timeLabel = DateFormat('M/d HH:mm').format(record.exportedAt);

    return Material(
      color: surfaceCardColor(context),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: subtleBorderColor(context)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.file_download_done_rounded,
                  size: 14,
                  color: exists
                      ? feature.accentColor
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: exists
                              ? null
                              : colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                        ),
                      ),
                      Text(
                        '${feature.title} · ${record.pageCount} 页 · $timeLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (exists) ...[
                  Icon(
                    Icons.folder_open_outlined,
                    size: 14,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                ],
                InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}
