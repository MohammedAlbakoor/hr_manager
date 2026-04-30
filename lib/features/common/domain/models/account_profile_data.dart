import 'app_user_role.dart';

class AccountProfileData {
  const AccountProfileData({
    required this.role,
    required this.name,
    required this.code,
    required this.email,
    required this.phone,
    required this.department,
    required this.jobTitle,
    required this.joinDate,
    required this.workSchedule,
    required this.workLocation,
    required this.lastLogin,
    required this.deviceLabel,
    required this.permissions,
  });

  final AppUserRole role;
  final String name;
  final String code;
  final String email;
  final String phone;
  final String department;
  final String jobTitle;
  final String joinDate;
  final String workSchedule;
  final String workLocation;
  final String lastLogin;
  final String deviceLabel;
  final List<String> permissions;

  factory AccountProfileData.fromJson(Map<String, dynamic> json) {
    return AccountProfileData(
      role: AppUserRole.fromStorage(json['role']?.toString()),
      name: json['name']?.toString() ?? '--',
      code: json['code']?.toString() ?? '--',
      email: json['email']?.toString() ?? '--',
      phone: json['phone']?.toString() ?? '--',
      department: json['department']?.toString() ?? '--',
      jobTitle: json['job_title']?.toString() ?? '--',
      joinDate: json['join_date']?.toString() ?? '--',
      workSchedule: json['work_schedule']?.toString() ?? '--',
      workLocation: json['work_location']?.toString() ?? '--',
      lastLogin: json['last_login']?.toString() ?? '--',
      deviceLabel: json['device_label']?.toString() ?? '--',
      permissions: (json['permissions'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role.name,
      'name': name,
      'code': code,
      'email': email,
      'phone': phone,
      'department': department,
      'job_title': jobTitle,
      'join_date': joinDate,
      'work_schedule': workSchedule,
      'work_location': workLocation,
      'last_login': lastLogin,
      'device_label': deviceLabel,
      'permissions': permissions,
    };
  }
}
