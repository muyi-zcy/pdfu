import '../models/pdf_feature.dart';
import '../models/picked_pdf_file.dart';
import 'pdf_page_ref.dart';

class PdfLoadedSource {
  const PdfLoadedSource({
    required this.id,
    required this.file,
    required this.pageCount,
  });

  final String id;
  final PickedPdfFile file;
  final int pageCount;
}

class PageScheduleBuilder {
  static List<PdfPageRef> build({
    required PdfFeatureType mode,
    required List<PdfLoadedSource> sources,
  }) {
    if (sources.isEmpty) {
      return [];
    }

    if (sources.length == 1) {
      return buildSequential(sources.first.id, sources.first.pageCount);
    }

    return switch (mode) {
      PdfFeatureType.alternateMerge => buildAlternateMany(sources),
      PdfFeatureType.appendMerge => buildAppendMany(sources),
      PdfFeatureType.reverseBMerge =>
        buildAlternateMany(sources, reverseSourceIndex: 1),
      PdfFeatureType.pdfEditor =>
        buildSequential(sources.first.id, sources.first.pageCount),
    };
  }

  static List<PdfPageRef> buildSequential(String sourceId, int pageCount) {
    return List.generate(
      pageCount,
      (index) => PdfPageRef(sourceId: sourceId, pageIndex: index),
    );
  }

  static List<PdfPageRef> buildAppend(
    String sourceAId,
    int countA,
    String sourceBId,
    int countB,
  ) {
    return [
      ...buildSequential(sourceAId, countA),
      ...buildSequential(sourceBId, countB),
    ];
  }

  static List<PdfPageRef> buildAppendMany(List<PdfLoadedSource> sources) {
    return sources
        .expand((source) => buildSequential(source.id, source.pageCount))
        .toList();
  }

  static List<PdfPageRef> buildAlternateMany(
    List<PdfLoadedSource> sources, {
    int? reverseSourceIndex,
  }) {
    if (sources.length == 2 && reverseSourceIndex == 1) {
      return buildAlternate(
        sources[0].id,
        sources[0].pageCount,
        sources[1].id,
        sources[1].pageCount,
        reverseB: true,
      );
    }

    if (sources.length == 2 && reverseSourceIndex == null) {
      return buildAlternate(
        sources[0].id,
        sources[0].pageCount,
        sources[1].id,
        sources[1].pageCount,
      );
    }

    final schedule = <PdfPageRef>[];
    final maxLen = sources
        .map((source) => source.pageCount)
        .reduce((left, right) => left > right ? left : right);

    for (var pageIndex = 0; pageIndex < maxLen; pageIndex++) {
      for (var sourceIndex = 0; sourceIndex < sources.length; sourceIndex++) {
        final source = sources[sourceIndex];
        if (pageIndex >= source.pageCount) {
          continue;
        }

        final resolvedIndex = reverseSourceIndex == sourceIndex
            ? source.pageCount - 1 - pageIndex
            : pageIndex;
        schedule.add(
          PdfPageRef(sourceId: source.id, pageIndex: resolvedIndex),
        );
      }
    }

    return schedule;
  }

  static List<PdfPageRef> buildAlternate(
    String sourceAId,
    int countA,
    String sourceBId,
    int countB, {
    bool reverseB = false,
  }) {
    final schedule = <PdfPageRef>[];
    final maxLen = countA > countB ? countA : countB;

    for (var i = 0; i < maxLen; i++) {
      if (i < countA) {
        schedule.add(PdfPageRef(sourceId: sourceAId, pageIndex: i));
      }
      if (i < countB) {
        final bIndex = reverseB ? countB - 1 - i : i;
        schedule.add(PdfPageRef(sourceId: sourceBId, pageIndex: bIndex));
      }
    }

    return schedule;
  }
}

String pageRefLabel(PdfPageRef ref) {
  if (ref.isImagePage) {
    return '插入图片';
  }
  return '${ref.sourceId} · 第 ${ref.pageIndex + 1} 页';
}
