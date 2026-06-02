import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import '../../core/models/pdf_feature.dart';
import '../../core/models/picked_pdf_file.dart';
import '../../core/pdf/pdf_page_ref.dart';
import '../../core/pdf/page_schedule.dart';
import '../../core/pdf/pdf_merger.dart';
import '../../core/pdf/source_utils.dart';
import '../../core/pdf/workspace_estimate.dart';
import '../../core/platform/file_service.dart';
import '../../core/settings/app_scope.dart';
import '../../core/settings/saved_recipe.dart';
import '../../core/theme/app_theme.dart';
import '../editor/editor_page.dart';
import 'widgets/pdf_drop_target.dart';
import 'widgets/selected_file_card.dart';
import 'widgets/workspace_estimate_banner.dart';

class WorkspacePage extends StatefulWidget {
  const WorkspacePage({
    super.key,
    required this.feature,
    this.initialFiles = const [],
    this.pendingRecipe,
  });

  final PdfFeature feature;
  final List<PickedPdfFile> initialFiles;
  final SavedRecipe? pendingRecipe;

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  final _fileService = FileService();
  final _pdfLoader = PdfLoader();
  List<PickedPdfFile> _selectedFiles = [];
  bool _isPicking = false;
  bool _isLoading = false;
  bool _estimateLoading = false;
  WorkspaceEstimate? _estimate;

  @override
  void initState() {
    super.initState();
    _selectedFiles = List.of(widget.initialFiles);
    _refreshEstimate();
  }

