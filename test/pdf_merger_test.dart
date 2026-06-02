import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:pdf_edit/core/models/pdf_feature.dart';
import 'package:pdf_edit/core/models/picked_pdf_file.dart';
import 'package:pdf_edit/core/pdf/page_schedule.dart';
import 'package:pdf_edit/core/pdf/page_image_utils.dart';
import 'package:pdf_edit/core/pdf/pdf_merger.dart';
import 'package:pdf_edit/core/pdf/pdf_page_ref.dart';

Future<File> _createSamplePdf(String name) async {
  final document = PdfDocument();
  document.pages.add().graphics.drawString(
        'Sample page for $name',
        PdfStandardFont(PdfFontFamily.helvetica, 18),
        bounds: const Rect.fromLTWH(72, 72, 400, 40),
      );
  final bytes = Uint8List.fromList(document.saveSync());
  document.dispose();

  final file = File('${Directory.systemTemp.path}/$name.pdf');
  await file.writeAsBytes(bytes);
  return file;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PdfMerger renders single and merged PDFs', () async {
    final fileA = await _createSamplePdf('merge-a');
    final fileB = await _createSamplePdf('merge-b');

    final pickedA = PickedPdfFile(
      name: 'merge-a.pdf',
      path: fileA.path,
      sizeBytes: await fileA.length(),
    );
    final pickedB = PickedPdfFile(
      name: 'merge-b.pdf',
      path: fileB.path,
      sizeBytes: await fileB.length(),
    );

    final loader = PdfLoader();
    final merger = PdfMerger();

    final singleSources = await loader.loadSources([pickedA]);
    final singleSchedule = <PdfPageRef>[
      PdfPageRef(sourceId: 'doc', pageIndex: 0),
    ];
    final singleBytes = await merger.render(
      sources: singleSources,
      schedule: singleSchedule,
    );
    expect(singleBytes.length, greaterThan(100));

    final mergeSources = await loader.loadSources([pickedA, pickedB]);
    final mergeSchedule = PageScheduleBuilder.build(
      mode: PdfFeatureType.alternateMerge,
      sources: mergeSources,
    );
    final mergedBytes = await merger.render(
      sources: mergeSources,
      schedule: mergeSchedule,
    );
    expect(mergedBytes.length, greaterThan(100));

    final outputDoc = PdfDocument(inputBytes: mergedBytes);
    expect(outputDoc.pages.count, 2);
    outputDoc.dispose();
  });

  test('rotated export page swaps dimensions', () async {
    final file = await _createSamplePdf('rotate-test');
    final picked = PickedPdfFile(
      name: 'rotate-test.pdf',
      path: file.path,
      sizeBytes: await file.length(),
    );

    final loader = PdfLoader();
    final merger = PdfMerger();
    final sources = await loader.loadSources([picked]);

    final sourceDoc = PdfDocument(
      inputBytes: await file.readAsBytes(),
    );
    final sourceSize = sourceDoc.pages[0].size;
    sourceDoc.dispose();

    final schedule = <PdfPageRef>[
      PdfPageRef(sourceId: 'doc', pageIndex: 0, rotation: 90),
    ];

    final bytes = await merger.render(
      sources: sources,
      schedule: schedule,
    );

    final outputDoc = PdfDocument(inputBytes: bytes);
    final outputSize = outputDoc.pages[0].size;
    outputDoc.dispose();

    expect(outputSize.width, closeTo(sourceSize.height, 2));
    expect(outputSize.height, closeTo(sourceSize.width, 2));
  });

  test('thumbnailFrameSize swaps dimensions when rotated', () {
    const visualSize = Size(100, 141.4);
    const slotWidth = 100.0;
    final portrait = thumbnailFrameSize(visualSize, 0, slotWidth);
    final landscape = thumbnailFrameSize(visualSize, 90, slotWidth);

    expect(portrait.width, slotWidth);
    expect(landscape.width, slotWidth);
    expect(landscape.height, lessThan(portrait.height));
  });
}
