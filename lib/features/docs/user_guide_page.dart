import 'package:flutter/material.dart';

import 'doc_page.dart';
import 'widgets/doc_section.dart';

class UserGuidePage extends StatelessWidget {
  const UserGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: '使用说明',
      subtitle: '软件功能与操作指南',
      icon: Icons.menu_book_rounded,
      accentColor: const Color(0xFF2563EB),
      sections: const [
        DocSection(
          title: '简介',
          children: [
            DocParagraph(
              'pd斧是一款本地 PDF 处理工具，所有文件均在您的设备上处理，不会上传到任何服务器。',
            ),
            DocParagraph('支持以下功能：'),
            DocBulletList(items: [
              '交叉合并 — 多份 PDF 逐页交替排列（A1, B1, C1, A2 …）',
              '顺序合并 — 多份 PDF 按顺序首尾拼接（A 全部 + B 全部 + …）',
              'B 反向交叉 — 第二份 PDF 页序反转后与其余文档交叉合并',
              '页序编辑 — 单文件内调整页面顺序、删除或旋转页面',
            ]),
          ],
        ),
        DocSection(
          title: '基本流程',
          children: [
            DocNumberedList(items: [
              '在首页选择需要的功能',
              '选择 PDF 文件（合并类功能至少 2 个文件）',
              '点击「继续 · 预览页序」进入编辑界面',
              '预览并调整页序后，点击「导出 PDF」保存结果',
            ]),
          ],
        ),
        DocSection(
          title: '交叉合并',
          children: [
            DocParagraph(
              '适用于双语文档、问答对照等需要逐页交替排版的场景。',
            ),
            DocParagraph(
              '示例：文档 A 有 3 页，文档 B 有 2 页，合并结果为 A1 → B1 → A2 → B2 → A3。',
            ),
            DocNumberedList(items: [
              '依次选择 PDF A、PDF B（可继续添加 C、D …）',
              '可通过拖拽左侧手柄调整各文档的先后顺序',
              '进入预览界面确认页序，必要时可手动微调',
              '导出文件，默认命名为 原文件名-mixed.pdf',
            ]),
          ],
        ),
        DocSection(
          title: '顺序合并',
          children: [
            DocParagraph('适用于将多份独立 PDF 拼接成一份完整文档。'),
            DocParagraph('示例：A（5 页）+ B（3 页）+ C（2 页）= 共 10 页。'),
            DocNumberedList(items: [
              '至少选择 2 个 PDF 文件',
              '拖拽调整文档顺序（先出现的文档页面前置）',
              '预览确认后导出，默认命名为 原文件名-merged.pdf',
            ]),
          ],
        ),
        DocSection(
          title: 'B 反向交叉',
          children: [
            DocParagraph('适用于纠正双面扫描时第二份 PDF 页序颠倒的情况。'),
            DocParagraph(
              '示例：文档 A 正常，文档 B 页序为 B3, B2, B1，合并时 B 会自动反转后再交叉排列。',
            ),
            DocNumberedList(items: [
              '至少选择 2 个 PDF，第二份（PDF B）将被自动反转',
              '其余文档按正常顺序参与交叉合并',
              '导出文件，默认命名为 原文件名-reverse-mixed.pdf',
            ]),
          ],
        ),
        DocSection(
          title: '页序编辑',
          children: [
            DocParagraph('适用于单份 PDF 的页面整理。'),
            DocTable(
              headers: ['操作', '方法'],
              rows: [
                ['选中页面', '点击缩略图'],
                ['调整顺序', '长按拖拽缩略图'],
                ['旋转页面', '选中后点击底部「旋转 90°」按钮'],
                ['删除页面', '选中后点击底部「删除」按钮'],
                ['放大预览', '选中后点击「放大预览」按钮'],
              ],
            ),
            DocParagraph('导出文件默认命名为 原文件名-edited.pdf。'),
          ],
        ),
        DocSection(
          title: '隐私与安全',
          children: [
            DocBulletList(items: [
              '所有 PDF 读取、合并、导出均在本地完成',
              '应用不收集、不上传任何文件内容',
              '导出时由系统文件选择器指定保存位置',
            ]),
          ],
        ),
        DocSection(
          title: '常见问题',
          children: [
            DocParagraph('Q：合并功能最少需要几个文件？'),
            DocParagraph('A：交叉合并、顺序合并、B 反向交叉均至少需要 2 个 PDF 文件。'),
            DocParagraph('Q：可以合并超过 2 个文件吗？'),
            DocParagraph('A：可以。交叉合并和顺序合并支持添加任意数量的 PDF。'),
            DocParagraph('Q：导出后的文件在哪里？'),
            DocParagraph('A：导出时系统会弹出保存对话框，保存成功后界面会提示完整路径。'),
            DocParagraph('Q：旋转页面是永久修改吗？'),
            DocParagraph('A：旋转仅应用于导出的新文件，不会修改原始 PDF。'),
          ],
        ),
      ],
    );
  }
}
