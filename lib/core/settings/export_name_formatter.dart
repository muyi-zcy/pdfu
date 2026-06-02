import 'package:intl/intl.dart';

import '../models/pdf_feature.dart';

const defaultExportNameTemplate = '{name}-{suffix}';
const imageExportSuffix = 'images';

const exportNameTemplateTokens = <String, String>{
  '{name}': '源文件名（不含扩展名）',
  '{suffix}': '模式后缀（mixed、merged 等）',
  '{date}': '导出日期（yyyyMMdd）',
  '{pages}': '输出页数',
};

String exportSuffixForFeature(PdfFeatureType type) {
  return switch (type) {
    PdfFeatureType.alternateMerge => 'mixed',
    PdfFeatureType.appendMerge => 'merged',
    PdfFeatureType.reverseBMerge => 'reverse-mixed',
    PdfFeatureType.pdfEditor => 'edited',
  };
}

/// 图片导出文件夹名（不含扩展名）。
String formatImageExportFolderName({
  required String template,
  required String baseName,
  required String suffix,
  required int pageCount,
  DateTime? exportedAt,
}) {
  final pdfName = formatExportFileName(
    template: template,
    baseName: baseName,
    suffix: suffix,
    pageCount: pageCount,
    exportedAt: exportedAt,
  );
  return pdfName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
}

String formatExportFileName({
  required String template,
  required String baseName,
  required String suffix,
  required int pageCount,
  DateTime? exportedAt,
}) {
  final sanitized =
      baseName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
  final date = DateFormat('yyyyMMdd').format(exportedAt ?? DateTime.now());

  var result = template
      .replaceAll('{name}', sanitized)
      .replaceAll('{suffix}', suffix)
      .replaceAll('{date}', date)
      .replaceAll('{pages}', '$pageCount');

  if (!result.toLowerCase().endsWith('.pdf')) {
    result = '$result.pdf';
  }

  return result.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
}
