import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/app_user_session.dart';
import '../domain/models/report_export_file.dart';
import '../domain/models/report_export_filter.dart';
import '../domain/models/report_table_models.dart';
import '../domain/repositories/report_repository.dart';
import '../../../core/utils/arabic_date_time_formatter.dart';

class RemoteReportRepository implements ReportRepository {
  RemoteReportRepository({
    required this.apiClient,
    required this.sessionController,
  });

  final ApiClient apiClient;
  final AppSessionController sessionController;

  @override
  Future<List<ReportTableRow>> fetchAttendanceReportRows(
    ReportExportFilter filter,
  ) async {
    final response = await apiClient.get(
      ApiEndpoints.attendanceReportRows,
      accessToken: _token,
      queryParameters: filter.toQueryParameters(),
      handleUnauthorized: true,
    );

    return _unwrapList(response).map(_mapAttendanceRow).toList();
  }

  @override
  Future<List<ReportTableRow>> fetchLeaveReportRows(
    ReportExportFilter filter,
  ) async {
    final response = await apiClient.get(
      ApiEndpoints.leaveReportRows,
      accessToken: _token,
      queryParameters: filter.toQueryParameters(),
      handleUnauthorized: true,
    );

    return _unwrapList(response).map(_mapLeaveRow).toList();
  }

  @override
  Future<ReportExportFile> exportAttendanceReport(
    ReportExportFilter filter,
  ) async {
    final response = await apiClient.getBytes(
      ApiEndpoints.attendanceReportExport,
      accessToken: _token,
      queryParameters: filter.toQueryParameters(),
      handleUnauthorized: true,
    );

    return ReportExportFile(
      fileName: response.fileName ?? _defaultFileName('attendance', filter),
      bytes: response.bytes,
      mimeType: _normalizeMimeType(response.contentType),
    );
  }

  @override
  Future<ReportExportFile> exportLeaveReport(ReportExportFilter filter) async {
    final response = await apiClient.getBytes(
      ApiEndpoints.leaveReportExport,
      accessToken: _token,
      queryParameters: filter.toQueryParameters(),
      handleUnauthorized: true,
    );

    return ReportExportFile(
      fileName: response.fileName ?? _defaultFileName('leaves', filter),
      bytes: response.bytes,
      mimeType: _normalizeMimeType(response.contentType),
    );
  }

  String get _token {
    final token = sessionController.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw const ApiException('لا توجد جلسة دخول نشطة لتنفيذ العملية.');
    }
    return token;
  }

  List<Map<String, dynamic>> _unwrapList(dynamic value) {
    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList();
    }
    if (value is Map<String, dynamic>) {
      final data = value['data'] ?? value['items'];
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
    }
    throw const ApiException('صيغة بيانات التقارير غير متوقعة.');
  }

  String _defaultFileName(String prefix, ReportExportFilter filter) {
    final queryParameters = filter.toQueryParameters();
    final dateFrom = queryParameters['date_from'] ?? 'from';
    final dateTo = queryParameters['date_to'] ?? 'to';
    return '${prefix}_${dateFrom}_to_$dateTo.csv';
  }

  String _normalizeMimeType(String? value) {
    final mimeType = value?.split(';').first.trim();
    return mimeType == null || mimeType.isEmpty ? 'text/csv' : mimeType;
  }

  ReportTableRow _mapAttendanceRow(Map<String, dynamic> json) {
    return ReportTableRow(
      id: _string(json['id']) ?? '--',
      cells: {
        'date': ReportTableCell(
          value: ArabicDateTimeFormatter.date(json['date']),
          sortValue: _dateSortValue(json['date']),
        ),
        'employee_code': ReportTableCell(
          value: _string(json['employee_code']) ?? '--',
        ),
        'employee_name': ReportTableCell(
          value: _string(json['employee_name']) ?? '--',
        ),
        'department': ReportTableCell(
          value: _string(json['department']) ?? '--',
        ),
        'manager_name': ReportTableCell(
          value: _string(json['manager_name']) ?? '--',
        ),
        'status_label': ReportTableCell(
          value: _string(json['status_label']) ?? '--',
          sortValue: _string(json['status']) ?? '',
        ),
        'check_in_label': ReportTableCell(
          value: _string(json['check_in_label']) ?? '--',
          sortValue: _dateSortValue(json['check_in_time']),
        ),
        'method': ReportTableCell(value: _string(json['method']) ?? '--'),
        'location_label': ReportTableCell(
          value: _string(json['location_label']) ?? '--',
        ),
        'note': ReportTableCell(value: _string(json['note']) ?? '--'),
      },
    );
  }

  ReportTableRow _mapLeaveRow(Map<String, dynamic> json) {
    final currentBalance = _double(json['current_balance']);
    final remainingBalance = _double(json['remaining_balance']);

    return ReportTableRow(
      id: _string(json['id']) ?? '--',
      cells: {
        'request_date': ReportTableCell(
          value: ArabicDateTimeFormatter.date(json['request_date']),
          sortValue: _dateSortValue(json['request_date']),
        ),
        'employee_code': ReportTableCell(
          value: _string(json['employee_code']) ?? '--',
        ),
        'employee_name': ReportTableCell(
          value: _string(json['employee_name']) ?? '--',
        ),
        'department': ReportTableCell(
          value: _string(json['department']) ?? '--',
        ),
        'manager_name': ReportTableCell(
          value: _string(json['manager_name']) ?? '--',
        ),
        'leave_type_name': ReportTableCell(
          value: _string(json['leave_type_name']) ?? '--',
        ),
        'start_date': ReportTableCell(
          value: ArabicDateTimeFormatter.date(json['start_date']),
          sortValue: _dateSortValue(json['start_date']),
        ),
        'end_date': ReportTableCell(
          value: ArabicDateTimeFormatter.date(json['end_date']),
          sortValue: _dateSortValue(json['end_date']),
        ),
        'days_count': ReportTableCell(
          value: '${_int(json['days_count'])}',
          sortValue: _int(json['days_count']),
        ),
        'status_label': ReportTableCell(
          value: _string(json['status_label']) ?? '--',
          sortValue: _string(json['status']) ?? '',
        ),
        'manager_status_label': ReportTableCell(
          value: _string(json['manager_status_label']) ?? '--',
          sortValue: _string(json['manager_status']) ?? '',
        ),
        'manager_note': ReportTableCell(
          value: _string(json['manager_note']) ?? '--',
        ),
        'hr_note': ReportTableCell(value: _string(json['hr_note']) ?? '--'),
        'current_balance': ReportTableCell(
          value: currentBalance.toStringAsFixed(1),
          sortValue: currentBalance,
        ),
        'remaining_balance': ReportTableCell(
          value: remainingBalance.toStringAsFixed(1),
          sortValue: remainingBalance,
        ),
        'note': ReportTableCell(value: _string(json['note']) ?? '--'),
      },
    );
  }

  String? _string(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  int _int(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _double(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Object _dateSortValue(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed ?? (value?.toString() ?? '');
  }
}
