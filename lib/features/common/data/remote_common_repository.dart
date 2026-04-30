import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/app_user_session.dart';
import '../../../core/utils/arabic_date_time_formatter.dart';
import '../domain/models/account_profile_data.dart';
import '../domain/models/app_dashboard_summary.dart';
import '../domain/models/app_notification_item.dart';
import '../domain/models/app_user_role.dart';
import '../domain/repositories/common_repository.dart';

class RemoteCommonRepository implements CommonRepository {
  RemoteCommonRepository({
    required this.apiClient,
    required this.sessionController,
  });

  final ApiClient apiClient;
  final AppSessionController sessionController;

  @override
  Future<AppDashboardSummary> fetchDashboardSummary(AppUserRole role) async {
    final response = await apiClient.get(
      ApiEndpoints.dashboardSummary,
      accessToken: _token,
      handleUnauthorized: true,
    );
    return _mapDashboardSummary(_unwrapMap(response), fallbackRole: role);
  }

  @override
  Future<List<AppNotificationItem>> fetchNotifications(AppUserRole role) async {
    final response = await apiClient.get(
      ApiEndpoints.notifications,
      accessToken: _token,
      handleUnauthorized: true,
    );
    return _unwrapList(response).map(_mapNotification).toList();
  }

  @override
  Future<AccountProfileData> fetchProfile(AppUserRole role) async {
    final response = await apiClient.get(
      ApiEndpoints.profile,
      accessToken: _token,
      handleUnauthorized: true,
    );
    return _mapProfile(_unwrapMap(response), fallbackRole: role);
  }

  @override
  Future<void> markAllNotificationsRead(AppUserRole role) async {
    await apiClient.post(
      ApiEndpoints.notificationsReadAll,
      accessToken: _token,
      handleUnauthorized: true,
    );
  }

  @override
  Future<void> markNotificationRead({
    required AppUserRole role,
    required String notificationId,
  }) async {
    await apiClient.post(
      ApiEndpoints.notificationRead(notificationId),
      accessToken: _token,
      handleUnauthorized: true,
    );
  }

  @override
  Future<void> requestPasswordChange({required String password}) async {
    await apiClient.post(
      ApiEndpoints.passwordChangeRequest,
      accessToken: _token,
      body: {'password': password},
      handleUnauthorized: true,
    );
  }

  @override
  Future<AppNotificationItem> approvePasswordChange({
    required AppUserRole role,
    required String notificationId,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.approvePasswordChange(notificationId),
      accessToken: _token,
      handleUnauthorized: true,
    );
    return _mapNotification(_unwrapMap(response));
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
    throw const ApiException('صيغة بيانات الإشعارات غير متوقعة.');
  }

