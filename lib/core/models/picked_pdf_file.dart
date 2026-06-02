class PickedPdfFile {
  const PickedPdfFile({
    required this.name,
    required this.path,
    required this.sizeBytes,
  });

  static const blankDocumentName = '未命名文档.pdf';

  factory PickedPdfFile.blank() {
    return const PickedPdfFile(
      name: blankDocumentName,
      path: '',
      sizeBytes: 0,
    );
  }

  bool get isBlank => path.isEmpty;

  final String name;
  final String path;
  final int sizeBytes;

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
