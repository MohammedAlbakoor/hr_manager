import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/app_user_session.dart';
import '../../../core/utils/arabic_date_time_formatter.dart';
import '../../hr/domain/models/hr_leave_request.dart';
import '../../manager/domain/models/manager_leave_request.dart';
import '../domain/models/create_leave_request_payload.dart';
import '../domain/models/employee_leave_request.dart';
import '../domain/repositories/leave_repository.dart';

class RemoteLeaveRepository implements LeaveRepository {
  RemoteLeaveRepository({
    required this.apiClient,
    required this.sessionController,
  });

  final ApiClient apiClient;
  final AppSessionController sessionController;

  @override
  Future<List<EmployeeLeaveRequest>> fetchEmployeeLeaveHistory() async {
    final response = await apiClient.get(
      ApiEndpoints.leaves,
      accessToken: _token,
      handleUnauthorized: true,
    );
    return _unwrapList(response).map(_mapEmployeeRequest).toList();
  }

  @override
  Future<EmployeeLeaveRequest> createLeaveRequest(
    CreateLeaveRequestPayload payload,
  ) async {
    final response = await apiClient.post(
      ApiEndpoints.leaves,
      accessToken: _token,
      body: payload.toJson(),
      handleUnauthorized: true,
    );
    return _mapEmployeeRequest(_unwrapMap(response));
  }

  @override
  Future<List<ManagerLeaveRequest>> fetchManagerLeaveRequests() async {
    final response = await apiClient.get(
      ApiEndpoints.managerLeaves,
      accessToken: _token,
      handleUnauthorized: true,
    );
    return _unwrapList(response).map(_mapManagerRequest).toList();
  }

  @override
  Future<ManagerLeaveRequest> submitManagerDecision({
    required String leaveId,
    required bool approve,
    String? note,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.leaveDecision(leaveId),
      accessToken: _token,
      body: {'decision': approve ? 'approve' : 'reject', 'note': note},
      handleUnauthorized: true,
    );
    return _mapManagerRequest(_unwrapMap(response));
  }

  @override
  Future<List<HrLeaveRequest>> fetchHrLeaveRequests() async {
    final response = await apiClient.get(
      ApiEndpoints.hrLeaves,
      accessToken: _token,
      handleUnauthorized: true,
    );
    return _unwrapList(response).map(_mapHrRequest).toList();
  }

