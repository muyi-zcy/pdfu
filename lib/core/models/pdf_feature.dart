import 'package:flutter/material.dart';

enum PdfFeatureType {
  alternateMerge,
  appendMerge,
  reverseBMerge,
  pdfEditor,
}

PdfFeatureType parsePdfFeatureType(String value) {
  switch (value) {
    case 'pageEditor':
    case 'pdfToImage':
      return PdfFeatureType.pdfEditor;
    default:
      return PdfFeatureType.values.byName(value);
  }
}

class PdfFeature {
  const PdfFeature({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.minFiles,
    required this.maxFiles,
  });

  final PdfFeatureType type;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color accentColor;
  final int minFiles;
  final int maxFiles;

  bool get unlimitedFiles => maxFiles < 0;

  bool canAddFiles(int currentCount) =>
      unlimitedFiles || currentCount < maxFiles;

  bool get supportsBlankStart =>
      type == PdfFeatureType.pdfEditor && minFiles == 0;

  String get fileHint {
    if (supportsBlankStart) {
      return '选择 PDF 文件，或从空白文档开始';
    }
    if (minFiles == 1 && maxFiles == 1) {
      return '选择 1 个 PDF 文件';
    }
    if (unlimitedFiles) {
      return '至少选择 $minFiles 个 PDF 文件，可继续添加';
    }
    if (minFiles == maxFiles) {
      return '分别选择 $minFiles 个 PDF 文件（每次 1 个）';
    }
    return '分别选择 $minFiles～$maxFiles 个 PDF 文件（每次 1 个）';
  }
}

const pdfFeatures = <PdfFeature>[
  PdfFeature(
    type: PdfFeatureType.alternateMerge,
    title: '交叉合并',
    subtitle: 'A1, B1, C1, A2 …',
    description: '多份 PDF 逐页交替合并，适合双语文档或问答对照排版。',
    icon: Icons.swap_horiz_rounded,
    accentColor: Color(0xFF2563EB),
    minFiles: 2,
    maxFiles: -1,
  ),
  PdfFeature(
    type: PdfFeatureType.appendMerge,
    title: '顺序合并',
    subtitle: 'A 全部 + B 全部 + …',
    description: '将多份 PDF 按顺序首尾拼接，生成一份完整文档。',
    icon: Icons.merge_type_rounded,
    accentColor: Color(0xFF059669),
    minFiles: 2,
    maxFiles: -1,
  ),
  PdfFeature(
    type: PdfFeatureType.reverseBMerge,
    title: 'B 反向交叉',
    subtitle: 'A1, Bn, C1, A2 …',
    description: '第二份 PDF 页序反转后与其余文档交叉合并，常用于纠正双面扫描顺序。',
    icon: Icons.flip_rounded,
    accentColor: Color(0xFF7C3AED),
    minFiles: 2,
    maxFiles: -1,
  ),
  PdfFeature(
    type: PdfFeatureType.pdfEditor,
    title: 'PDF 编辑',
    subtitle: '页序 · 插图片 · 转图片',
    description: '从空白或已有 PDF 开始，调整页序、插入图片页，并可将指定页面导出为 PNG/JPEG。',
    icon: Icons.edit_document,
    accentColor: Color(0xFFEA580C),
    minFiles: 0,
    maxFiles: 1,
  ),
];
