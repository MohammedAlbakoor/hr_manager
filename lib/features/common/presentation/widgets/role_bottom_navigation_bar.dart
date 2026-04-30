import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/app_user_role.dart';

class RoleBottomNavigationBar extends StatelessWidget {
  const RoleBottomNavigationBar({
    super.key,
    required this.role,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final AppUserRole role;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final items = _destinationsForRole(role);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppPalette.border),
            boxShadow: const [
              BoxShadow(
                color: AppPalette.shadow,
                blurRadius: 26,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: items
                  .map(
                    (item) => NavigationDestination(
                      tooltip: item.label,
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  List<_NavItem> _destinationsForRole(AppUserRole role) {
    switch (role) {
      case AppUserRole.employee:
        return const [
          _NavItem(
            label: 'الرئيسية',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
          ),
          _NavItem(
            label: 'الإجازات',
            icon: Icons.event_outlined,
            selectedIcon: Icons.event_available_rounded,
          ),
          _NavItem(
            label: 'الدوام',
            icon: Icons.access_time_outlined,
            selectedIcon: Icons.access_time_filled_rounded,
          ),
          _NavItem(
            label: 'الإشعارات',
            icon: Icons.notifications_outlined,
            selectedIcon: Icons.notifications_rounded,
          ),
          _NavItem(
            label: 'الحساب',
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
          ),
        ];
      case AppUserRole.manager:
        return const [
          _NavItem(
            label: 'الرئيسية',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
          ),
          _NavItem(
            label: 'الطلبات',
            icon: Icons.assignment_outlined,
            selectedIcon: Icons.assignment_rounded,
          ),
          _NavItem(
            label: 'الموظفون',
            icon: Icons.groups_outlined,
            selectedIcon: Icons.groups_rounded,
          ),
          _NavItem(
            label: 'الرسائل',
            icon: Icons.campaign_outlined,
            selectedIcon: Icons.campaign_rounded,
          ),
          _NavItem(
            label: 'الإشعارات',
            icon: Icons.notifications_outlined,
            selectedIcon: Icons.notifications_rounded,
          ),
          _NavItem(
            label: 'الحساب',
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
          ),
        ];
      case AppUserRole.hr:
        return const [
          _NavItem(
            label: 'الرئيسية',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
          ),
          _NavItem(
            label: 'الطلبات',
            icon: Icons.assignment_outlined,
            selectedIcon: Icons.assignment_rounded,
          ),
          _NavItem(
            label: 'الموظفون',
            icon: Icons.groups_outlined,
            selectedIcon: Icons.groups_rounded,
          ),
          _NavItem(
            label: 'الإشعارات',
            icon: Icons.notifications_outlined,
            selectedIcon: Icons.notifications_rounded,
          ),
          _NavItem(
            label: 'الحساب',
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
          ),
        ];
      case AppUserRole.admin:
        return const [
          _NavItem(
            label: 'الإدارة',
            icon: Icons.admin_panel_settings_outlined,
            selectedIcon: Icons.admin_panel_settings_rounded,
          ),
          _NavItem(
            label: 'الاعتمادات',
            icon: Icons.assignment_outlined,
            selectedIcon: Icons.assignment_rounded,
          ),
          _NavItem(
            label: 'الحسابات',
            icon: Icons.supervisor_account_outlined,
            selectedIcon: Icons.supervisor_account_rounded,
          ),
          _NavItem(
            label: 'الإشعارات',
            icon: Icons.notifications_outlined,
            selectedIcon: Icons.notifications_rounded,
          ),
          _NavItem(
            label: 'الحساب',
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
          ),
        ];
    }
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
