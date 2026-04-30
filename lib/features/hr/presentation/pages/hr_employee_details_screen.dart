import 'package:flutter/material.dart';

import '../../../../core/services/app_services.dart';
import '../../../common/domain/models/app_user_role.dart';
import '../../../common/presentation/pages/employee_management_screen.dart';
import '../../../manager/domain/models/manager_employee_profile.dart';

class HrEmployeeDetailsScreen extends StatelessWidget {
  const HrEmployeeDetailsScreen({super.key, this.profile});

  final ManagerEmployeeProfile? profile;

  @override
  Widget build(BuildContext context) {
    final role = AppServices.session.currentSession?.role == AppUserRole.admin
        ? AppUserRole.admin
        : AppUserRole.hr;

    return EmployeeManagementScreen(role: role, initialProfile: profile);
  }
}
