import 'dart:io';

import '../models/pdf_feature.dart';
import 'page_schedule.dart';

class WorkspaceEstimate {
  const WorkspaceEstimate({
    required this.inputPageCount,
    required this.outputPageCount,
    required this.inputBytes,
  });

  final int inputPageCount;
  final int outputPageCount;
  final int inputBytes;

  String get inputSizeLabel => _formatBytes(inputBytes);

  String get outputSizeLabel {
    if (inputPageCount == 0) return inputSizeLabel;
    final ratio = outputPageCount / inputPageCount;
    return _formatBytes((inputBytes * ratio).round());
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

Future<WorkspaceEstimate?> computeWorkspaceEstimate({
  required PdfFeatureType mode,
  required List<PdfLoadedSource> sources,
}) async {
  if (sources.isEmpty) return null;

  final schedule = PageScheduleBuilder.build(mode: mode, sources: sources);
  final inputPages =
      sources.fold<int>(0, (sum, source) => sum + source.pageCount);
  var inputBytes = 0;
  for (final source in sources) {
    try {
      inputBytes += await File(source.file.path).length();
    } catch (_) {
      inputBytes += source.file.sizeBytes;
    }
  }

  return WorkspaceEstimate(
    inputPageCount: inputPages,
    outputPageCount: schedule.length,
    inputBytes: inputBytes,
  );
}
