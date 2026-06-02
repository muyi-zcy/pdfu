import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_edit/core/models/picked_pdf_file.dart';
import 'package:pdf_edit/core/pdf/page_schedule.dart';

void main() {
  group('PageScheduleBuilder', () {
    test('buildAlternate interleaves pages', () {
      final schedule = PageScheduleBuilder.buildAlternate('A', 3, 'B', 2);

      expect(
        schedule.map((p) => '${p.sourceId}:${p.pageIndex}').toList(),
        ['A:0', 'B:0', 'A:1', 'B:1', 'A:2'],
      );
    });

    test('buildAlternate with reverseB reverses second source', () {
      final schedule = PageScheduleBuilder.buildAlternate(
        'A',
        2,
        'B',
        3,
        reverseB: true,
      );

      expect(
        schedule.map((p) => '${p.sourceId}:${p.pageIndex}').toList(),
        ['A:0', 'B:2', 'A:1', 'B:1', 'B:0'],
      );
    });

    test('buildAppend concatenates sources', () {
      final schedule = PageScheduleBuilder.buildAppend('A', 2, 'B', 2);

      expect(
        schedule.map((p) => '${p.sourceId}:${p.pageIndex}').toList(),
        ['A:0', 'A:1', 'B:0', 'B:1'],
      );
    });

    test('buildAppendMany concatenates three sources', () {
      final schedule = PageScheduleBuilder.buildAppendMany([
        const PdfLoadedSource(
          id: 'A',
          file: _dummyFile,
          pageCount: 2,
        ),
        const PdfLoadedSource(
          id: 'B',
          file: _dummyFile,
          pageCount: 1,
        ),
        const PdfLoadedSource(
          id: 'C',
          file: _dummyFile,
          pageCount: 2,
        ),
      ]);

      expect(
        schedule.map((p) => '${p.sourceId}:${p.pageIndex}').toList(),
        ['A:0', 'A:1', 'B:0', 'C:0', 'C:1'],
      );
    });

    test('buildAlternateMany interleaves three sources', () {
      final schedule = PageScheduleBuilder.buildAlternateMany([
        const PdfLoadedSource(
          id: 'A',
          file: _dummyFile,
          pageCount: 2,
        ),
        const PdfLoadedSource(
          id: 'B',
          file: _dummyFile,
          pageCount: 2,
        ),
        const PdfLoadedSource(
          id: 'C',
          file: _dummyFile,
          pageCount: 1,
        ),
      ]);

      expect(
        schedule.map((p) => '${p.sourceId}:${p.pageIndex}').toList(),
        ['A:0', 'B:0', 'C:0', 'A:1', 'B:1'],
      );
    });

    test('buildAlternateMany reverses second source only', () {
      final schedule = PageScheduleBuilder.buildAlternateMany(
        [
          const PdfLoadedSource(
            id: 'A',
            file: _dummyFile,
            pageCount: 2,
          ),
          const PdfLoadedSource(
            id: 'B',
            file: _dummyFile,
            pageCount: 2,
          ),
          const PdfLoadedSource(
            id: 'C',
            file: _dummyFile,
            pageCount: 2,
          ),
        ],
        reverseSourceIndex: 1,
      );

      expect(
        schedule.map((p) => '${p.sourceId}:${p.pageIndex}').toList(),
        ['A:0', 'B:1', 'C:0', 'A:1', 'B:0', 'C:1'],
      );
    });
  });
}

const _dummyFile = PickedPdfFile(
  name: 'dummy.pdf',
  path: '/tmp/dummy.pdf',
  sizeBytes: 1,
);
