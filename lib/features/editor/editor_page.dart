import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import '../../core/models/pdf_feature.dart';
import '../../core/models/picked_pdf_file.dart';
import '../../core/pdf/page_schedule.dart';
import '../../core/pdf/pdf_merger.dart';
import '../../core/pdf/pdf_page_ref.dart';
import '../../core/pdf/pdf_thumbnail_service.dart';
import '../../core/pdf/source_utils.dart';
import '../../core/pdf/pdf_to_image_service.dart';
import '../../core/platform/export_service.dart';
import '../../core/platform/file_service.dart';
import '../../core/platform/image_export_service.dart';
import '../../core/settings/app_scope.dart';
import '../../core/settings/export_name_formatter.dart';
import 'widgets/export_images_dialog.dart';
import 'widgets/insert_images_dialog.dart';
import 'widgets/page_grid_cell.dart';
import 'widgets/page_preview_dialog.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({
    super.key,
    required this.feature,
    required this.files,
    required this.sources,
    required this.initialSchedule,
  });

  final PdfFeature feature;
  final List<PickedPdfFile> files;
  final List<PdfLoadedSource> sources;
  final List<PdfPageRef> initialSchedule;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final _merger = PdfMerger();
  final _exportService = ExportService();
  final _fileService = FileService();
  final _imageExportService = ImageExportService();
  final _imageConverter = PdfToImageService();
  final _thumbnailService = PdfThumbnailService();
  final _focusNode = FocusNode();
  late List<PdfPageRef> _schedule;
  bool _isExporting = false;
  bool _isExportingImages = false;
  bool _isInsertingImages = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _schedule = List.of(widget.initialSchedule);
    _thumbnailService.preloadSources(widget.sources);
  }

  @override
  void dispose() {
    _thumbnailService.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Map<String, Color> get _sourceColors {
    final colors =
        buildSourceColors(widget.sources.map((source) => source.id));
    if (widget.sources.length == 1) {
      colors['doc'] = widget.feature.accentColor;
    }
    return colors;
  }

  String get _exportBaseName {
    final file = widget.files.first;
    return file.isBlank ? PickedPdfFile.blankDocumentName : file.name;
  }

  Future<void> _exportPdf() async {
    if (_isExporting || _schedule.isEmpty) return;

    setState(() => _isExporting = true);

    try {
      final bytes = await _merger.render(
        sources: widget.sources,
        schedule: _schedule,
      );

      if (!mounted) return;

      final settings = AppScope.of(context);
      final suggestedName = settings.buildExportName(
        baseName: _exportBaseName,
        featureType: widget.feature.type,
        pageCount: _schedule.length,
      );

      final savedPath = await _exportService.savePdf(
        bytes: bytes,
        suggestedName: suggestedName,
      );

      if (!mounted) return;

      if (savedPath != null) {
        await settings.recordTask(
          featureType: widget.feature.type,
          files: widget.files,
          outputPageCount: _schedule.length,
        );
        await settings.recordExport(
          featureType: widget.feature.type,
          outputPath: savedPath,
          pageCount: _schedule.length,
        );
        _showMessage('已保存至 $savedPath');
      }
    } on PdfProcessException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('导出失败：$e');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportImages() async {
    if (_isExportingImages || _isExporting || _schedule.isEmpty) return;

    final options = await showExportImagesDialog(
      context: context,
      totalPages: _schedule.length,
    );
    if (!mounted || options == null) return;

    final pageIndices = options.resolveIndices(_schedule.length);
    if (pageIndices.isEmpty) {
      _showMessage('未选择任何页面');
      return;
    }

    final parentDir = await _imageExportService.pickOutputDirectory();
    if (!mounted || parentDir == null) return;

    setState(() => _isExportingImages = true);

    try {
      final settings = AppScope.of(context);
      final folderName = formatImageExportFolderName(
        template: settings.exportNameTemplate,
        baseName: _exportBaseName,
        suffix: imageExportSuffix,
        pageCount: pageIndices.length,
      );
      final fileBaseName = folderName;
      final outputDirectory = await _imageExportService.createOutputFolder(
        parentDirectory: parentDir,
        folderName: folderName,
      );

      final result = await _imageConverter.exportSchedule(
        schedule: _schedule,
        sources: widget.sources,
        thumbnailService: _thumbnailService,
        pageIndices: pageIndices,
        outputDirectory: outputDirectory,
        fileBaseName: fileBaseName,
        format: options.format,
        scale: options.scale,
      );

      if (!mounted) return;

      await settings.recordTask(
        featureType: widget.feature.type,
        files: widget.files,
        outputPageCount: result.savedCount,
      );
      await settings.recordExport(
        featureType: widget.feature.type,
        outputPath: result.outputDirectory,
        pageCount: result.savedCount,
      );
      _showMessage('已导出 ${result.savedCount} 张图片至 ${result.outputDirectory}');
    } on PdfProcessException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('导出图片失败：$e');
    } finally {
      if (mounted) {
        setState(() => _isExportingImages = false);
      }
    }
  }

  Future<void> _insertImages() async {
    if (_isInsertingImages || _isExporting || _isExportingImages) return;

    final insertOptions = await showInsertImagesDialog(
      context: context,
      scheduleLength: _schedule.length,
      selectedIndex: _schedule.isEmpty
          ? 0
          : _selectedIndex.clamp(0, _schedule.length - 1),
    );
    if (!mounted || insertOptions == null) return;

    setState(() => _isInsertingImages = true);
    try {
      final imagePaths = await _fileService.pickAndStageImageFiles();
      if (!mounted || imagePaths.isEmpty) return;

      final insertAt = insertOptions.resolveInsertIndex(
        scheduleLength: _schedule.length,
        selectedIndex: _selectedIndex,
      );

      setState(() {
        final newPages = [
          for (final path in imagePaths) PdfPageRef.fromImage(path),
        ];
        _schedule.insertAll(insertAt, newPages);
        _selectedIndex = insertAt + newPages.length - 1;
      });

      _showMessage(
        '已在第 ${insertAt + 1} 页起插入 ${imagePaths.length} 张图片',
      );
    } on FilePickException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('插入图片失败：$e');
    } finally {
      if (mounted) {
        setState(() => _isInsertingImages = false);
      }
    }
  }

  Future<void> _saveRecipe() async {
    final nameController = TextEditingController(
      text: '${widget.feature.title} 方案',
    );

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存页序方案'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '方案名称',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    nameController.dispose();
    if (!mounted || name == null || name.trim().isEmpty) return;

    final labels = widget.sources.map((source) => source.id).toList();
    await AppScope.of(context).saveRecipe(
      name: name.trim(),
      featureType: widget.feature.type,
      schedule: _schedule,
      sourceLabels: labels,
    );

    if (mounted) {
      _showMessage('方案已保存，可在设置中查看');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _selectPage(int index) {
    setState(() => _selectedIndex = index);
  }

  void _removeSelectedPage() {
    if (_schedule.isEmpty) return;
    setState(() {
      _schedule.removeAt(_selectedIndex);
      if (_schedule.isEmpty) {
        _selectedIndex = 0;
      } else if (_selectedIndex >= _schedule.length) {
        _selectedIndex = _schedule.length - 1;
      }
    });
  }

  void _rotateSelectedPage() {
    if (_schedule.isEmpty) return;
    setState(() {
      final page = _schedule[_selectedIndex];
      _schedule[_selectedIndex] =
          page.copyWith(rotation: (page.rotation + 90) % 360);
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;

    setState(() {
      final item = _schedule.removeAt(oldIndex);
      _schedule.insert(newIndex, item);

      if (_selectedIndex == oldIndex) {
        _selectedIndex = newIndex;
      } else if (oldIndex < _selectedIndex && newIndex >= _selectedIndex) {
        _selectedIndex -= 1;
      } else if (oldIndex > _selectedIndex && newIndex <= _selectedIndex) {
        _selectedIndex += 1;
      }
    });
  }

  void _openPreview() {
    if (_schedule.isEmpty) return;
    final page = _schedule[_selectedIndex];

    showPagePreviewDialog(
      context: context,
      service: _thumbnailService,
      pageRef: page,
      sources: widget.sources,
      outputIndex: _selectedIndex,
    );
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _schedule.isEmpty) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final isMeta = HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;

    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      _removeSelectedPage();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyR && !isMeta) {
      _rotateSelectedPage();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyS && isMeta) {
      _exportPdf();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowLeft) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1).clamp(0, _schedule.length - 1);
      });
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowRight) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1).clamp(0, _schedule.length - 1);
      });
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = gridCrossAxisCount(width);
    final thumbnailWidth = gridThumbnailWidth(width, crossAxisCount);

    final multiSource = widget.sources.length > 1;
    final cellExtent = gridCellExtent(thumbnailWidth, multiSource: multiSource);

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.feature.title} · 编辑'),
          actions: [
            if (widget.feature.type == PdfFeatureType.pdfEditor) ...[
              IconButton(
                tooltip: '插入图片',
                onPressed: _isInsertingImages ? null : _insertImages,
                icon: _isInsertingImages
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined),
              ),
              IconButton(
                tooltip: '导出图片',
                onPressed: _isExportingImages || _schedule.isEmpty
                    ? null
                    : _exportImages,
                icon: const Icon(Icons.image_outlined),
              ),
            ],
            IconButton(
              tooltip: '保存方案',
              onPressed: _schedule.isEmpty ? null : _saveRecipe,
              icon: const Icon(Icons.bookmark_add_outlined),
            ),
            TextButton.icon(
              onPressed: _isExporting || _schedule.isEmpty ? null : _exportPdf,
              icon: _isExporting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  : const Icon(Icons.save_alt_rounded),
              label: const Text('导出'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              color: colorScheme.surfaceContainerHighest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '输出共 ${_schedule.length} 页 · 每行 $crossAxisCount 页',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.feature.type == PdfFeatureType.pdfEditor
                        ? '点击选中，长按拖拽排序。可指定位置插入图片、导出指定页为图片。快捷键：Delete 删除 · R 旋转 · ←/→ 切换 · Ctrl/Cmd+S 导出 PDF'
                        : '点击选中，长按拖拽排序。快捷键：Delete 删除 · R 旋转 · ←/→ 切换 · Ctrl/Cmd+S 导出',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _schedule.isEmpty
                  ? _EmptySchedulePlaceholder(
                      isPdfEditor:
                          widget.feature.type == PdfFeatureType.pdfEditor,
                      onInsertImages: widget.feature.type ==
                              PdfFeatureType.pdfEditor
                          ? _insertImages
                          : null,
                      isInserting: _isInsertingImages,
                    )
                  : ReorderableGridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 12,
                        mainAxisExtent: cellExtent,
                      ),
                      itemCount: _schedule.length,
                      onReorder: _onReorder,
                      itemBuilder: (context, index) {
                        final page = _schedule[index];
                        final color = _sourceColors[page.sourceId] ??
                            widget.feature.accentColor;

                        return PageGridCell(
                          key: ValueKey(page.id),
                          index: index,
                          pageRef: page,
                          service: _thumbnailService,
                          sources: widget.sources,
                          thumbnailWidth: thumbnailWidth,
                          cellExtent: cellExtent,
                          isSelected: index == _selectedIndex,
                          accentColor: color,
                          onTap: () => _selectPage(index),
                        );
                      },
                    ),
            ),
            if (_schedule.isNotEmpty)
              Material(
                elevation: 4,
                color: colorScheme.surface,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '第 ${_selectedIndex + 1} 页'
                            '${_schedule[_selectedIndex].isImagePage ? ' · 插入图片' : widget.sources.length > 1 ? ' · ${_schedule[_selectedIndex].sourceId} 源第 ${_schedule[_selectedIndex].pageIndex + 1} 页' : ''}'
                            '${_schedule[_selectedIndex].rotation != 0 ? ' · 页面已旋转 ${_schedule[_selectedIndex].rotation}°' : ''}',
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: '放大预览',
                          onPressed: _openPreview,
                          icon: const Icon(Icons.zoom_in_rounded),
                        ),
                        if (widget.feature.type == PdfFeatureType.pdfEditor)
                          IconButton(
                            tooltip: '插入图片',
                            onPressed:
                                _isInsertingImages ? null : _insertImages,
                            icon: const Icon(Icons.add_photo_alternate_outlined),
                          ),
                        IconButton(
                          tooltip: '整页旋转 90° (R)',
                          onPressed: _rotateSelectedPage,
                          icon: const Icon(Icons.rotate_90_degrees_ccw),
                        ),
                        IconButton(
                          tooltip: '删除 (Delete)',
                          onPressed: _removeSelectedPage,
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FilledButton.icon(
              onPressed: _isExporting || _schedule.isEmpty ? null : _exportPdf,
              icon: _isExporting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.file_download_rounded),
              label: Text(
                _isExporting ? '正在导出…' : '导出 PDF（${_schedule.length} 页）',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptySchedulePlaceholder extends StatelessWidget {
  const _EmptySchedulePlaceholder({
    required this.isPdfEditor,
    required this.onInsertImages,
    required this.isInserting,
  });

  final bool isPdfEditor;
  final VoidCallback? onInsertImages;
  final bool isInserting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPdfEditor ? Icons.note_add_outlined : Icons.layers_clear_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isPdfEditor ? '空白文档' : '没有可导出的页面',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPdfEditor
                  ? '插入图片开始创建 PDF，或返回选择已有 PDF 文件'
                  : '请至少保留一页后再导出',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (isPdfEditor && onInsertImages != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: isInserting ? null : onInsertImages,
                icon: isInserting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('插入图片'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
