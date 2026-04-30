import 'package:flutter/material.dart';

enum AppUserRole {
  employee(
    label: 'موظف',
    subtitle: 'طلبات الإجازة والحضور',
    icon: Icons.person_outline_rounded,
    color: Color(0xFF1D4ED8),
  ),
  manager(
    label: 'مدير مباشر',
    subtitle: 'إدارة الفريق والموافقات',
    icon: Icons.manage_accounts_outlined,
    color: Color(0xFF0F766E),
  ),
  hr(
    label: 'موارد بشرية',
    subtitle: 'مراجعة السجلات والاعتمادات',
    icon: Icons.approval_outlined,
    color: Color(0xFF7C3AED),
  ),
  admin(
    label: 'Admin',
    subtitle: 'Full system administration',
    icon: Icons.admin_panel_settings_outlined,
    color: Color(0xFFB45309),
  );

  const AppUserRole({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;

  static AppUserRole fromStorage(String? value) {
    switch (value?.toLowerCase()) {
      case 'manager':
        return AppUserRole.manager;
      case 'hr':
        return AppUserRole.hr;
      case 'admin':
        return AppUserRole.admin;
      default:
        return AppUserRole.employee;
    }
  }
}
