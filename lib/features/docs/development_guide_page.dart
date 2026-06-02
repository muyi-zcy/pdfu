import 'package:flutter/material.dart';

import 'doc_page.dart';
import 'widgets/doc_section.dart';

class DevelopmentGuidePage extends StatelessWidget {
  const DevelopmentGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: '开发说明',
      subtitle: '项目架构与开发指南',
      icon: Icons.code_rounded,
      accentColor: const Color(0xFF059669),
      sections: const [
        DocSection(
          title: '项目概述',
          children: [
            DocParagraph(
              'pd斧（pdf_edit）是基于 Flutter 的跨平台桌面应用，提供 PDF 交叉合并、顺序合并、反向交叉合并及页序编辑能力。核心设计原则：本地处理、无网络依赖。',
            ),
          ],
        ),
        DocSection(
          title: '环境要求',
          children: [
            DocTable(
              headers: ['项目', '版本'],
              rows: [
                ['Flutter SDK', '≥ 3.11.5'],
                ['Dart SDK', '^3.11.5'],
              ],
            ),
          ],
        ),
        DocSection(
          title: '快速开始',
          children: [
            DocCodeBlock('''cd pdf-edit
flutter pub get
flutter run -d macos    # macOS
flutter run -d windows  # Windows
flutter run -d linux    # Linux
flutter run -d chrome   # Web'''),
          ],
        ),
        DocSection(
          title: '项目结构',
          children: [
            DocCodeBlock('''lib/
├── main.dart              # 应用入口
├── app.dart               # 主题与路由
├── core/
│   ├── models/            # 数据模型
│   ├── pdf/               # PDF 处理核心
│   └── platform/          # 文件选择与导出
└── features/
    ├── home/              # 首页
    ├── workspace/         # 选文件工作区
    ├── editor/            # 页序预览编辑
    └── docs/              # 说明文档'''),
          ],
        ),
        DocSection(
          title: '核心架构',
          children: [
            DocParagraph('数据流：'),
            DocCodeBlock('''HomePage → WorkspacePage → EditorPage → ExportService
                ↓               ↓
           FileService    PageScheduleBuilder
                ↓               ↓
           PdfLoader         PdfMerger'''),
            DocParagraph('PageScheduleBuilder 页序算法：'),
            DocTable(
              headers: ['模式', '算法'],
              rows: [
                ['alternateMerge', '多源逐页交替（A1,B1,C1,A2,…）'],
                ['appendMerge', '多源顺序拼接（A全部+B全部+…）'],
                ['reverseBMerge', '第二源反转后交替'],
                ['pageEditor', '单源顺序（1,2,3,…）'],
              ],
            ),
          ],
        ),
        DocSection(
          title: '主要依赖',
          children: [
            DocTable(
              headers: ['包', '用途'],
              rows: [
                ['file_picker', '文件选择与保存对话框'],
                ['syncfusion_flutter_pdf', 'PDF 读写与合并'],
                ['pdfx', '页面缩略图渲染'],
                ['reorderable_grid_view', '编辑页网格拖拽排序'],
              ],
            ),
          ],
        ),
        DocSection(
          title: '添加新功能',
          children: [
            DocNumberedList(items: [
              '在 PdfFeatureType 枚举中新增类型',
              '在 pdfFeatures 列表中注册 UI 配置',
              '在 PageScheduleBuilder.build() 中实现页序算法',
              '在 EditorPage 的 suffix 映射中添加导出文件名后缀',
              '更新 docs/ 与 lib/features/docs/ 中的说明内容',
            ]),
          ],
        ),
        DocSection(
          title: '构建发布',
          children: [
            DocCodeBlock('''flutter build macos --release
flutter build windows --release
flutter build web --release'''),
            DocParagraph('产物位于 build/ 目录下对应平台子目录。'),
          ],
        ),
        DocSection(
          title: '已知限制',
          children: [
            DocBulletList(items: [
              'PDF 合并采用逐页复制方式，复杂 PDF 可能与原文件存在细微差异',
              '大文件合并时内存占用随页数增加',
              'Web 平台导出依赖浏览器下载机制',
            ]),
          ],
        ),
      ],
    );
  }
}
