import 'dart:convert';
import 'dart:typed_data';

import '../../features/reports/domain/models/report_export_file.dart';
import '../../features/reports/domain/models/report_export_filter.dart';
import '../../features/reports/domain/models/report_table_models.dart';

class ReportTableExportBuilder {
  const ReportTableExportBuilder();

  ReportExportFile buildCsv({
    required ReportTableType type,
    required ReportExportFilter filter,
    required List<ReportTableColumn> columns,
    required List<ReportTableRow> rows,
  }) {
    final visibleColumns = columns.where((column) => column.isVisible).toList();
    final csv = StringBuffer()
      ..write('\uFEFF')
      ..writeln(
        visibleColumns.map((column) => _escape(column.label)).join(','),
      );

    for (final row in rows) {
      csv.writeln(
        visibleColumns
            .map((column) => _escape(row.valueFor(column.id)))
            .join(','),
      );
    }

    return ReportExportFile(
      fileName: _fileName(type, filter),
      bytes: Uint8List.fromList(utf8.encode(csv.toString())),
      mimeType: 'text/csv',
    );
  }

  String _fileName(ReportTableType type, ReportExportFilter filter) {
    final queryParameters = filter.toQueryParameters();
    final dateFrom = queryParameters['date_from'] ?? 'from';
    final dateTo = queryParameters['date_to'] ?? 'to';
    return '${type.exportPrefix}_${dateFrom}_to_$dateTo.csv';
  }

  String _escape(String value) {
    final normalized = value.replaceAll('"', '""');
    final shouldQuote =
        normalized.contains(',') ||
        normalized.contains('"') ||
        normalized.contains('\n');
    return shouldQuote ? '"$normalized"' : normalized;
  }
}