  Map<String, dynamic> _unwrapMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      final data = value['data'] ?? value['user'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return value;
    }
    throw const ApiException('صيغة بيانات الحساب غير متوقعة.');
  }

  AppNotificationItem _mapNotification(Map<String, dynamic> json) {
    final category = _parseCategory(
      _string(json['category']) ?? _string(json['type']) ?? 'system',
    );
    return AppNotificationItem(
      id: _string(json['id']) ?? '--',
      title: _string(json['title']) ?? 'إشعار جديد',
      message: _string(json['message']) ?? 'لا توجد تفاصيل إضافية.',
      timeLabel:
          _string(json['time_label']) ??
          _string(json['created_at_human']) ??
          ArabicDateTimeFormatter.dateTime(
            json['created_at'] ?? json['sent_at'],
          ),
      category: category,
      isRead: _bool(json['is_read'] ?? json['read']),
      actionLabel: _string(json['action_label']) ?? 'عرض التفاصيل',
      actionRoute: _string(json['action_route']),
      metadata: _mapMetadata(json['metadata']),
    );
  }

  Map<String, dynamic> _mapMetadata(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return const <String, dynamic>{};
  }

  AccountProfileData _mapProfile(
    Map<String, dynamic> json, {
    required AppUserRole fallbackRole,
  }) {
    final sessionProfile = sessionController.currentSession?.profile;
    return AccountProfileData(
      role: _parseRole(
        _string(json['role']) ??
            _string(_nested(json, ['role', 'name'])) ??
            sessionProfile?.role.name ??
            fallbackRole.name,
      ),
      name: _string(json['name']) ?? sessionProfile?.name ?? 'مستخدم النظام',
      code:
          _string(json['code']) ??
          _string(json['employee_code']) ??
          sessionProfile?.code ??
          '--',
      email: _string(json['email']) ?? sessionProfile?.email ?? '--',
      phone: _string(json['phone']) ?? '--',
      department: _string(json['department']) ?? '--',
      jobTitle: _string(json['job_title']) ?? '--',
      joinDate:
          _string(json['join_date']) ??
          ArabicDateTimeFormatter.date(json['joined_at']),
      workSchedule: _string(json['work_schedule']) ?? '--',
      workLocation: _string(json['work_location']) ?? '--',
      lastLogin:
          _string(json['last_login']) ??
          ArabicDateTimeFormatter.dateTime(json['last_login_at']),
      deviceLabel:
          _string(json['device_label']) ??
          _string(json['current_device']) ??
          '--',
      permissions: _parsePermissions(json['permissions']),
    );
  }

  AppDashboardSummary _mapDashboardSummary(
    Map<String, dynamic> json, {
    required AppUserRole fallbackRole,
  }) {
    return AppDashboardSummary(
      role: _parseRole(_string(json['role']) ?? fallbackRole.name),
      unreadNotificationsCount: _int(json['unread_notifications_count']),
      leaveBalanceDays: _double(json['leave_balance_days']),
      monthlyIncrement: _double(json['monthly_increment'] ?? 1.5),
      usedLeavesDays: _int(json['used_leaves_days']),
      pendingRequestsCount: _int(json['pending_requests_count']),
      todayAttendanceRecorded: _bool(json['today_attendance_recorded']),
      todayAttendanceStatus:
          _string(json['today_attendance_status']) ?? 'absent',
      todayCheckInTime: _parseDate(json['today_check_in_time']),
      todayCheckInMethod: _string(json['today_check_in_method']),
      todayLocationLabel: _string(json['today_location_label']),
      employeeCount: _int(json['employee_count']),
      forwardedToHrCount: _int(json['forwarded_to_hr_count']),
      approvedRequestsCount: _int(json['approved_requests_count']),
      rejectedRequestsCount: _int(json['rejected_requests_count']),
      reviewedByManagerCount: _int(json['reviewed_by_manager_count']),
      attendanceTodayCount: _int(json['attendance_today_count']),
      attendanceTodayTotal: _int(
        json['attendance_today_total'] ?? json['employee_count'],
      ),
      leavesThisWeekCount: _int(json['leaves_this_week_count']),
      followUpCasesCount: _int(json['follow_up_cases_count']),
      averageMonthlyIncrement: _double(
        json['average_monthly_increment'] ?? 1.5,
      ),
      waitingManagerCount: _int(json['waiting_manager_count']),
      pendingHrCount: _int(json['pending_hr_count']),
    );
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

  bool _bool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final text = value?.toString().toLowerCase().trim();
    return text == 'true' || text == '1';
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

  DateTime? _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  List<String> _parsePermissions(dynamic value) {
    if (value is List) {
      return value.map((item) {
        if (item is Map<String, dynamic>) {
          return _string(item['name']) ?? item.toString();
        }
        return item.toString();
      }).toList();
    }
    return const [];
  }

  AppNotificationCategory _parseCategory(String value) {
    switch (value.toLowerCase()) {
      case 'leave':
        return AppNotificationCategory.leave;
      case 'attendance':
        return AppNotificationCategory.attendance;
      default:
        return AppNotificationCategory.system;
    }
  }

  AppUserRole _parseRole(String value) {
    switch (value.toLowerCase()) {
      case 'manager':
        return AppUserRole.manager;
      case 'hr':
        return AppUserRole.hr;
      case 'admin':
        return AppUserRole.admin;
      default:
        return AppUserRole.employee;
    }
  }
}
