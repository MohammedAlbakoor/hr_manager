import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/app_user_session.dart';
import '../../../core/utils/arabic_date_time_formatter.dart';
import '../../common/domain/models/app_user_role.dart';
import '../domain/models/attendance_qr_session.dart';
import '../domain/models/attendance_record.dart';
import '../domain/models/attendance_scan_payload.dart';
import '../domain/repositories/attendance_repository.dart';

class RemoteAttendanceRepository implements AttendanceRepository {
  RemoteAttendanceRepository({
    required this.apiClient,
    required this.sessionController,
  });

  final ApiClient apiClient;
  final AppSessionController sessionController;

  @override
  Future<List<AttendanceRecord>> fetchAttendanceHistory() async {
    final response = await apiClient.get(
      ApiEndpoints.attendanceHistory,
      accessToken: _token,
      handleUnauthorized: true,
    );
    final items = _unwrapList(response);
    return items.map(_mapRecord).toList();
  }

  @override
  Future<AttendanceRecord> scanAttendance(AttendanceScanPayload payload) async {
    final response = await apiClient.post(
      ApiEndpoints.attendanceScan,
      accessToken: _token,
      body: payload.toJson(),
      handleUnauthorized: true,
    );
    return _mapRecord(_unwrapMap(response));
  }

  @override
  Future<AttendanceQrSession> createAttendanceQrSession({
    required AppUserRole role,
    bool refresh = false,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.attendanceQrSession,
      accessToken: _token,
      body: {'role': role.name, 'refresh': refresh},
      handleUnauthorized: true,
    );
    return _mapQrSession(_unwrapMap(response));
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
    throw const ApiException('صيغة بيانات الحضور غير متوقعة.');
  }

  Map<String, dynamic> _unwrapMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      final data = value['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return value;
    }
    throw const ApiException('صيغة بيانات الحضور غير متوقعة.');
  }

  AttendanceRecord _mapRecord(Map<String, dynamic> json) {
    final dateValue = json['date'] ?? json['check_in_time'];
    final note = _string(json['note']);
    return AttendanceRecord(
      id: _string(json['id']) ?? '--',
      dateLabel: ArabicDateTimeFormatter.date(dateValue),
      dayLabel:
          _string(json['day_label']) ??
          ArabicDateTimeFormatter.weekday(dateValue),
      checkInTimeLabel: ArabicDateTimeFormatter.time(
        json['check_in_time'] ?? json['time'],
      ),
      status: _parseStatus(_string(json['status']) ?? 'present'),
      method: _string(json['method']) ?? 'QR',
      locationLabel:
          _string(json['location']) ?? _string(json['location_label']) ?? '--',
      note: _localizedNote(note),
    );
  }

  String _localizedNote(String? note) {
    final value = note?.trim();
    if (value == null || value.isEmpty) {
      return 'لا توجد ملاحظات.';
    }

    final normalized = value.toLowerCase();
    if (normalized.contains('attendance recorded') ||
        normalized.contains('by laravel')) {
      if (normalized.contains('hr')) {
        return 'تم تسجيل الحضور عبر رمز QR صادر من الموارد البشرية.';
      }
      if (normalized.contains('manager')) {
        return 'تم تسجيل الحضور عبر رمز QR صادر من المدير المباشر.';
      }
      return 'تم تسجيل الحضور عبر رمز QR نشط.';
    }

    return value.replaceAll(
      RegExp(r'\s*by\s+Laravel\.?', caseSensitive: false),
      '',
    );
  }

  AttendanceQrSession _mapQrSession(Map<String, dynamic> json) {
    final generatedAt =
        _parseDate(json['generated_at'] ?? json['created_at']) ??
        DateTime.now();
    final expiresAt =
        _parseDate(json['expires_at']) ??
        generatedAt.add(
          Duration(
            seconds: _int(json['expires_in_seconds'] ?? json['ttl'] ?? 30),
          ),
        );
    final payload =
        _string(json['payload']) ??
        _string(json['qr_value']) ??
        _string(json['url']) ??
        _string(json['token']) ??
        '--';

    return AttendanceQrSession(
      id: _string(json['id']) ?? _string(json['token']) ?? '--',
      token: _string(json['token']) ?? '--',
      payload: payload,
      generatedAt: generatedAt,
      expiresAt: expiresAt,
    );
  }

  AttendanceRecordStatus _parseStatus(String status) {
    switch (status) {
      case 'late':
        return AttendanceRecordStatus.late;
      case 'absent':
        return AttendanceRecordStatus.absent;
      default:
        return AttendanceRecordStatus.present;
    }
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

  DateTime? _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
