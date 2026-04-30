import '../../../common/domain/models/app_user_role.dart';

class EmployeeUpsertPayload {
  const EmployeeUpsertPayload({
    required this.name,
    required this.code,
    required this.email,
    required this.phone,
    required this.department,
    required this.jobTitle,
    required this.workLocation,
    required this.workSchedule,
    required this.joinDate,
    this.password,
    this.managerId,
    this.role,
  });

  final String name;
  final String code;
  final String email;
  final String phone;
  final String department;
  final String jobTitle;
  final String workLocation;
  final String workSchedule;
  final String joinDate;
  final String? password;
  final int? managerId;
  final AppUserRole? role;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'code': code,
      'email': email,
      'phone': phone,
      'department': department,
      'job_title': jobTitle,
      'work_location': workLocation,
      'work_schedule': workSchedule,
      'joined_at': joinDate.isEmpty ? null : joinDate,
      'manager_id': managerId,
      'role': role?.name,
    };

    final trimmedPassword = password?.trim();
    if (trimmedPassword != null && trimmedPassword.isNotEmpty) {
      json['password'] = trimmedPassword;
    }

    return json;
  }
}
