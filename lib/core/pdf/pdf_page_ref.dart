const insertedImageSourceId = '@image';

class PdfPageRef {
  PdfPageRef({
    String? id,
    required this.sourceId,
    required this.pageIndex,
    this.rotation = 0,
    this.imagePath,
  }) : id = id ?? _nextId();

  static int _sequence = 0;
  static String _nextId() => 'page-${_sequence++}';

  final String id;
  final String sourceId;
  final int pageIndex;
  final int rotation;
  final String? imagePath;

  bool get isImagePage => imagePath != null;

  factory PdfPageRef.fromImage(String imagePath, {String? id}) {
    return PdfPageRef(
      id: id,
      sourceId: insertedImageSourceId,
      pageIndex: 0,
      imagePath: imagePath,
    );
  }

  PdfPageRef copyWith({
    String? sourceId,
    int? pageIndex,
    int? rotation,
    String? imagePath,
  }) {
    return PdfPageRef(
      id: id,
      sourceId: sourceId ?? this.sourceId,
      pageIndex: pageIndex ?? this.pageIndex,
      rotation: rotation ?? this.rotation,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PdfPageRef &&
        other.id == id &&
        other.sourceId == sourceId &&
        other.pageIndex == pageIndex &&
        other.rotation == rotation &&
        other.imagePath == imagePath;
  }

  @override
  int get hashCode =>
      Object.hash(id, sourceId, pageIndex, rotation, imagePath);
}
