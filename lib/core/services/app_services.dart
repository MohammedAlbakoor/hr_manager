import '../navigation/app_navigator.dart';
import '../network/api_client.dart';
import '../network/api_config.dart';
import '../session/app_user_session.dart';
import '../session/session_expiration_coordinator.dart';
import 'biometric_lock_service.dart';
import 'device_identifier_service.dart';
import 'report_file_saver.dart';
import 'report_table_export_builder.dart';
import '../../features/attendance/data/mock_attendance_repository.dart';
import '../../features/attendance/data/remote_attendance_repository.dart';
import '../../features/attendance/domain/repositories/attendance_repository.dart';
import '../../features/auth/data/local_login_credentials_store.dart';
import '../../features/auth/data/mock_auth_repository.dart';
import '../../features/auth/data/remote_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/common/data/mock_common_repository.dart';
import '../../features/common/data/remote_common_repository.dart';
import '../../features/common/domain/repositories/common_repository.dart';
import '../../features/leave/data/mock_leave_repository.dart';
import '../../features/leave/data/remote_leave_repository.dart';
import '../../features/leave/domain/repositories/leave_repository.dart';
import '../../features/manager/data/mock_employee_profile_repository.dart';
import '../../features/manager/data/mock_manager_broadcast_repository.dart';
import '../../features/manager/data/remote_employee_profile_repository.dart';
import '../../features/manager/data/remote_manager_broadcast_repository.dart';
import '../../features/manager/domain/repositories/employee_profile_repository.dart';
import '../../features/manager/domain/repositories/manager_broadcast_repository.dart';
import '../../features/reports/data/mock_report_repository.dart';
import '../../features/reports/data/remote_report_repository.dart';
import '../../features/reports/domain/repositories/report_repository.dart';

class AppServices {
  AppServices._();

  static final AppSessionController session = AppSessionController();
  static final SessionExpirationCoordinator sessionExpirationCoordinator =
      SessionExpirationCoordinator(sessionController: session);
  static final ApiClient apiClient = ApiClient(
    baseUrl: ApiConfig.baseUrl,
    onUnauthorized: sessionExpirationCoordinator.handleUnauthorized,
  );
  static final bool useMockRepositories = ApiConfig.useMockRepositories;
  static const DeviceIdentifierService deviceIdentifierService =
      DeviceIdentifierService();
  static final LocalLoginCredentialsStore loginCredentialsStore =
      LocalLoginCredentialsStore();
  static final BiometricLockService biometricLockService =
      BiometricLockService();
  static const ReportFileSaver reportFileSaver = ReportFileSaver();
  static const ReportTableExportBuilder reportTableExportBuilder =
      ReportTableExportBuilder();
  static final navigatorKey = AppNavigator.navigatorKey;
  static final scaffoldMessengerKey = AppNavigator.scaffoldMessengerKey;

  static final AuthRepository authRepository = useMockRepositories
      ? MockAuthRepository(sessionController: session)
      : RemoteAuthRepository(apiClient: apiClient, sessionController: session);

  static final LeaveRepository leaveRepository = useMockRepositories
      ? MockLeaveRepository()
      : RemoteLeaveRepository(apiClient: apiClient, sessionController: session);

  static final AttendanceRepository attendanceRepository = useMockRepositories
      ? MockAttendanceRepository()
      : RemoteAttendanceRepository(
          apiClient: apiClient,
          sessionController: session,
        );

  static final EmployeeProfileRepository employeeProfileRepository =
      useMockRepositories
      ? MockEmployeeProfileRepository(sessionController: session)
      : RemoteEmployeeProfileRepository(
          apiClient: apiClient,
          sessionController: session,
        );

  static final ManagerBroadcastRepository managerBroadcastRepository =
      useMockRepositories
      ? MockManagerBroadcastRepository()
      : RemoteManagerBroadcastRepository(
          apiClient: apiClient,
          sessionController: session,
        );

  static final CommonRepository commonRepository = useMockRepositories
      ? MockCommonRepository()
      : RemoteCommonRepository(
          apiClient: apiClient,
          sessionController: session,
        );

  static final ReportRepository reportRepository = useMockRepositories
      ? MockReportRepository()
      : RemoteReportRepository(
          apiClient: apiClient,
          sessionController: session,
        );
}
