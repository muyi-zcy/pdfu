import '../models/pdf_feature.dart';
import '../pdf/pdf_page_ref.dart';

class SavedRecipePage {
  const SavedRecipePage({
    required this.sourceLabel,
    required this.pageIndex,
    this.rotation = 0,
  });

  final String sourceLabel;
  final int pageIndex;
  final int rotation;

  Map<String, dynamic> toJson() => {
        'sourceLabel': sourceLabel,
        'pageIndex': pageIndex,
        'rotation': rotation,
      };

  factory SavedRecipePage.fromJson(Map<String, dynamic> json) {
    return SavedRecipePage(
      sourceLabel: json['sourceLabel'] as String,
      pageIndex: json['pageIndex'] as int,
      rotation: json['rotation'] as int? ?? 0,
    );
  }

  PdfPageRef toPageRef(String sourceId) {
    return PdfPageRef(
      sourceId: sourceId,
      pageIndex: pageIndex,
      rotation: rotation,
    );
  }
}

class SavedRecipe {
  const SavedRecipe({
    required this.id,
    required this.name,
    required this.featureType,
    required this.createdAt,
    this.schedule = const [],
  });

  final String id;
  final String name;
  final PdfFeatureType featureType;
  final DateTime createdAt;
  final List<SavedRecipePage> schedule;

  bool get hasCustomSchedule => schedule.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'featureType': featureType.name,
        'createdAt': createdAt.toIso8601String(),
        'schedule': schedule.map((page) => page.toJson()).toList(),
      };

  factory SavedRecipe.fromJson(Map<String, dynamic> json) {
    return SavedRecipe(
      id: json['id'] as String,
      name: json['name'] as String,
      featureType: parsePdfFeatureType(json['featureType'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      schedule: (json['schedule'] as List? ?? [])
          .map((item) => SavedRecipePage.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  List<PdfPageRef> resolveSchedule(List<String> sourceLabels) {
    if (schedule.isEmpty) return [];

    final labelToId = {
      for (var i = 0; i < sourceLabels.length; i++) sourceLabels[i]: sourceLabels[i],
    };

    return [
      for (final page in schedule)
        if (labelToId.containsKey(page.sourceLabel))
          page.toPageRef(page.sourceLabel),
    ];
  }
}
