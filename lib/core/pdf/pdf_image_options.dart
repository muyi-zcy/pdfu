enum PdfImageFormat {
  png,
  jpeg,
}

enum PdfImageScale {
  preview,
  standard,
  high,
}

extension PdfImageFormatX on PdfImageFormat {
  String get extension => this == PdfImageFormat.png ? 'png' : 'jpg';

  String get label => this == PdfImageFormat.png ? 'PNG' : 'JPEG';
}

extension PdfImageScaleX on PdfImageScale {
  String get label => switch (this) {
        PdfImageScale.preview => '预览（约 72 DPI）',
        PdfImageScale.standard => '标准（约 150 DPI）',
        PdfImageScale.high => '高清（约 300 DPI）',
      };

  double get dpiFactor => switch (this) {
        PdfImageScale.preview => 1.0,
        PdfImageScale.standard => 150 / 72,
        PdfImageScale.high => 300 / 72,
      };
}
