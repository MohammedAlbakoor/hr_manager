import '../../../../core/utils/arabic_date_time_formatter.dart';
import 'app_user_role.dart';

class AppDashboardSummary {
  const AppDashboardSummary({
    required this.role,
    required this.unreadNotificationsCount,
    required this.leaveBalanceDays,
    required this.monthlyIncrement,
    required this.usedLeavesDays,
    required this.pendingRequestsCount,
    required this.todayAttendanceRecorded,
    required this.todayAttendanceStatus,
    required this.todayCheckInTime,
    required this.todayCheckInMethod,
    required this.todayLocationLabel,
    required this.employeeCount,
    required this.forwardedToHrCount,
    required this.approvedRequestsCount,
    required this.rejectedRequestsCount,
    required this.reviewedByManagerCount,
    required this.attendanceTodayCount,
    required this.attendanceTodayTotal,
    required this.leavesThisWeekCount,
    required this.followUpCasesCount,
    required this.averageMonthlyIncrement,
    required this.waitingManagerCount,
    required this.pendingHrCount,
  });

  final AppUserRole role;
  final int unreadNotificationsCount;
  final double leaveBalanceDays;
  final double monthlyIncrement;
  final int usedLeavesDays;
  final int pendingRequestsCount;
  final bool todayAttendanceRecorded;
  final String todayAttendanceStatus;
  final DateTime? todayCheckInTime;
  final String? todayCheckInMethod;
  final String? todayLocationLabel;
  final int employeeCount;
  final int forwardedToHrCount;
  final int approvedRequestsCount;
  final int rejectedRequestsCount;
  final int reviewedByManagerCount;
  final int attendanceTodayCount;
  final int attendanceTodayTotal;
  final int leavesThisWeekCount;
  final int followUpCasesCount;
  final double averageMonthlyIncrement;
  final int waitingManagerCount;
  final int pendingHrCount;

  String get leaveBalanceLabel => '${leaveBalanceDays.toStringAsFixed(1)} يوم';

  String get monthlyIncrementLabel =>
      '${monthlyIncrement.toStringAsFixed(1)} يوم';

  String get averageMonthlyIncrementLabel =>
      '${averageMonthlyIncrement.toStringAsFixed(1)} يوم';

  String get todayCheckInTimeLabel {
    if (todayCheckInTime == null) {
      return '--';
    }
    return ArabicDateTimeFormatter.time(todayCheckInTime);
  }

  String get todayAttendanceStatusLabel {
    switch (todayAttendanceStatus) {
      case 'late':
        return 'متأخر';
      case 'absent':
        return 'غائب';
      default:
        return 'حاضر';
    }
  }

  String get attendanceTodayRatioLabel =>
      '$attendanceTodayCount / $attendanceTodayTotal موظف';
}
