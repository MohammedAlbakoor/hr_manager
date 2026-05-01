import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/app_user_session.dart';
import '../../common/domain/models/app_user_role.dart';
import '../domain/models/employee_manager_option.dart';
import '../domain/models/employee_upsert_payload.dart';
import '../domain/models/manager_employee_profile.dart';
import '../domain/models/manager_leave_request.dart';
import '../domain/repositories/employee_profile_repository.dart';

class RemoteEmployeeProfileRepository implements EmployeeProfileRepository {
  RemoteEmployeeProfileRepository({
    required this.apiClient,
    required this.sessionController,
  });

  final ApiClient apiClient;
  final AppSessionController sessionController;

  @override
  Future<List<ManagerEmployeeProfile>> fetchEmployeeProfiles() async {
    final response = await apiClient.get(
      ApiEndpoints.employeeProfiles,
      accessToken: _token,
      queryParameters: const {'status': 'all'},
      handleUnauthorized: true,
    );
    return _unwrapList(response).map(_mapProfile).toList();
  }

  @override
  Future<ManagerEmployeeProfile?> fetchEmployeeProfileByCode(
    String code,
  ) async {
    final response = await apiClient.get(
      ApiEndpoints.employeeProfile(code),
      accessToken: _token,
      handleUnauthorized: true,
    );
    return _mapProfile(_unwrapMap(response));
  }

  @override
  Future<List<EmployeeManagerOption>> fetchManagerOptions() async {
    final response = await apiClient.get(
      ApiEndpoints.employeeManagers,
      accessToken: _token,
      handleUnauthorized: true,
    );
    return _unwrapList(response).map(_mapManagerOption).toList();
  }

  @override
  Future<ManagerEmployeeProfile> createEmployee(
    EmployeeUpsertPayload payload,
  ) async {
    final response = await apiClient.post(
      ApiEndpoints.employeeProfiles,
      accessToken: _token,
      body: payload.toJson(),
      handleUnauthorized: true,
    );
    return _mapProfile(_unwrapMap(response));
  }

  @override
  Future<ManagerEmployeeProfile> updateEmployee({
    required String employeeCode,
    required EmployeeUpsertPayload payload,
  }) async {
    final response = await apiClient.patch(
      ApiEndpoints.updateEmployee(employeeCode),
      accessToken: _token,
      body: payload.toJson(),
      handleUnauthorized: true,
    );
    return _mapProfile(_unwrapMap(response));
  }

  @override
  Future<void> updateEmployeePassword({
    required String employeeCode,
    required String password,
  }) async {
    await apiClient.post(
      ApiEndpoints.updateEmployeePassword(employeeCode),
      accessToken: _token,
      body: {'password': password},
      handleUnauthorized: true,
    );
  }

  @override
  Future<void> deleteEmployee(String employeeCode) async {
    await apiClient.delete(
      ApiEndpoints.deleteEmployee(employeeCode),
      accessToken: _token,
      handleUnauthorized: true,
    );
  }

  @override
  Future<ManagerEmployeeProfile> restoreEmployee(String employeeCode) async {
    final response = await apiClient.post(
      ApiEndpoints.restoreEmployee(employeeCode),
      accessToken: _token,
      handleUnauthorized: true,
    );
    return _mapProfile(_unwrapMap(response));
  }

  @override
  Future<void> broadcastManagerMessage({
    required String title,
    required String message,
  }) async {
    await apiClient.post(
      ApiEndpoints.notificationsBroadcast,
      accessToken: _token,
      body: {'title': title, 'message': message},
      handleUnauthorized: true,
    );
  }

  @override
  Future<ManagerEmployeeProfile> updateEmployeeMonthlyIncrement({
    required String employeeCode,
    required double monthlyIncrement,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.employeeMonthlyIncrement(employeeCode),
      accessToken: _token,
      body: {'monthly_increment': monthlyIncrement},
      handleUnauthorized: true,
    );
    return _mapProfile(_unwrapMap(response));
  }

