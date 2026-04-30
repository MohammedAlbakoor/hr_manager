import 'package:flutter/material.dart';

import '../../../common/domain/models/app_user_role.dart';
import '../../../common/presentation/pages/employee_management_screen.dart';
import '../../domain/models/manager_employee_profile.dart';

class ManagerEmployeeDetailsScreen extends StatelessWidget {
  const ManagerEmployeeDetailsScreen({super.key, this.profile});

  final ManagerEmployeeProfile? profile;

  @override
  Widget build(BuildContext context) {
    return EmployeeManagementScreen(
      role: AppUserRole.manager,
      initialProfile: profile,
    );
  }
}
