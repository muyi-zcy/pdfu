# pd斧

<p align="center">
  <img src="logo.png" alt="pd斧" width="120" height="120" />
</p>

**pd斧** 是一款基于 Flutter 的本地 PDF 桌面工具。所有处理均在设备上完成，不上传文件、不依赖网络。

## 功能

| 功能 | 说明 |
|------|------|
| 交叉合并 | 多份 PDF 逐页交替（A1, B1, C1, A2 …） |
| 顺序合并 | 多份 PDF 按顺序首尾拼接 |
| B 反向交叉 | 第二份 PDF 页序反转后与其余文档交叉合并 |
| PDF 编辑 | 调整页序、插入图片、导出为 PNG/JPEG |

## 环境要求

- Flutter SDK ≥ 3.11.5
- Dart SDK ^3.11.5
- macOS：Xcode（构建 macOS 版本时）
- Windows / Linux：对应平台构建工具链

## 快速开始

```bash
git clone <仓库地址>
cd pdf-edit
flutter pub get
```

### 运行

```bash
flutter run -d macos    # macOS
flutter run -d windows  # Windows
flutter run -d linux    # Linux
```

### 构建发布版

```bash
flutter build macos
flutter build windows
flutter build linux
```

macOS 产物位于 `build/macos/Build/Products/Release/pd斧.app`。

## 项目结构

```
lib/
├── main.dart              # 入口
├── app.dart               # 主题与根路由
├── core/
│   ├── app_branding.dart  # 应用名称与 Logo
│   ├── models/            # 数据模型
│   ├── pdf/               # PDF 合并与导出
│   └── platform/          # 文件选择与系统交互
└── features/
    ├── home/              # 首页
    ├── workspace/         # 选文件工作区
    ├── editor/            # 页序预览与编辑
    ├── settings/          # 偏好设置
    └── docs/              # 内置使用说明
```

## 品牌资源

- 应用 Logo：`logo.png` / `assets/logo.png`
- macOS 应用图标：由 `logo.png` 生成，位于 `macos/Runner/Assets.xcassets/AppIcon.appiconset/`

## 隐私

- 文件读取、合并、导出均在本地完成
- 不收集、不上传任何 PDF 内容

## 许可证

请参阅项目仓库中的许可证文件（如有）。