  @override
  void didUpdateWidget(WorkspacePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFiles != widget.initialFiles &&
        widget.initialFiles.isNotEmpty) {
      _selectedFiles = List.of(widget.initialFiles);
      _refreshEstimate();
    }
  }

  Future<void> _pickFile() async {
    if (_isPicking || _isLoading) return;

    final feature = widget.feature;
    final replacingAll =
        !feature.unlimitedFiles && _selectedFiles.length >= feature.maxFiles;

    setState(() => _isPicking = true);

    try {
      final file = await _fileService.pickSinglePdfFile();

      if (!mounted || file == null) return;

      setState(() {
        if (replacingAll || feature.maxFiles == 1) {
          _selectedFiles = [file];
        } else {
          _selectedFiles = [..._selectedFiles, file];
        }
      });
      _refreshEstimate();
    } on FilePickException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('无法打开文件选择器：$e');
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _addFilesFromDrop(List<DropItem> items) async {
    if (_isPicking || _isLoading) return;

    final feature = widget.feature;
    setState(() => _isPicking = true);

    try {
      final incoming = await _fileService.stageDroppedFiles(items);
      if (!mounted) return;

      if (incoming.isEmpty) {
        _showMessage('未检测到有效的 PDF 文件');
        return;
      }

      setState(() {
        if (feature.maxFiles == 1) {
          _selectedFiles = [incoming.first];
        } else if (!feature.unlimitedFiles &&
            _selectedFiles.length >= feature.maxFiles) {
          _selectedFiles = incoming.take(feature.maxFiles).toList();
        } else {
          final merged = [..._selectedFiles, ...incoming];
          _selectedFiles = feature.unlimitedFiles
              ? merged
              : merged.take(feature.maxFiles).toList();
        }
      });
      _refreshEstimate();
    } on FilePickException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('无法读取拖入的文件：$e');
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _refreshEstimate() async {
    final feature = widget.feature;
    if (_selectedFiles.length < feature.minFiles) {
      if (mounted) {
        setState(() {
          _estimate = null;
          _estimateLoading = false;
        });
      }
      return;
    }

    setState(() => _estimateLoading = true);

    try {
      final sources = await _pdfLoader.loadSources(_selectedFiles);
      final estimate = await computeWorkspaceEstimate(
        mode: feature.type,
        sources: sources,
      );
      if (mounted) {
        setState(() {
          _estimate = estimate;
          _estimateLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _estimate = null;
          _estimateLoading = false;
        });
      }
    }
  }

  String _pickButtonLabel() {
    final feature = widget.feature;

    if (_selectedFiles.isEmpty) {
      return feature.minFiles > 1 ? '选择 PDF A' : '选择 PDF';
    }

    if (feature.canAddFiles(_selectedFiles.length)) {
      final label = sourceLabelForIndex(_selectedFiles.length);
      return '添加 PDF $label';
    }

    return '重新选择';
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles.removeAt(index));
    _refreshEstimate();
  }

  void _clearFiles() {
    setState(() => _selectedFiles = []);
    _refreshEstimate();
  }

  void _onReorderFiles(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;

    setState(() {
      var targetIndex = newIndex;
      if (targetIndex > oldIndex) {
        targetIndex -= 1;
      }
      final file = _selectedFiles.removeAt(oldIndex);
      _selectedFiles.insert(targetIndex, file);
    });
    _refreshEstimate();
  }

  List<PdfPageRef>? _recipeSchedule(List<PdfLoadedSource> sources) {
    final recipe = widget.pendingRecipe;
    if (recipe == null || !recipe.hasCustomSchedule) return null;

    final labels = sources.map((source) => source.id).toList();
    final resolved = recipe.resolveSchedule(labels);
    return resolved.isEmpty ? null : resolved;
  }

  Future<void> _startBlankEditor() async {
    if (_isLoading || !widget.feature.supportsBlankStart) return;

    setState(() => _isLoading = true);
    try {
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => EditorPage(
            feature: widget.feature,
            files: [PickedPdfFile.blank()],
            sources: const [],
            initialSchedule: const [],
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _continueToEditor() async {
    if (_selectedFiles.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final sources = await _pdfLoader.loadSources(_selectedFiles);
      final schedule = _recipeSchedule(sources) ??
          PageScheduleBuilder.build(
            mode: widget.feature.type,
            sources: sources,
          );

      if (!mounted) return;

      final settings = AppScope.of(context);
      await settings.recordTask(
        featureType: widget.feature.type,
        files: _selectedFiles,
        outputPageCount: schedule.length,
      );

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => EditorPage(
            feature: widget.feature,
            files: _selectedFiles,
            sources: sources,
            initialSchedule: schedule,
          ),
        ),
      );
    } on PdfProcessException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('加载 PDF 失败：$e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final feature = widget.feature;
    final canContinue =
        _selectedFiles.length >= feature.minFiles && !_isLoading;
    final needMoreFiles =
        _selectedFiles.isNotEmpty && _selectedFiles.length < feature.minFiles;
    final isEmpty = _selectedFiles.isEmpty;
    final canReorder = feature.maxFiles != 1 && _selectedFiles.length > 1;
    final sourceColors = buildSourceColors(
      List.generate(_selectedFiles.length, sourceLabelForIndex),
    );
    final recipe = widget.pendingRecipe;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          feature.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return PdfDropTarget(
            enabled: !_isPicking && !_isLoading,
            onFilesDropped: _addFilesFromDrop,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (recipe != null) ...[
                          _RecipeHintBanner(recipe: recipe),
                          const SizedBox(height: 16),
                        ],
                        if (isEmpty) ...[
                          _UploadZone(
                            feature: feature,
                            isPicking: _isPicking,
                            onTap: _pickFile,
                            onBlankStart: feature.supportsBlankStart
                                ? _startBlankEditor
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            feature.fileHint,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (isPdfDropSupported)
                            Text(
                              '或将 PDF 文件拖拽到此处',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ] else ...[
                          Text(
                            feature.description,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          WorkspaceEstimateBanner(
                            estimate: _estimate,
                            isLoading: _estimateLoading,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '已选文件',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          if (canReorder) ...[
                            const SizedBox(height: 4),
                            Text(
                              '拖拽左侧手柄调整文档顺序',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          if (canReorder)
                            ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              buildDefaultDragHandles: false,
                              itemCount: _selectedFiles.length,
                              onReorder: _onReorderFiles,
                              itemBuilder: (context, index) {
                                final file = _selectedFiles[index];
                                final label = sourceLabelForIndex(index);

                                return SelectedFileCard(
                                  key: ValueKey(file.path),
                                  file: file,
                                  index: index,
                                  accentColor: sourceColors[label] ??
                                      feature.accentColor,
                                  showDragHandle: true,
                                  onRemove: () => _removeFile(index),
                                );
                              },
                            )
                          else
                            ...List.generate(_selectedFiles.length, (index) {
                              final file = _selectedFiles[index];
                              final label = feature.maxFiles > 1
                                  ? sourceLabelForIndex(index)
                                  : null;

                              return SelectedFileCard(
                                key: ValueKey(file.path),
                                file: file,
                                index: index,
                                accentColor: label == null
                                    ? feature.accentColor
                                    : sourceColors[label] ??
                                        feature.accentColor,
                                onRemove: feature.maxFiles != 1
                                    ? () => _removeFile(index)
                                    : null,
                              );
                            }),
                          if (needMoreFiles) ...[
                            const SizedBox(height: 4),
                            Text(
                              '还需选择 ${feature.minFiles - _selectedFiles.length} 个文件',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: feature.accentColor,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isPicking || _isLoading
                                      ? null
                                      : _pickFile,
                                  icon: _isPicking
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: colorScheme.primary,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.add_rounded,
                                          size: 18,
                                        ),
                                  label: Text(_pickButtonLabel()),
                                ),
                              ),
                              if (feature.maxFiles != 1) ...[
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: _isPicking || _isLoading
                                      ? null
                                      : _clearFiles,
                                  child: const Text('清空'),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed:
                                  canContinue ? _continueToEditor : null,
                              child: _isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.onPrimary,
                                      ),
                                    )
                                  : Text(
                                      feature.type == PdfFeatureType.pdfEditor
                                          ? '继续 · 编辑 PDF'
                                          : '继续 · 预览页序',
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecipeHintBanner extends StatelessWidget {
  const _RecipeHintBanner({required this.recipe});

  final SavedRecipe recipe;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.bookmark_outline_rounded, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '将应用方案「${recipe.name}」'
              '${recipe.hasCustomSchedule ? '（${recipe.schedule.length} 页）' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadZone extends StatelessWidget {
  const _UploadZone({
    required this.feature,
    required this.isPicking,
    required this.onTap,
    this.onBlankStart,
  });

  final PdfFeature feature;
  final bool isPicking;
  final VoidCallback onTap;
  final VoidCallback? onBlankStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isPicking ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            color: surfaceCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: subtleBorderColor(context),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: feature.accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: isPicking
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: feature.accentColor,
                          ),
                        )
                      : Icon(
                          feature.icon,
                          size: 28,
                          color: feature.accentColor,
                        ),
                ),
                const SizedBox(height: 20),
                Text(
                  feature.subtitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  feature.description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: isPicking ? null : onTap,
                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                  label: Text(
                    feature.maxFiles > 1 ? '选择 PDF A' : '选择 PDF',
                  ),
                ),
                if (onBlankStart != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: isPicking ? null : onBlankStart,
                    icon: const Icon(Icons.note_add_outlined, size: 18),
                    label: const Text('从空白文档开始'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
