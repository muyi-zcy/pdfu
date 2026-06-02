import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef PdfFilesDropped = void Function(List<DropItem> files);

bool get isPdfDropSupported {
  if (kIsWeb) return true;
  return switch (defaultTargetPlatform) {
    TargetPlatform.macOS ||
    TargetPlatform.windows ||
    TargetPlatform.linux =>
      true,
    _ => false,
  };
}

class PdfDropTarget extends StatefulWidget {
  const PdfDropTarget({
    super.key,
    required this.enabled,
    required this.onFilesDropped,
    required this.child,
  });

  final bool enabled;
  final PdfFilesDropped onFilesDropped;
  final Widget child;

  @override
  State<PdfDropTarget> createState() => _PdfDropTargetState();
}

class _PdfDropTargetState extends State<PdfDropTarget> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || !isPdfDropSupported) {
      return widget.child;
    }

    final colorScheme = Theme.of(context).colorScheme;

    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (details) {
        setState(() => _dragging = false);
        final files = details.files
            .where((file) => file.path.toLowerCase().endsWith('.pdf'))
            .toList();
        if (files.isNotEmpty) {
          widget.onFilesDropped(files);
        }
      },
      child: Stack(
        children: [
          widget.child,
          if (_dragging)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.06),
                    border: Border.all(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.file_download_outlined,
                          size: 32,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '松开以添加 PDF',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
