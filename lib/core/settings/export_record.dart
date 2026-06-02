import 'package:path/path.dart' as p;

import '../models/pdf_feature.dart';

class ExportRecord {
  const ExportRecord({
    required this.id,
    required this.featureType,
    required this.outputPath,
    required this.exportedAt,
    required this.pageCount,
  });

  final String id;
  final PdfFeatureType featureType;
  final String outputPath;
  final DateTime exportedAt;
  final int pageCount;

  String get fileName => p.basename(outputPath);

  Map<String, dynamic> toJson() => {
        'id': id,
        'featureType': featureType.name,
        'outputPath': outputPath,
        'exportedAt': exportedAt.toIso8601String(),
        'pageCount': pageCount,
      };

  factory ExportRecord.fromJson(Map<String, dynamic> json) {
    return ExportRecord(
      id: json['id'] as String,
      featureType: parsePdfFeatureType(json['featureType'] as String),
      outputPath: json['outputPath'] as String,
      exportedAt: DateTime.parse(json['exportedAt'] as String),
      pageCount: json['pageCount'] as int,
    );
  }
}
