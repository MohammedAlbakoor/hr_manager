import '../models/report_export_file.dart';
import '../models/report_export_filter.dart';
import '../models/report_table_models.dart';

abstract class ReportRepository {
  Future<List<ReportTableRow>> fetchAttendanceReportRows(
    ReportExportFilter filter,
  );

  Future<List<ReportTableRow>> fetchLeaveReportRows(ReportExportFilter filter);

  Future<ReportExportFile> exportAttendanceReport(ReportExportFilter filter);

  Future<ReportExportFile> exportLeaveReport(ReportExportFilter filter);
}
