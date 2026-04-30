import '../../features/common/domain/models/app_user_role.dart';
import 'app_routes.dart';

String homeRouteForRole(AppUserRole role) {
  switch (role) {
    case AppUserRole.employee:
      return AppRoutes.employeeDashboard;
    case AppUserRole.manager:
      return AppRoutes.managerDashboard;
    case AppUserRole.hr:
      return AppRoutes.hrDashboard;
    case AppUserRole.admin:
      return AppRoutes.adminDashboard;
  }
}