  @override
  Future<List<ManagerEmployeeProfile>> updateAllMonthlyIncrements(
    double monthlyIncrement,
  ) async {
    final response = await apiClient.post(
      ApiEndpoints.employeeMonthlyIncrementBulk,
      accessToken: _token,
      body: {'monthly_increment': monthlyIncrement},
      handleUnauthorized: true,
    );
    return _unwrapList(response).map(_mapProfile).toList();
  }

  @override
  Future<ManagerEmployeeProfile> uploadEmployeeDocument({
    required String employeeCode,
    required EmployeeDocumentType type,
    required EmployeeDocumentSource source,
    required String title,
    required EmployeeProfileAttachmentFile file,
    bool runOcr = false,
  }) async {
    final response = await apiClient.multipart(
      ApiEndpoints.employeeDocuments(employeeCode),
      method: 'POST',
      accessToken: _token,
      fields: {
        'type': type.apiValue,
        'source': source.apiValue,
        'title': title,
        'run_ocr': runOcr ? '1' : '0',
      },
      files: [_uploadFile(file)],
      handleUnauthorized: true,
    );
    return _mapProfile(_unwrapMap(response));
  }

  @override
  Future<ManagerEmployeeProfile> saveEmployeeCv({
    required String employeeCode,
    required EmployeeCvProfile cvProfile,
  }) async {
    final response = await apiClient.patch(
      ApiEndpoints.employeeCv(employeeCode),
      accessToken: _token,
      body: cvProfile.toJson(),
      handleUnauthorized: true,
    );
    return _mapProfile(_unwrapMap(response));
  }

  @override
  Future<ManagerEmployeeProfile> uploadEmployeeCvPdf({
    required String employeeCode,
    required EmployeeProfileAttachmentFile file,
    bool suggestAutofill = true,
  }) async {
    final response = await apiClient.multipart(
      ApiEndpoints.employeeCvPdf(employeeCode),
      method: 'POST',
      accessToken: _token,
      fields: {'suggest_autofill': suggestAutofill ? '1' : '0'},
      files: [_uploadFile(file)],
      handleUnauthorized: true,
    );
    return _mapProfile(_unwrapMap(response));
  }

  @override
  Future<ManagerEmployeeProfile> autofillEmployeeCvFromFile(
    String employeeCode,
  ) async {
    final response = await apiClient.post(
      ApiEndpoints.employeeCvAutofill(employeeCode),
      accessToken: _token,
      handleUnauthorized: true,
    );
    return _mapProfile(_unwrapMap(response));
  }

  @override
  Future<ManagerEmployeeProfile> regenerateEmployeeCvSummary(
    String employeeCode,
  ) async {
    final response = await apiClient.post(
      ApiEndpoints.employeeCvSummary(employeeCode),
      accessToken: _token,
      handleUnauthorized: true,
    );
    return _mapProfile(_unwrapMap(response));
  }

  @override
  Future<ManagerEmployeeProfile> addAdministrativeRecord({
    required String employeeCode,
    required EmployeeAdministrativeRecordDraft record,
    EmployeeProfileAttachmentFile? attachment,
  }) async {
    final endpoint = ApiEndpoints.employeeAdministrativeRecords(employeeCode);
    final response = attachment == null
        ? await apiClient.post(
            endpoint,
            accessToken: _token,
            body: record.toJson(),
            handleUnauthorized: true,
          )
        : await apiClient.multipart(
            endpoint,
            method: 'POST',
            accessToken: _token,
            fields: record.toJson().map(
              (key, value) => MapEntry(key, value?.toString() ?? ''),
            ),
            files: [_uploadFile(attachment)],
            handleUnauthorized: true,
          );
    return _mapProfile(_unwrapMap(response));
  }

