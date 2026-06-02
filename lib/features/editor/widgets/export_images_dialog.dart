import 'package:flutter/material.dart';

import '../../../core/pdf/page_selection.dart';
import '../../../core/pdf/pdf_image_options.dart';

class ExportImagesOptions {
  const ExportImagesOptions({
    required this.mode,
    required this.format,
    required this.scale,
    this.rangeStart,
    this.rangeEnd,
    this.specificPages,
  });

  final PageSelectionMode mode;
  final PdfImageFormat format;
  final PdfImageScale scale;
  final int? rangeStart;
  final int? rangeEnd;
  final String? specificPages;

  List<int> resolveIndices(int totalPages) {
    return PageSelection.resolve(
      totalPages: totalPages,
      mode: mode,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      specific: specificPages,
    );
  }
}

Future<ExportImagesOptions?> showExportImagesDialog({
  required BuildContext context,
  required int totalPages,
}) {
  return showDialog<ExportImagesOptions>(
    context: context,
    builder: (context) => _ExportImagesDialog(totalPages: totalPages),
  );
}

class _ExportImagesDialog extends StatefulWidget {
  const _ExportImagesDialog({required this.totalPages});

  final int totalPages;

  @override
  State<_ExportImagesDialog> createState() => _ExportImagesDialogState();
}

class _ExportImagesDialogState extends State<_ExportImagesDialog> {
  PageSelectionMode _mode = PageSelectionMode.all;
  PdfImageFormat _format = PdfImageFormat.png;
  PdfImageScale _scale = PdfImageScale.standard;
  final _rangeStartController = TextEditingController(text: '1');
  final _rangeEndController = TextEditingController();
  final _specificController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rangeEndController.text = '${widget.totalPages}';
  }

  @override
  void dispose() {
    _rangeStartController.dispose();
    _rangeEndController.dispose();
    _specificController.dispose();
    super.dispose();
  }

  ExportImagesOptions _buildOptions() {
    return ExportImagesOptions(
      mode: _mode,
      format: _format,
      scale: _scale,
      rangeStart: int.tryParse(_rangeStartController.text.trim()),
      rangeEnd: int.tryParse(_rangeEndController.text.trim()),
      specificPages: _specificController.text.trim(),
    );
  }

  int get _selectedCount => _buildOptions().resolveIndices(widget.totalPages).length;

  void _submit() {
    if (_selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一页')),
      );
      return;
    }

    Navigator.pop(context, _buildOptions());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('导出图片'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '选择要导出的页面（当前文档共 ${widget.totalPages} 页）',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              SegmentedButton<PageSelectionMode>(
                segments: const [
                  ButtonSegment(
                    value: PageSelectionMode.all,
                    label: Text('全部'),
                  ),
                  ButtonSegment(
                    value: PageSelectionMode.range,
                    label: Text('范围'),
                  ),
                  ButtonSegment(
                    value: PageSelectionMode.specific,
                    label: Text('指定页'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) {
                  setState(() => _mode = selection.first);
                },
              ),
              const SizedBox(height: 12),
              if (_mode == PageSelectionMode.range)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _rangeStartController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '起始页',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('—'),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _rangeEndController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '结束页',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                )
              else if (_mode == PageSelectionMode.specific)
                TextField(
                  controller: _specificController,
                  decoration: const InputDecoration(
                    labelText: '页码',
                    hintText: '例如：1,3,5-8',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              const SizedBox(height: 8),
              Text(
                PageSelection.describeSelection(
                  totalPages: widget.totalPages,
                  mode: _mode,
                  rangeStart: int.tryParse(_rangeStartController.text.trim()),
                  rangeEnd: int.tryParse(_rangeEndController.text.trim()),
                  specific: _specificController.text.trim(),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text('图片格式', style: theme.textTheme.bodySmall),
              const SizedBox(height: 6),
              SegmentedButton<PdfImageFormat>(
                segments: const [
                  ButtonSegment(value: PdfImageFormat.png, label: Text('PNG')),
                  ButtonSegment(value: PdfImageFormat.jpeg, label: Text('JPEG')),
                ],
                selected: {_format},
                onSelectionChanged: (selection) {
                  setState(() => _format = selection.first);
                },
              ),
              const SizedBox(height: 14),
              Text('清晰度', style: theme.textTheme.bodySmall),
              const SizedBox(height: 6),
              SegmentedButton<PdfImageScale>(
                segments: PdfImageScale.values
                    .map(
                      (item) => ButtonSegment(
                        value: item,
                        label: Text(
                          switch (item) {
                            PdfImageScale.preview => '预览',
                            PdfImageScale.standard => '标准',
                            PdfImageScale.high => '高清',
                          },
                        ),
                      ),
                    )
                    .toList(),
                selected: {_scale},
                onSelectionChanged: (selection) {
                  setState(() => _scale = selection.first);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text('导出 $_selectedCount 页'),
        ),
      ],
    );
  }
}
