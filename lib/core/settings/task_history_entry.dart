import '../models/pdf_feature.dart';

class TaskHistoryEntry {
  const TaskHistoryEntry({
    required this.id,
    required this.featureType,
    required this.filePaths,
    required this.fileNames,
    required this.lastUsedAt,
    this.outputPageCount,
  });

  final String id;
  final PdfFeatureType featureType;
  final List<String> filePaths;
  final List<String> fileNames;
  final DateTime lastUsedAt;
  final int? outputPageCount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'featureType': featureType.name,
        'filePaths': filePaths,
        'fileNames': fileNames,
        'lastUsedAt': lastUsedAt.toIso8601String(),
        if (outputPageCount != null) 'outputPageCount': outputPageCount,
      };

  factory TaskHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TaskHistoryEntry(
      id: json['id'] as String,
      featureType: parsePdfFeatureType(json['featureType'] as String),
      filePaths: (json['filePaths'] as List).cast<String>(),
      fileNames: (json['fileNames'] as List).cast<String>(),
      lastUsedAt: DateTime.parse(json['lastUsedAt'] as String),
      outputPageCount: json['outputPageCount'] as int?,
    );
  }

  String get fileSummary {
    if (fileNames.isEmpty) return '';
    if (fileNames.length == 1) return fileNames.first;
    return '${fileNames.first} 等 ${fileNames.length} 个文件';
  }
}
