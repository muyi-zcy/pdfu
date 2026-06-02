import 'package:flutter/material.dart';

enum ImageInsertPosition {
  afterSelection,
  beforePage,
  atStart,
  atEnd,
}

class InsertImagesOptions {
  const InsertImagesOptions({
    required this.position,
    this.beforePage,
  });

  final ImageInsertPosition position;
  final int? beforePage;

  int resolveInsertIndex({
    required int scheduleLength,
    required int selectedIndex,
  }) {
    switch (position) {
      case ImageInsertPosition.atStart:
        return 0;
      case ImageInsertPosition.atEnd:
        return scheduleLength;
      case ImageInsertPosition.afterSelection:
        if (scheduleLength == 0) return 0;
        return (selectedIndex + 1).clamp(0, scheduleLength);
      case ImageInsertPosition.beforePage:
        if (scheduleLength == 0) return 0;
        final page = (beforePage ?? 1).clamp(1, scheduleLength + 1);
        return (page - 1).clamp(0, scheduleLength);
    }
  }

  String describe({required int scheduleLength, required int selectedIndex}) {
    if (scheduleLength == 0) {
      return '将插入到文档开头';
    }

    final index = resolveInsertIndex(
      scheduleLength: scheduleLength,
      selectedIndex: selectedIndex,
    );
    final outputPage = index + 1;
    return switch (position) {
      ImageInsertPosition.atStart => '将插入到第 1 页之前',
      ImageInsertPosition.atEnd => '将插入到文档末尾（第 ${scheduleLength + 1} 页起）',
      ImageInsertPosition.afterSelection =>
        '将插入到第 ${selectedIndex + 1} 页之后（第 $outputPage 页起）',
      ImageInsertPosition.beforePage =>
        '将插入到第 ${beforePage ?? 1} 页之前（第 $outputPage 页起）',
    };
  }
}

Future<InsertImagesOptions?> showInsertImagesDialog({
  required BuildContext context,
  required int scheduleLength,
  required int selectedIndex,
}) {
  return showDialog<InsertImagesOptions>(
    context: context,
    builder: (context) => _InsertImagesDialog(
      scheduleLength: scheduleLength,
      selectedIndex: selectedIndex,
    ),
  );
}

class _InsertImagesDialog extends StatefulWidget {
  const _InsertImagesDialog({
    required this.scheduleLength,
    required this.selectedIndex,
  });

  final int scheduleLength;
  final int selectedIndex;

  @override
  State<_InsertImagesDialog> createState() => _InsertImagesDialogState();
}

class _InsertImagesDialogState extends State<_InsertImagesDialog> {
  late ImageInsertPosition _position;
  final _beforePageController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _position = widget.scheduleLength == 0
        ? ImageInsertPosition.atStart
        : ImageInsertPosition.afterSelection;
  }

  @override
  void dispose() {
    _beforePageController.dispose();
    super.dispose();
  }

  InsertImagesOptions _buildOptions() {
    return InsertImagesOptions(
      position: _position,
      beforePage: int.tryParse(_beforePageController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = _buildOptions();
    final description = options.describe(
      scheduleLength: widget.scheduleLength,
      selectedIndex: widget.selectedIndex,
    );

    return AlertDialog(
      title: const Text('插入图片'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.scheduleLength == 0)
              Text(
                '当前文档为空，图片将作为首批页面插入。',
                style: theme.textTheme.bodySmall,
              )
            else
              Text(
                '当前共 ${widget.scheduleLength} 页，已选中第 ${widget.selectedIndex + 1} 页',
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            SegmentedButton<ImageInsertPosition>(
              segments: [
                if (widget.scheduleLength > 0)
                  const ButtonSegment(
                    value: ImageInsertPosition.afterSelection,
                    label: Text('选中页后'),
                  ),
                const ButtonSegment(
                  value: ImageInsertPosition.beforePage,
                  label: Text('指定页前'),
                ),
                const ButtonSegment(
                  value: ImageInsertPosition.atStart,
                  label: Text('开头'),
                ),
                const ButtonSegment(
                  value: ImageInsertPosition.atEnd,
                  label: Text('末尾'),
                ),
              ],
              selected: {_position},
              onSelectionChanged: (selection) {
                setState(() => _position = selection.first);
              },
            ),
            if (_position == ImageInsertPosition.beforePage) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _beforePageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '页码',
                  hintText: widget.scheduleLength == 0
                      ? '1'
                      : '1-${widget.scheduleLength + 1}',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, options),
          child: const Text('选择图片'),
        ),
      ],
    );
  }
}
