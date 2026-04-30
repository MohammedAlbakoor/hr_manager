import 'dart:convert';
import 'dart:typed_data';

import '../domain/models/report_export_file.dart';
import '../domain/models/report_export_filter.dart';
import '../domain/models/report_table_models.dart';
import '../domain/repositories/report_repository.dart';

class MockReportRepository implements ReportRepository {
  @override
  Future<List<ReportTableRow>> fetchAttendanceReportRows(
    ReportExportFilter filter,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));

    return [
      ReportTableRow(
        id: 'attendance-1',
        cells: {
          'date': ReportTableCell(
            value: _formatDate(filter.dateTo),
            sortValue: filter.dateTo,
          ),
          'employee_code': const ReportTableCell(value: 'EMP-014'),
          'employee_name': const ReportTableCell(value: 'أحمد خالد'),
          'department': const ReportTableCell(value: 'المبيعات'),
          'manager_name': const ReportTableCell(value: 'محمد العتيبي'),
          'status_label': const ReportTableCell(
            value: 'حاضر',
            sortValue: 'present',
          ),
          'check_in_label': const ReportTableCell(value: '08:05'),
          'method': const ReportTableCell(value: 'QR'),
          'location_label': const ReportTableCell(value: 'Main Office'),
          'note': const ReportTableCell(value: 'Attendance preview row'),
        },
      ),
    ];
  }

  @override
  Future<List<ReportTableRow>> fetchLeaveReportRows(
    ReportExportFilter filter,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));

    return [
      ReportTableRow(
        id: 'leave-1',
        cells: {
          'request_date': ReportTableCell(
            value: _formatDate(filter.dateTo),
            sortValue: filter.dateTo,
          ),
          'employee_code': const ReportTableCell(value: 'EMP-014'),
          'employee_name': const ReportTableCell(value: 'أحمد خالد'),
          'department': const ReportTableCell(value: 'المبيعات'),
          'manager_name': const ReportTableCell(value: 'محمد العتيبي'),
          'leave_type_name': const ReportTableCell(value: 'إجازة سنوية'),
          'start_date': ReportTableCell(
            value: _formatDate(filter.dateFrom),
            sortValue: filter.dateFrom,
          ),
          'end_date': ReportTableCell(
            value: _formatDate(filter.dateTo),
            sortValue: filter.dateTo,
          ),
          'days_count': const ReportTableCell(value: '3', sortValue: 3),
          'status_label': const ReportTableCell(
            value: 'معتمد',
            sortValue: 'approved',
          ),
          'manager_status_label': const ReportTableCell(
            value: 'موافق',
            sortValue: 'approved',
          ),
          'manager_note': const ReportTableCell(value: '--'),
          'hr_note': const ReportTableCell(value: '--'),
          'current_balance': const ReportTableCell(
            value: '21.5',
            sortValue: 21.5,
          ),
          'remaining_balance': const ReportTableCell(
            value: '18.5',
            sortValue: 18.5,
          ),
          'note': const ReportTableCell(value: 'Preview leave row'),
        },
      ),
    ];
  }

  @override
  Future<ReportExportFile> exportAttendanceReport(
    ReportExportFilter filter,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));

    final csv = StringBuffer()
      ..writeln('التاريخ,رمز الموظف,اسم الموظف,القسم,المدير المباشر,الحالة')
      ..writeln(
        '${_formatDate(filter.dateTo)},EMP-014,أحمد خالد,المبيعات,محمد العتيبي,حاضر',
      );

    return ReportExportFile(
      fileName:
          'attendance_${_formatDate(filter.dateFrom)}_to_${_formatDate(filter.dateTo)}.csv',
      bytes: Uint8List.fromList(utf8.encode('\uFEFF${csv.toString()}')),
    );
  }

  @override
  Future<ReportExportFile> exportLeaveReport(ReportExportFilter filter) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));

    final csv = StringBuffer()
      ..writeln('تاريخ الطلب,رمز الموظف,اسم الموظف,نوع الإجازة,الحالة')
      ..writeln(
        '${_formatDate(filter.dateTo)},EMP-014,أحمد خالد,إجازة سنوية,معتمد',
      );

    return ReportExportFile(
      fileName:
          'leaves_${_formatDate(filter.dateFrom)}_to_${_formatDate(filter.dateTo)}.csv',
      bytes: Uint8List.fromList(utf8.encode('\uFEFF${csv.toString()}')),
    );
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
