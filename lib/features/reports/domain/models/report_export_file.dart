import 'dart:typed_data';

class ReportExportFile {
  const ReportExportFile({
    required this.fileName,
    required this.bytes,
    this.mimeType = 'text/csv',
  });

  final String fileName;
  final Uint8List bytes;
  final String mimeType;
}
