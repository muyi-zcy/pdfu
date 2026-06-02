import 'package:flutter_test/flutter_test.dart';

import 'package:pdf_edit/app.dart';

void main() {
  testWidgets('首页展示功能选择菜单', (WidgetTester tester) async {
    await tester.pumpWidget(const PdfEditApp());

    expect(find.text('功能'), findsOneWidget);
    expect(find.text('交叉合并'), findsOneWidget);
    expect(find.text('顺序合并'), findsOneWidget);
    expect(find.text('B 反向交叉'), findsOneWidget);
    expect(find.text('页序编辑'), findsOneWidget);
  });
}
