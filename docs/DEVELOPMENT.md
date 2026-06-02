# PDF 编辑 · 开发说明

## 项目概述

PDF 编辑（`pdf_edit`）是基于 Flutter 的跨平台桌面/Web 应用，提供 PDF 交叉合并、顺序合并、反向交叉合并及页序编辑能力。核心设计原则：**本地处理、无网络依赖**。

## 环境要求

| 项目 | 版本 |
|------|------|
| Flutter SDK | ≥ 3.11.5 |
| Dart SDK | ^3.11.5 |

推荐 IDE：VS Code / Android Studio，并安装 Flutter 与 Dart 插件。

## 快速开始

```bash
# 克隆项目后进入目录
cd pdf-edit

# 安装依赖
flutter pub get

# 运行（以 macOS 为例）
flutter run -d macos

# 其他平台
flutter run -d windows
flutter run -d linux
flutter run -d chrome
```

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── app.dart                  # MaterialApp 主题与路由
├── core/
│   ├── models/
│   │   ├── pdf_feature.dart      # 功能定义与配置
│   │   └── picked_pdf_file.dart  # 已选文件模型
│   ├── pdf/
│   │   ├── page_schedule.dart    # 页序调度算法
│   │   ├── pdf_merger.dart       # PDF 加载与渲染合并
│   │   ├── pdf_page_ref.dart     # 页面引用（来源 + 索引 + 旋转）
│   │   ├── pdf_thumbnail_service.dart
│   │   ├── page_image_utils.dart
│   │   └── source_utils.dart     # 来源标签与配色
│   └── platform/
│       ├── file_service.dart     # 文件选择
│       ├── export_service.dart   # 导出保存
│       └── export_io.dart        # 平台 IO 实现
└── features/
    ├── home/                 # 首页功能菜单
    ├── workspace/            # 选文件工作区
    ├── editor/               # 页序预览与编辑
    └── docs/                 # 说明文档页面
```

## 核心架构

### 数据流

```
HomePage → WorkspacePage → EditorPage → ExportService
                ↓               ↓
           FileService    PageScheduleBuilder
                ↓               ↓
           PdfLoader         PdfMerger
```

1. **HomePage**：展示功能列表，用户选择合并/编辑模式
2. **WorkspacePage**：通过 `FileService` 选取 PDF，可调整文件顺序
3. **EditorPage**：`PageScheduleBuilder` 生成初始页序，用户拖拽/旋转/删除后由 `PdfMerger` 渲染导出

### 页序模型

`PdfPageRef` 表示输出序列中的单页：

```dart
PdfPageRef(
  sourceId: 'A',      // 来源文档标识
  pageIndex: 0,       // 源文档中的页码（0-based）
  rotation: 0,        // 旋转角度（0/90/180/270）
)
```

`PageScheduleBuilder` 根据 `PdfFeatureType` 生成初始调度：

| 模式 | 算法 |
|------|------|
| `alternateMerge` | 多源逐页交替（A1,B1,C1,A2,…） |
| `appendMerge` | 多源顺序拼接（A全部+B全部+…） |
| `reverseBMerge` | 第二源反转后交替 |
| `pageEditor` | 单源顺序（1,2,3,…） |

### PDF 处理

- **读取页数**：Syncfusion `PdfDocument`
- **缩略图渲染**：pdfx
- **合并导出**：Syncfusion 创建新文档，按 `schedule` 逐页复制并应用旋转

## 主要依赖

| 包 | 用途 |
|----|------|
| `file_picker` | 文件选择与保存对话框 |
| `syncfusion_flutter_pdf` | PDF 读写与合并 |
| `pdfx` | 页面缩略图渲染 |
| `reorderable_grid_view` | 编辑页网格拖拽排序 |

## 添加新功能

1. 在 `PdfFeatureType` 枚举中新增类型
2. 在 `pdfFeatures` 列表中注册 UI 配置（标题、图标、文件数量限制等）
3. 在 `PageScheduleBuilder.build()` 的 `switch` 中实现页序算法
4. 在 `EditorPage._exportPdf()` 的 `suffix` 映射中添加导出文件名后缀
5. 更新 `docs/USER_GUIDE.md` 与 `lib/features/docs/` 中的说明内容

## 构建发布

```bash
# macOS
flutter build macos --release

# Windows
flutter build windows --release

# Web
flutter build web --release
```

产物位于 `build/` 目录下对应平台子目录。

## 代码规范

- 遵循 `flutter_lints` 规则（见 `analysis_options.yaml`）
- UI 文案使用中文
- 新功能保持 `features/` 按页面拆分、`core/` 放可复用逻辑的分层习惯
- 平台差异通过 `export_io.dart` / `export_io_stub.dart` 条件导入隔离

## 已知限制

- PDF 合并采用逐页复制方式，复杂 PDF（嵌入字体、特殊注释）可能与原文件存在细微差异
- 大文件合并时内存占用随页数增加，建议分批处理超大文档
- Web 平台导出依赖浏览器下载机制，路径提示与桌面端不同

## 相关文档

- [软件使用说明](./USER_GUIDE.md)
- [Flutter 官方文档](https://docs.flutter.dev/)
