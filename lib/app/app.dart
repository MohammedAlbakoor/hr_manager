import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/connectivity/connectivity_host.dart';
import '../core/navigation/app_navigator.dart';
import '../core/navigation/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../core/services/app_services.dart';
import '../features/admin/presentation/pages/admin_dashboard_screen.dart';
import '../features/auth/presentation/pages/login_screen.dart';
import '../features/auth/presentation/pages/splash_screen.dart';
import '../features/attendance/presentation/pages/attendance_history_screen.dart';
import '../features/attendance/presentation/pages/scan_qr_attendance_screen.dart';
import '../features/common/domain/models/app_user_role.dart';
import '../features/common/presentation/pages/notifications_screen.dart';
import '../features/common/presentation/pages/profile_account_screen.dart';
import '../features/employee/presentation/pages/employee_dashboard_screen.dart';
import '../features/hr/presentation/pages/hr_dashboard_screen.dart';
import '../features/hr/presentation/pages/hr_employee_details_screen.dart';
import '../features/hr/presentation/pages/hr_leave_requests_screen.dart';
import '../features/hr/presentation/pages/hr_qr_display_screen.dart';
import '../features/leave/presentation/pages/create_leave_request_screen.dart';
import '../features/leave/presentation/pages/employee_leave_history_screen.dart';
import '../features/manager/presentation/pages/manager_dashboard_screen.dart';
import '../features/manager/presentation/pages/manager_employee_details_screen.dart';
import '../features/manager/presentation/pages/manager_broadcasts_screen.dart';
import '../features/manager/presentation/pages/manager_leave_requests_screen.dart';
import '../features/manager/presentation/pages/manager_leave_policy_screen.dart';
import '../features/manager/presentation/pages/manager_qr_display_screen.dart';
import '../features/reports/presentation/pages/hr_reports_screen.dart';

class HrManagerApp extends StatelessWidget {
  const HrManagerApp({super.key});

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.notifications:
        final role = settings.arguments as AppUserRole? ?? AppUserRole.employee;
        return MaterialPageRoute(
          builder: (_) => NotificationsScreen(role: role),
          settings: settings,
        );
      case AppRoutes.profileAccount:
        final role = settings.arguments as AppUserRole? ?? AppUserRole.employee;
        return MaterialPageRoute(
          builder: (_) => ProfileAccountScreen(role: role),
          settings: settings,
        );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HR Manager',
      theme: AppTheme.light(),
      navigatorKey: AppNavigator.navigatorKey,
      scaffoldMessengerKey: AppNavigator.scaffoldMessengerKey,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: _onGenerateRoute,
      builder: (context, child) {
        return ConnectivityHost(
          controller: AppServices.connectivity,
          child: child ?? const SizedBox.shrink(),
        );
      },
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.employeeDashboard: (_) => const EmployeeDashboardScreen(),
        AppRoutes.createLeaveRequest: (_) => const CreateLeaveRequestScreen(),
        AppRoutes.employeeLeaveHistory: (_) =>
            const EmployeeLeaveHistoryScreen(),
        AppRoutes.employeeAttendanceHistory: (_) =>
            const AttendanceHistoryScreen(),
        AppRoutes.scanQrAttendance: (_) => const ScanQrAttendanceScreen(),
        AppRoutes.managerDashboard: (_) => const ManagerDashboardScreen(),
        AppRoutes.managerLeaveRequests: (_) =>
            const ManagerLeaveRequestsScreen(),
        AppRoutes.managerEmployeeDetails: (_) =>
            const ManagerEmployeeDetailsScreen(),
        AppRoutes.managerBroadcasts: (_) => const ManagerBroadcastsScreen(),
        AppRoutes.managerLeavePolicy: (_) => const ManagerLeavePolicyScreen(),
        AppRoutes.managerQrDisplay: (_) => const ManagerQrDisplayScreen(),
        AppRoutes.adminDashboard: (_) => const AdminDashboardScreen(),
        AppRoutes.hrDashboard: (_) => const HrDashboardScreen(),
        AppRoutes.hrLeaveRequests: (_) => const HrLeaveRequestsScreen(),
        AppRoutes.hrEmployeeDetails: (_) => const HrEmployeeDetailsScreen(),
        AppRoutes.hrQrDisplay: (_) => const HrQrDisplayScreen(),
        AppRoutes.hrReports: (_) => const HrReportsScreen(),
      },
    );
  }
}
