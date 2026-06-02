import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/pdf_feature.dart';
import '../../../core/models/picked_pdf_file.dart';
import '../../../core/settings/task_history_entry.dart';
import '../../../core/theme/app_theme.dart';
import '../../workspace/workspace_page.dart';

class RecentTasksSection extends StatelessWidget {
  const RecentTasksSection({
    super.key,
    required this.entries,
    required this.onRemove,
  });

  final List<TaskHistoryEntry> entries;
  final void Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final visible = entries.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '历史记录',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '点击可快速重新打开',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                '暂无历史记录',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ...visible.map((entry) {
            final feature =
                pdfFeatures.firstWhere((item) => item.type == entry.featureType);

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _RecentTaskTile(
                entry: entry,
                feature: feature,
                onTap: () => _openEntry(context, entry, feature),
                onRemove: () => onRemove(entry.id),
              ),
            );
          }),
      ],
    );
  }

  void _openEntry(
    BuildContext context,
    TaskHistoryEntry entry,
    PdfFeature feature,
  ) {
    final files = <PickedPdfFile>[];
    for (var i = 0; i < entry.filePaths.length; i++) {
      final path = entry.filePaths[i];
      if (!File(path).existsSync()) continue;
      files.add(
        PickedPdfFile(
          name: i < entry.fileNames.length ? entry.fileNames[i] : path,
          path: path,
          sizeBytes: File(path).lengthSync(),
        ),
      );
    }

    if (files.length < feature.minFiles) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('部分文件已移动或删除，请重新选择'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => WorkspacePage(
          feature: feature,
          initialFiles: files,
        ),
      ),
    );
  }
}

class _RecentTaskTile extends StatelessWidget {
  const _RecentTaskTile({
    required this.entry,
    required this.feature,
    required this.onTap,
    required this.onRemove,
  });

  final TaskHistoryEntry entry;
  final PdfFeature feature;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timeLabel = DateFormat('M/d HH:mm').format(entry.lastUsedAt);

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
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
                  feature.icon,
                  size: 14,
                  color: feature.accentColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.title,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        entry.fileSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        timeLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
