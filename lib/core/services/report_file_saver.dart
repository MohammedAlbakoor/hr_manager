import 'package:file_saver/file_saver.dart';

import '../../features/reports/domain/models/report_export_file.dart';

class ReportFileSaver {
  const ReportFileSaver();

  Future<void> save(ReportExportFile file) async {
    final segments = file.fileName.split('.');
    final extension = segments.length > 1 ? segments.last : 'csv';
    final name = segments.length > 1
        ? segments.sublist(0, segments.length - 1).join('.')
        : file.fileName;

    await FileSaver.instance.saveFile(
      name: name,
      bytes: file.bytes,
      fileExtension: extension,
      mimeType: MimeType.custom,
      customMimeType: _normalizeMimeType(file.mimeType),
    );
  }

  String _normalizeMimeType(String value) {
    final mimeType = value.split(';').first.trim();
    return mimeType.isEmpty ? 'text/csv' : mimeType;
  }
}
