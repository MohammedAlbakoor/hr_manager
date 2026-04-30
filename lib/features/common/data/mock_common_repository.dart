import '../../attendance/data/mock_attendance_records.dart';
import '../../attendance/domain/models/attendance_record.dart';
import '../../hr/domain/models/hr_leave_request.dart';
import '../../leave/data/mock_employee_leave_requests.dart';
import '../../leave/domain/models/employee_leave_request.dart';
import '../../hr/data/mock_hr_leave_requests.dart';
import '../../manager/data/mock_manager_employee_profiles.dart';
import '../../manager/data/mock_manager_leave_requests.dart';
import '../../manager/domain/models/manager_leave_request.dart';
import '../domain/models/account_profile_data.dart';
import '../domain/models/app_dashboard_summary.dart';
import '../domain/models/app_notification_item.dart';
import '../domain/models/app_user_role.dart';
import '../domain/repositories/common_repository.dart';
import 'mock_common_data.dart';
import 'mock_notification_store.dart';

class MockCommonRepository implements CommonRepository {
  @override
  Future<AppDashboardSummary> fetchDashboardSummary(AppUserRole role) async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    final unreadCount = _itemsForRole(
      role,
    ).where((item) => !item.isRead).length;

    switch (role) {
      case AppUserRole.employee:
        final pendingCount = mockEmployeeLeaveRequests
            .where((item) => item.status == LeaveRequestStatus.pending)
            .length;
        final usedLeavesDays = mockEmployeeLeaveRequests
            .where((item) => item.status == LeaveRequestStatus.approved)
            .fold<int>(0, (sum, item) => sum + item.daysCount);
        final todayRecord = mockAttendanceRecords.isEmpty
            ? null
            : mockAttendanceRecords.first;
        return AppDashboardSummary(
          role: role,
          unreadNotificationsCount: unreadCount,
          leaveBalanceDays: 18.5,
          monthlyIncrement: 1.5,
          usedLeavesDays: usedLeavesDays,
          pendingRequestsCount: pendingCount,
          todayAttendanceRecorded: todayRecord != null,
          todayAttendanceStatus: _attendanceStatusValue(todayRecord?.status),
          todayCheckInTime: null,
          todayCheckInMethod: todayRecord?.method,
          todayLocationLabel: todayRecord?.locationLabel,
          employeeCount: 0,
          forwardedToHrCount: 0,
          approvedRequestsCount: 0,
          rejectedRequestsCount: 0,
          reviewedByManagerCount: 0,
          attendanceTodayCount: 0,
          attendanceTodayTotal: 0,
          leavesThisWeekCount: 0,
          followUpCasesCount: 0,
          averageMonthlyIncrement: 1.5,
          waitingManagerCount: 0,
          pendingHrCount: 0,
        );
      case AppUserRole.manager:
        final pendingCount = mockManagerLeaveRequests
            .where(
              (item) => item.status == ManagerLeaveWorkflowStatus.pendingReview,
            )
            .length;
        final forwardedCount = mockManagerLeaveRequests
            .where(
              (item) =>
                  item.status == ManagerLeaveWorkflowStatus.managerApproved,
            )
            .length;
        final approvedCount = mockManagerLeaveRequests
            .where(
              (item) => item.status == ManagerLeaveWorkflowStatus.fullyApproved,
            )
            .length;
        final rejectedCount = mockManagerLeaveRequests
            .where((item) => item.status == ManagerLeaveWorkflowStatus.rejected)
            .length;
        final averageIncrement = mockManagerEmployeeProfiles.isEmpty
            ? 1.5
            : mockManagerEmployeeProfiles
                      .map((item) => item.monthlyIncrement)
                      .reduce((sum, value) => sum + value) /
                  mockManagerEmployeeProfiles.length;
        return AppDashboardSummary(
          role: role,
          unreadNotificationsCount: unreadCount,
          leaveBalanceDays: 0,
          monthlyIncrement: 0,
          usedLeavesDays: 0,
          pendingRequestsCount: pendingCount,
          todayAttendanceRecorded: false,
          todayAttendanceStatus: 'absent',
          todayCheckInTime: null,
          todayCheckInMethod: null,
          todayLocationLabel: null,
          employeeCount: mockManagerEmployeeProfiles.length,
          forwardedToHrCount: forwardedCount,
          approvedRequestsCount: approvedCount,
          rejectedRequestsCount: rejectedCount,
          reviewedByManagerCount:
              forwardedCount + approvedCount + rejectedCount,
          attendanceTodayCount: 10,
          attendanceTodayTotal: mockManagerEmployeeProfiles.length,
          leavesThisWeekCount: 3,
          followUpCasesCount: (mockManagerEmployeeProfiles.length - 10).clamp(
            0,
            999,
          ),
          averageMonthlyIncrement: averageIncrement,
          waitingManagerCount: 0,
          pendingHrCount: 0,
        );
      case AppUserRole.hr:
      case AppUserRole.admin:
        final waitingManagerCount = mockHrLeaveRequests
            .where(
              (item) => item.status == HrLeaveWorkflowStatus.waitingManager,
            )
            .length;
        final pendingHrCount = mockHrLeaveRequests
            .where((item) => item.status == HrLeaveWorkflowStatus.pendingHr)
            .length;
        final approvedCount = mockHrLeaveRequests
            .where((item) => item.status == HrLeaveWorkflowStatus.approved)
            .length;
        final rejectedCount = mockHrLeaveRequests
            .where((item) => item.status == HrLeaveWorkflowStatus.rejected)
            .length;
        return AppDashboardSummary(
          role: role,
          unreadNotificationsCount: unreadCount,
          leaveBalanceDays: 0,
          monthlyIncrement: 0,
          usedLeavesDays: 0,
          pendingRequestsCount: 0,
          todayAttendanceRecorded: false,
          todayAttendanceStatus: 'absent',
          todayCheckInTime: null,
          todayCheckInMethod: null,
          todayLocationLabel: null,
          employeeCount: mockManagerEmployeeProfiles.length,
          forwardedToHrCount: 0,
          approvedRequestsCount: approvedCount,
          rejectedRequestsCount: rejectedCount,
          reviewedByManagerCount: 0,
          attendanceTodayCount: 0,
          attendanceTodayTotal: 0,
          leavesThisWeekCount: 0,
          followUpCasesCount: 0,
          averageMonthlyIncrement: 0,
          waitingManagerCount: waitingManagerCount,
          pendingHrCount: pendingHrCount,
        );
    }
  }

  @override
  Future<List<AppNotificationItem>> fetchNotifications(AppUserRole role) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    return MockNotificationStore.itemsForRole(role);
  }

  @override
  Future<AccountProfileData> fetchProfile(AppUserRole role) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    return profileForRole(role);
  }

  @override
  Future<void> markAllNotificationsRead(AppUserRole role) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    MockNotificationStore.markAllRead(role);
  }

  @override
  Future<void> markNotificationRead({
    required AppUserRole role,
    required String notificationId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    MockNotificationStore.markRead(role, notificationId);
  }

  @override
  Future<void> requestPasswordChange({required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    MockNotificationStore.addPasswordChangeRequest();
  }

  @override
  Future<AppNotificationItem> approvePasswordChange({
    required AppUserRole role,
    required String notificationId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return MockNotificationStore.approvePasswordChange(role, notificationId);
  }

  List<AppNotificationItem> _itemsForRole(AppUserRole role) {
    return MockNotificationStore.itemsForRole(role);
  }

  String _attendanceStatusValue(AttendanceRecordStatus? status) {
    switch (status) {
      case AttendanceRecordStatus.late:
        return 'late';
      case AttendanceRecordStatus.absent:
        return 'absent';
      default:
        return 'present';
    }
  }
}