  @override
  Future<HrLeaveRequest> submitHrDecision({
    required String leaveId,
    required bool approve,
    String? note,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.leaveDecision(leaveId),
      accessToken: _token,
      body: {'decision': approve ? 'approve' : 'reject', 'note': note},
      handleUnauthorized: true,
    );
    return _mapHrRequest(_unwrapMap(response));
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
      return [value];
    }
    throw const ApiException('صيغة بيانات الإجازات غير متوقعة.');
  }

  Map<String, dynamic> _unwrapMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      final data = value['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return value;
    }
    throw const ApiException('صيغة بيانات الإجازات غير متوقعة.');
  }

  EmployeeLeaveRequest _mapEmployeeRequest(Map<String, dynamic> json) {
    final status = _parseEmployeeStatus(_string(json['status']) ?? 'pending');
    final managerStatus = _parseApprovalStatus(
      _string(json['manager_status']) ??
          _managerStatusFromOverall(json['status']),
    );
    final hrStatus = _parseApprovalStatus(
      _string(json['hr_status']) ?? _hrStatusFromOverall(json['status']),
    );
    final leaveTypeName = _leaveTypeName(json);
    final currentBalance = _decimalLabel(
      json['current_balance'] ?? json['balance_days'] ?? 0,
    );
    final remainingBalance = _decimalLabel(
      json['remaining_balance'] ?? json['remaining_balance_days'] ?? 0,
    );

    return EmployeeLeaveRequest(
      id: _string(json['id']) ?? '--',
      title: leaveTypeName,
      type: leaveTypeName,
      periodLabel:
          '${ArabicDateTimeFormatter.date(json['start_date'])} - ${ArabicDateTimeFormatter.date(json['end_date'])}',
      daysCount: _int(json['days_count']),
      status: status,
      note: _string(json['note']) ?? 'لا توجد ملاحظات.',
      requestedAtLabel: ArabicDateTimeFormatter.dateTime(
        json['created_at'] ?? json['submitted_at'],
      ),
      startDateLabel: ArabicDateTimeFormatter.date(json['start_date']),
      endDateLabel: ArabicDateTimeFormatter.date(json['end_date']),
      currentBalanceLabel: currentBalance,
      remainingBalanceLabel: remainingBalance,
      managerStatus: managerStatus,
      hrStatus: hrStatus,
      managerNote: _string(json['manager_note']) ?? 'لا توجد ملاحظة من المدير.',
      hrNote: _string(json['hr_note']) ?? 'لا توجد ملاحظة من الموارد البشرية.',
    );
  }

  ManagerLeaveRequest _mapManagerRequest(Map<String, dynamic> json) {
    return ManagerLeaveRequest(
      id: _string(json['id']) ?? '--',
      employeeName:
          _string(json['employee_name']) ??
          _string(_nested(json, ['user', 'name'])) ??
          'موظف',
      employeeCode:
          _string(json['employee_code']) ??
          _string(_nested(json, ['user', 'code'])) ??
          '--',
      department:
          _string(json['department']) ??
          _string(_nested(json, ['user', 'department'])) ??
          '--',
      leaveType: _leaveTypeName(json),
      periodLabel:
          '${ArabicDateTimeFormatter.date(json['start_date'])} - ${ArabicDateTimeFormatter.date(json['end_date'])}',
      startDateLabel: ArabicDateTimeFormatter.date(json['start_date']),
      endDateLabel: ArabicDateTimeFormatter.date(json['end_date']),
      daysCount: _int(json['days_count']),
      submittedAtLabel: ArabicDateTimeFormatter.dateTime(
        json['created_at'] ?? json['submitted_at'],
      ),
      employeeNote: _string(json['note']) ?? 'لا توجد ملاحظات.',
      currentBalanceLabel: _decimalLabel(
        json['current_balance'] ?? json['balance_days'] ?? 0,
      ),
      remainingBalanceLabel: _decimalLabel(
        json['remaining_balance'] ?? json['remaining_balance_days'] ?? 0,
      ),
      monthlyIncrementLabel: _decimalLabel(json['monthly_increment'] ?? 1.5),
      lastAttendanceLabel: ArabicDateTimeFormatter.dateTime(
        json['last_attendance_at'] ?? json['last_check_in'],
      ),
      status: _parseManagerWorkflow(_string(json['status']) ?? 'pending'),
      managerNote: _string(json['manager_note']) ?? 'بانتظار قرار المدير.',
      hrNote: _string(json['hr_note']) ?? 'بانتظار مرحلة الموارد البشرية.',
    );
  }

  HrLeaveRequest _mapHrRequest(Map<String, dynamic> json) {
    final overallStatus = _string(json['status']) ?? 'pending';
    return HrLeaveRequest(
      id: _string(json['id']) ?? '--',
      employeeName:
          _string(json['employee_name']) ??
          _string(_nested(json, ['user', 'name'])) ??
          'موظف',
      employeeCode:
          _string(json['employee_code']) ??
          _string(_nested(json, ['user', 'code'])) ??
          '--',
      department:
          _string(json['department']) ??
          _string(_nested(json, ['user', 'department'])) ??
          '--',
      leaveType: _leaveTypeName(json),
      periodLabel:
          '${ArabicDateTimeFormatter.date(json['start_date'])} - ${ArabicDateTimeFormatter.date(json['end_date'])}',
      startDateLabel: ArabicDateTimeFormatter.date(json['start_date']),
      endDateLabel: ArabicDateTimeFormatter.date(json['end_date']),
      daysCount: _int(json['days_count']),
      submittedAtLabel: ArabicDateTimeFormatter.dateTime(
        json['created_at'] ?? json['submitted_at'],
      ),
      employeeNote: _string(json['note']) ?? 'لا توجد ملاحظات.',
      currentBalanceLabel: _decimalLabel(
        json['current_balance'] ?? json['balance_days'] ?? 0,
      ),
      remainingBalanceLabel: _decimalLabel(
        json['remaining_balance'] ?? json['remaining_balance_days'] ?? 0,
      ),
      managerStatusLabel:
          _string(json['manager_status_label']) ??
          _parseApprovalStatus(
            _string(json['manager_status']) ??
                _managerStatusFromOverall(overallStatus),
          ).label,
      managerNote: _string(json['manager_note']) ?? 'بانتظار قرار المدير.',
      hrNote: _string(json['hr_note']) ?? 'بانتظار قرار الموارد البشرية.',
      status: _parseHrWorkflow(overallStatus),
    );
  }

  String _leaveTypeName(Map<String, dynamic> json) {
    final nestedType = _nested(json, ['leave_type', 'name']);
    return _string(json['leave_type_name']) ??
        _string(json['leave_type']) ??
        _string(nestedType) ??
        'إجازة';
  }

  dynamic _nested(Map<String, dynamic> json, List<String> keys) {
    dynamic current = json;
    for (final key in keys) {
      if (current is Map<String, dynamic>) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
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

  String _decimalLabel(dynamic value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse('$value') ?? 0;
    return '${number.toStringAsFixed(1)} يوم';
  }

  String _managerStatusFromOverall(dynamic value) {
    final status = _string(value) ?? 'pending';
    if (status == 'manager_approved' ||
        status == 'hr_approved' ||
        status == 'approved') {
      return 'approved';
    }
    if (status == 'rejected') {
      return 'rejected';
    }
    return 'pending';
  }

  String _hrStatusFromOverall(dynamic value) {
    final status = _string(value) ?? 'pending';
    if (status == 'hr_approved' || status == 'approved') {
      return 'approved';
    }
    if (status == 'rejected') {
      return 'rejected';
    }
    return 'pending';
  }

  LeaveRequestStatus _parseEmployeeStatus(String status) {
    switch (status) {
      case 'rejected':
        return LeaveRequestStatus.rejected;
      case 'hr_approved':
      case 'approved':
        return LeaveRequestStatus.approved;
      default:
        return LeaveRequestStatus.pending;
    }
  }

  LeaveApprovalStatus _parseApprovalStatus(String status) {
    switch (status) {
      case 'approved':
      case 'manager_approved':
      case 'hr_approved':
        return LeaveApprovalStatus.approved;
      case 'rejected':
        return LeaveApprovalStatus.rejected;
      default:
        return LeaveApprovalStatus.pending;
    }
  }

  ManagerLeaveWorkflowStatus _parseManagerWorkflow(String status) {
    switch (status) {
      case 'manager_approved':
        return ManagerLeaveWorkflowStatus.managerApproved;
      case 'hr_approved':
      case 'approved':
        return ManagerLeaveWorkflowStatus.fullyApproved;
      case 'rejected':
        return ManagerLeaveWorkflowStatus.rejected;
      default:
        return ManagerLeaveWorkflowStatus.pendingReview;
    }
  }

  HrLeaveWorkflowStatus _parseHrWorkflow(String status) {
    switch (status) {
      case 'manager_approved':
        return HrLeaveWorkflowStatus.pendingHr;
      case 'hr_approved':
      case 'approved':
        return HrLeaveWorkflowStatus.approved;
      case 'rejected':
        return HrLeaveWorkflowStatus.rejected;
      default:
        return HrLeaveWorkflowStatus.waitingManager;
    }
  }
}
