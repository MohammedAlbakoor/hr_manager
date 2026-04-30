class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String dashboardSummary = '/dashboard/summary';
  static const String profile = '/users/me';
  static const String notifications = '/notifications';
  static const String notificationsBroadcast = '/notifications/broadcast';
  static const String managerBroadcasts = '/notifications/broadcasts';
  static const String managerBroadcastRecipients =
      '/notifications/broadcasts/recipients';
  static const String notificationsReadAll = '/notifications/read-all';
  static const String passwordChangeRequest =
      '/users/me/password-change-request';
  static const String leaves = '/leaves';
  static const String managerLeaves = '/leaves/manager';
  static const String hrLeaves = '/leaves/hr';
  static const String employeeProfiles = '/users/employees';
  static const String employeeManagers = '/users/employees/managers';
  static const String employeeMonthlyIncrementBulk =
      '/users/employees/monthly-increment';
  static const String attendanceHistory = '/attendance/history';
  static const String attendanceScan = '/attendance/scan';
  static const String attendanceQrSession = '/qr/session';
  static const String attendanceReportRows = '/reports/attendance';
  static const String attendanceReportExport = '/reports/attendance/export';
  static const String leaveReportRows = '/reports/leaves';
  static const String leaveReportExport = '/reports/leaves/export';

  static String leaveDecision(String leaveId) => '/leaves/$leaveId/approve';
  static String notificationRead(String notificationId) =>
      '/notifications/$notificationId/read';
  static String approvePasswordChange(String notificationId) =>
      '/notifications/$notificationId/approve-password-change';
  static String employeeProfile(String code) => '/users/employees/$code';
  static String updateEmployee(String code) => '/users/employees/$code';
  static String deleteEmployee(String code) => '/users/employees/$code';
  static String updateEmployeePassword(String code) =>
      '/users/employees/$code/password';
  static String restoreEmployee(String code) =>
      '/users/employees/$code/restore';
  static String employeeMonthlyIncrement(String code) =>
      '/users/employees/$code/monthly-increment';
  static String managerBroadcast(String id) => '/notifications/broadcasts/$id';
}
