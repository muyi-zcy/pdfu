import 'package:flutter/material.dart';

import '../../core/models/pdf_feature.dart';
import '../../core/settings/app_scope.dart';
import '../../core/settings/export_name_formatter.dart';
import '../../core/settings/settings_notifier.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _templateController;
  bool _templateDirty = false;
  bool _templateInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_templateInitialized) {
      _templateController = TextEditingController(
        text: AppScope.of(context).exportNameTemplate,
      );
      _templateInitialized = true;
    }
  }

  @override
  void dispose() {
    if (_templateInitialized) {
      _templateController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('偏好设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          _SectionTitle(title: '外观'),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('跟随系统'),
                icon: Icon(Icons.brightness_auto_rounded, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('浅色'),
                icon: Icon(Icons.light_mode_outlined, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('深色'),
                icon: Icon(Icons.dark_mode_outlined, size: 18),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (selection) {
              settings.setThemeMode(selection.first);
            },
          ),
          const SizedBox(height: 28),
          _SectionTitle(title: '导出文件名'),
          const SizedBox(height: 8),
          TextField(
            controller: _templateController,
            decoration: InputDecoration(
              hintText: defaultExportNameTemplate,
              border: const OutlineInputBorder(),
              suffixIcon: _templateDirty
                  ? IconButton(
                      tooltip: '保存模板',
                      onPressed: () => _saveTemplate(settings),
                      icon: const Icon(Icons.check_rounded),
                    )
                  : null,
            ),
            onChanged: (_) => setState(() => _templateDirty = true),
            onSubmitted: (_) => _saveTemplate(settings),
          ),
          const SizedBox(height: 8),
          Text(
            '可用变量：${exportNameTemplateTokens.entries.map((e) => e.key).join(' ')}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...exportNameTemplateTokens.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${entry.key} — ${entry.value}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _PreviewChip(
            label: '预览',
            fileName: settings.buildExportName(
              baseName: '示例文档.pdf',
              featureType: PdfFeatureType.appendMerge,
              pageCount: 12,
            ),
          ),
          const SizedBox(height: 28),
          _SectionTitle(title: '导出记录'),
          const SizedBox(height: 8),
          Text(
            '成功导出的 PDF 文件列表，可在首页右侧查看。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: settings.exportRecords.isEmpty
                ? null
                : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('清空导出记录？'),
                        content: const Text('此操作不可撤销。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('清空'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await settings.clearExportRecords();
                    }
                  },
            icon: const Icon(Icons.file_download_done_rounded, size: 18),
            label: Text('清空导出记录（${settings.exportRecords.length}）'),
          ),
          const SizedBox(height: 28),
          _SectionTitle(title: '最近任务'),
          const SizedBox(height: 8),
          Text(
            '在首页显示最近使用过的文件组合，便于快速重新打开。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: settings.history.isEmpty
                ? null
                : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('清空最近任务？'),
                        content: const Text('此操作不可撤销。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('清空'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await settings.clearHistory();
                    }
                  },
            icon: const Icon(Icons.history_rounded, size: 18),
            label: Text('清空最近任务（${settings.history.length}）'),
          ),
          const SizedBox(height: 28),
          _SectionTitle(title: '已保存方案'),
          const SizedBox(height: 8),
          Text(
            '在编辑页可保存当前页序方案，源文件数量一致时可复用。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (settings.recipes.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '暂无已保存方案',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            ...settings.recipes.map(
              (recipe) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(recipe.name),
                subtitle: Text(
                  '${pdfFeatures.firstWhere((f) => f.type == recipe.featureType).title}'
                  '${recipe.hasCustomSchedule ? ' · ${recipe.schedule.length} 页' : ''}',
                ),
                trailing: IconButton(
                  tooltip: '删除方案',
                  onPressed: () => settings.removeRecipe(recipe.id),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: colorScheme.error,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
          _SectionTitle(title: '缓存与数据'),
          const SizedBox(height: 8),
          Text(
            '清除本地临时缓存（暂存 PDF、插入图片等），并重置导出记录、最近任务、已保存方案与导出文件名模板。外观设置不会被清除。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _confirmClearCacheAndData(context, settings),
            icon: Icon(Icons.delete_sweep_rounded, size: 18, color: colorScheme.error),
            label: Text(
              '清除缓存和数据',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearCacheAndData(
    BuildContext context,
    SettingsNotifier settings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除缓存和数据？'),
        content: const Text(
          '将删除本地临时文件，并清空导出记录、最近任务、已保存方案，同时将导出文件名模板恢复为默认。此操作不可撤销。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    await settings.clearCacheAndData();
    if (!context.mounted) {
      return;
    }

    _templateController.text = settings.exportNameTemplate;
    setState(() => _templateDirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('缓存和数据已清除')),
    );
  }

  Future<void> _saveTemplate(SettingsNotifier settings) async {
    await settings.setExportNameTemplate(_templateController.text);
    if (mounted) {
      setState(() => _templateDirty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导出文件名模板已保存')),
      );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({
    required this.label,
    required this.fileName,
  });

  final String label;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label：$fileName',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