  String get _token {
    final token = sessionController.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw const ApiException('لا توجد جلسة دخول نشطة لتنفيذ العملية.');
    }
    return token;
  }

  ApiUploadFile _uploadFile(EmployeeProfileAttachmentFile file) {
    return ApiUploadFile(
      field: 'file',
      fileName: file.name,
      path: file.path,
      bytes: file.bytes,
    );
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
    throw const ApiException('صيغة بيانات الموظفين غير متوقعة.');
  }

  Map<String, dynamic> _unwrapMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      final data = value['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return value;
    }
    throw const ApiException('صيغة ملف الموظف غير متوقعة.');
  }

  EmployeeManagerOption _mapManagerOption(Map<String, dynamic> json) {
    return EmployeeManagerOption(
      id: _int(json['id']),
      name: _string(json['name']) ?? 'مدير',
      code: _string(json['code']) ?? '--',
      department: _string(json['department']) ?? '--',
      jobTitle: _string(json['job_title']) ?? '--',
    );
  }

  ManagerEmployeeProfile _mapProfile(Map<String, dynamic> json) {
    final leaveItems = _unwrapNestedList(json, ['leave_items']);
    final attendanceItems = _unwrapNestedList(json, ['attendance_items']);
    final documents = _unwrapNestedList(json, ['documents']);
    final records = _unwrapNestedList(json, ['administrative_records']);
    final monthlyIncrement = _double(
      json['monthly_increment'] ??
          _nested(json, ['leave_balance', 'monthly_increment']) ??
          1.5,
    );

    return ManagerEmployeeProfile(
      id: _string(json['id']) ?? _string(json['employee_code']) ?? '--',
      name:
          _string(json['name']) ??
          _string(_nested(json, ['user', 'name'])) ??
          'موظف',
      code:
          _string(json['code']) ??
          _string(json['employee_code']) ??
          _string(_nested(json, ['user', 'code'])) ??
          '--',
      jobTitle:
          _string(json['job_title']) ??
          _string(_nested(json, ['user', 'job_title'])) ??
          '--',
      department:
          _string(json['department']) ??
          _string(_nested(json, ['user', 'department'])) ??
          '--',
      email:
          _string(json['email']) ??
          _string(_nested(json, ['user', 'email'])) ??
          '--',
      phone:
          _string(json['phone']) ??
          _string(_nested(json, ['user', 'phone'])) ??
          '--',
      leaveBalanceLabel: _decimalLabel(
        json['balance_days'] ??
            json['leave_balance_days'] ??
            _nested(json, ['leave_balance', 'balance_days']) ??
            0,
      ),
      usedLeavesLabel:
          '${_int(json['used_leaves_days'] ?? json['used_days'])} أيام',
      monthlyIncrement: monthlyIncrement,
      pendingLeavesCount: _int(
        json['pending_leaves_count'] ?? json['pending_count'],
      ),
      todayAttendanceLabel: _attendanceStatusLabel(
        _string(json['today_attendance_status']) ??
            _string(json['today_status']),
      ),
      lastCheckInLabel: _dateTimeLabel(
        json['last_check_in'] ?? json['last_attendance_at'],
      ),
      workLocation: _string(json['work_location']) ?? '--',
      workSchedule: _string(json['work_schedule']) ?? '--',
      joinDate: _string(json['join_date']) ?? '--',
      birthDate: _string(json['birth_date']) ?? '',
      identityNumber: _string(json['identity_number']) ?? '',
      identityIssueDate: _string(json['identity_issue_date']) ?? '',
      identityExpiryDate: _string(json['identity_expiry_date']) ?? '',
      identityPlace: _string(json['identity_place']) ?? '',
      nationality: _string(json['nationality']) ?? '',
      shamCashAccount: _string(json['sham_cash_account']) ?? '',
      address: _string(json['address']) ?? '',
      emergencyContact: _string(json['emergency_contact']) ?? '',
      jobLevel: EmployeeJobLevel.fromStorage(_string(json['job_level'])),
      documents: documents.map(_mapDocument).toList(),
      cvProfile: _mapCvProfile(json['cv_profile']),
      administrativeRecords: records.map(_mapAdministrativeRecord).toList(),
      role: _parseRole(_string(json['role'])),
      roleLabel: _string(json['role_label']),
      deletedAt: _string(json['deleted_at']),
      managerId: _nullableInt(json['manager_id']),
      managerName: _string(json['manager_name']),
      managerCode: _string(json['manager_code']),
      leaveItems: leaveItems.isEmpty
          ? _buildFallbackLeaveItems(json)
          : leaveItems.map(_mapLeaveItem).toList(),
      attendanceItems: attendanceItems.isEmpty
          ? _buildFallbackAttendanceItems(json)
          : attendanceItems.map(_mapAttendanceItem).toList(),
    );
  }

  List<Map<String, dynamic>> _unwrapNestedList(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    final value = _nested(json, keys);
    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  List<ManagerEmployeeLeaveItem> _buildFallbackLeaveItems(
    Map<String, dynamic> json,
  ) {
    final leaveType = _string(json['latest_leave_type']) ?? 'إجازة';
    final days = _int(json['latest_leave_days'] ?? 0);
    if (days == 0) {
      return const [];
    }
    return [
      ManagerEmployeeLeaveItem(
        title: leaveType,
        periodLabel: _string(json['latest_leave_period']) ?? '--',
        daysCount: days,
        status: _parseLeaveStatus(
          _string(json['latest_leave_status']) ?? 'pending',
        ),
      ),
    ];
  }

  List<ManagerEmployeeAttendanceItem> _buildFallbackAttendanceItems(
    Map<String, dynamic> json,
  ) {
    final lastCheckIn = json['last_check_in'] ?? json['last_attendance_at'];
    if (lastCheckIn == null) {
      return const [];
    }
    return [
      ManagerEmployeeAttendanceItem(
        dateLabel: _dateLabel(lastCheckIn),
        checkInLabel: _timeLabel(lastCheckIn),
        status: _parseAttendanceStatus(
          _string(json['today_attendance_status']) ?? 'present',
        ),
      ),
    ];
  }

  ManagerEmployeeLeaveItem _mapLeaveItem(Map<String, dynamic> json) {
    return ManagerEmployeeLeaveItem(
      title:
          _string(json['title']) ??
          _string(json['leave_type_name']) ??
          _string(_nested(json, ['leave_type', 'name'])) ??
          'إجازة',
      periodLabel:
          _string(json['period_label']) ??
          '${_dateLabel(json['start_date'])} - ${_dateLabel(json['end_date'])}',
      daysCount: _int(json['days_count']),
      status: _parseLeaveStatus(_string(json['status']) ?? 'pending'),
    );
  }

  ManagerEmployeeAttendanceItem _mapAttendanceItem(Map<String, dynamic> json) {
    return ManagerEmployeeAttendanceItem(
      dateLabel: _string(json['date_label']) ?? _dateLabel(json['date']),
      checkInLabel:
          _string(json['check_in_label']) ?? _timeLabel(json['check_in_time']),
      status: _parseAttendanceStatus(_string(json['status']) ?? 'present'),
    );
  }

  EmployeeProfileDocument _mapDocument(Map<String, dynamic> json) {
    return EmployeeProfileDocument(
      id: _string(json['id']) ?? '--',
      type: EmployeeDocumentType.fromStorage(_string(json['type'])),
      title:
          _string(json['title']) ??
          EmployeeDocumentType.fromStorage(_string(json['type'])).label,
      fileName:
          _string(json['file_name']) ??
          _string(json['original_name']) ??
          'attachment',
      uploadedAt:
          _string(json['uploaded_at']) ?? _string(json['created_at']) ?? '',
      source: EmployeeDocumentSource.fromStorage(_string(json['source'])),
      mimeType: _string(json['mime_type']),
      sizeBytes: _nullableInt(json['size_bytes']),
      url: _string(json['url']),
      ocrText: _string(json['ocr_text']),
      ocrSuggestions: _stringMap(json['ocr_suggestions']),
    );
  }

  EmployeeCvProfile _mapCvProfile(dynamic value) {
    if (value is! Map<String, dynamic>) {
      return const EmployeeCvProfile.empty();
    }
    final pdfDocument = value['pdf_document'];
    return EmployeeCvProfile(
      professionalSummary: _string(value['professional_summary']) ?? '',
      skills: _stringList(value['skills']),
      experience: _cvItems(value['experience']),
      education: _cvItems(value['education']),
      courses: _cvItems(value['courses']),
      pdfDocument: pdfDocument is Map<String, dynamic>
          ? _mapDocument(pdfDocument)
          : null,
      extractedText: _string(value['extracted_text']) ?? '',
      generatedSummary: _string(value['generated_summary']) ?? '',
      updatedAt: _string(value['updated_at']) ?? '',
    );
  }

  EmployeeAdministrativeRecord _mapAdministrativeRecord(
    Map<String, dynamic> json,
  ) {
    final document = json['document'];
    return EmployeeAdministrativeRecord(
      id: _string(json['id']) ?? '--',
      category: EmployeeAdministrativeRecordCategory.fromStorage(
        _string(json['category']),
      ),
      title: _string(json['title']) ?? 'سجل إداري',
      recordDate: _string(json['record_date']) ?? '',
      referenceNumber: _string(json['reference_number']) ?? '',
      description: _string(json['description']) ?? '',
      document: document is Map<String, dynamic>
          ? _mapDocument(document)
          : null,
      createdAt: _string(json['created_at']) ?? '',
    );
  }

  ManagerLeaveWorkflowStatus _parseLeaveStatus(String status) {
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

  ManagerAttendanceStatus _parseAttendanceStatus(String status) {
    switch (status) {
      case 'late':
        return ManagerAttendanceStatus.late;
      case 'absent':
        return ManagerAttendanceStatus.absent;
      default:
        return ManagerAttendanceStatus.present;
    }
  }

  AppUserRole _parseRole(String? value) {
    return AppUserRole.fromStorage(value);
  }

  String _attendanceStatusLabel(String? status) {
    switch (status) {
      case 'late':
        return ManagerAttendanceStatus.late.label;
      case 'absent':
        return ManagerAttendanceStatus.absent.label;
      default:
        return ManagerAttendanceStatus.present.label;
    }
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

  Map<String, String> _stringMap(dynamic value) {
    if (value is! Map<String, dynamic>) {
      return const {};
    }
    return value.map(
      (key, item) => MapEntry(key.toString(), item?.toString() ?? ''),
    );
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  List<EmployeeCvItem> _cvItems(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map<String, dynamic>>()
        .map(EmployeeCvItem.fromJson)
        .where((item) => !item.isEmpty)
        .toList();
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

  int? _nullableInt(dynamic value) {
    if (value == null) {
      return null;
    }
    return _int(value);
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

  String _decimalLabel(dynamic value) {
    return '${_double(value).toStringAsFixed(1)} يوم';
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

  String _dateLabel(dynamic value) {
    final date = _parseDate(value);
    if (date == null) {
      return '--';
    }
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _timeLabel(dynamic value) {
    final date = _parseDate(value);
    if (date == null) {
      return '--';
    }
    final hour = date.hour > 12
        ? date.hour - 12
        : date.hour == 0
        ? 12
        : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'م' : 'ص';
    return '${hour.toString().padLeft(2, '0')}:$minute $suffix';
  }

  String _dateTimeLabel(dynamic value) {
    final date = _parseDate(value);
    if (date == null) {
      return '--';
    }
    return '${_dateLabel(date)} - ${_timeLabel(date)}';
  }
}
