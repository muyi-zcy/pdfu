import 'package:flutter/material.dart';

import '../../../core/settings/export_record.dart';
import '../../../core/settings/task_history_entry.dart';
import '../../../core/theme/app_theme.dart';
import 'export_records_section.dart';
import 'recent_tasks_section.dart';

class HomeRecordsPanel extends StatelessWidget {
  const HomeRecordsPanel({
    super.key,
    required this.history,
    required this.exportRecords,
    required this.onRemoveHistory,
    required this.onRemoveExport,
  });

  final List<TaskHistoryEntry> history;
  final List<ExportRecord> exportRecords;
  final void Function(String id) onRemoveHistory;
  final void Function(String id) onRemoveExport;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: subtleBorderColor(context)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RecentTasksSection(
            entries: history,
            onRemove: onRemoveHistory,
          ),
          const SizedBox(height: 20),
          Divider(
            height: 1,
            color: subtleBorderColor(context),
          ),
          const SizedBox(height: 20),
          ExportRecordsSection(
            records: exportRecords,
            onRemove: onRemoveExport,
          ),
        ],
      ),
    );
  }
}
