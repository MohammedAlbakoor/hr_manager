import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../common/domain/models/app_dashboard_summary.dart';
import '../../../common/domain/models/app_user_role.dart';
import '../../../common/presentation/widgets/app_error_state.dart';
import '../../../common/presentation/widgets/app_loading_state.dart';
import '../../../common/presentation/widgets/responsive_card_grid.dart';
import '../../../common/presentation/widgets/role_bottom_navigation_bar.dart';
import '../../../manager/domain/models/manager_employee_profile.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AppDashboardSummary? _summary;
  List<ManagerEmployeeProfile> _profiles = const [];
  bool _isLoading = true;
  String? _errorMessage;

  int get _employeeCount =>
      _profiles.where((profile) => profile.role == AppUserRole.employee).length;
  int get _managerCount =>
      _profiles.where((profile) => profile.role == AppUserRole.manager).length;
  int get _hrCount =>
      _profiles.where((profile) => profile.role == AppUserRole.hr).length;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDashboard());
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        AppServices.commonRepository.fetchDashboardSummary(AppUserRole.admin),
        AppServices.employeeProfileRepository.fetchEmployeeProfiles(),
      ]);
      if (!mounted) {
        return;
      }

      setState(() {
        _summary = results[0] as AppDashboardSummary;
        _profiles = results[1] as List<ManagerEmployeeProfile>;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'تعذر تحميل لوحة الإدارة حاليا.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handlePrimaryNavigation(int index) {
    switch (index) {
      case 0:
        return;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.hrLeaveRequests);
        return;
      case 2:
        Navigator.of(context).pushReplacementNamed(AppRoutes.hrEmployeeDetails);
        return;
      case 3:
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.notifications,
          arguments: AppUserRole.admin,
        );
        return;
      case 4:
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.profileAccount,
          arguments: AppUserRole.admin,
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Scaffold(
      bottomNavigationBar: RoleBottomNavigationBar(
        role: AppUserRole.admin,
        selectedIndex: 0,
        onDestinationSelected: _handlePrimaryNavigation,
      ),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingState(
                title: 'جاري تحميل لوحة الإدارة',
                message: 'نجهز الحسابات والاعتمادات ونظرة النظام العامة.',
              )
            : _errorMessage != null
            ? AppErrorState(
                title: 'تعذر تحميل اللوحة',
                message: _errorMessage!,
                onRetry: _loadDashboard,
              )
            : RefreshIndicator(
                onRefresh: _loadDashboard,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  children: [
                    _AdminHero(
                      unreadCount: summary?.unreadNotificationsCount ?? 0,
                      accountCount: _profiles.length,
                      pendingHrCount: summary?.pendingHrCount ?? 0,
                    ),
                    const SizedBox(height: 20),
                    ResponsiveCardGrid(
                      children: [
                        _Metric(
                          title: 'الموظفون',
                          value: '$_employeeCount',
                          icon: Icons.badge_outlined,
                          color: const Color(0xFF2563EB),
                        ),
                        _Metric(
                          title: 'المديرون',
                          value: '$_managerCount',
                          icon: Icons.manage_accounts_outlined,
                          color: const Color(0xFFB45309),
                        ),
                        _Metric(
                          title: 'حسابات الموارد البشرية',
                          value: '$_hrCount',
                          icon: Icons.groups_2_outlined,
                          color: const Color(0xFF7C3AED),
                        ),
                        _Metric(
                          title: 'الاعتمادات النهائية',
                          value: '${summary?.approvedRequestsCount ?? 0}',
                          icon: Icons.verified_outlined,
                          color: const Color(0xFF0F766E),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ResponsiveCardGrid(
                      children: [
                        _Action(
                          title: 'إدارة الحسابات',
                          subtitle:
                              'إنشاء وتعديل حسابات المديرين والموارد البشرية والموظفين.',
                          icon: Icons.supervisor_account_outlined,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.hrEmployeeDetails),
                        ),
                        _Action(
                          title: 'اعتمادات الإجازات',
                          subtitle: 'مراجعة الطلبات بعد موافقة المدير.',
                          icon: Icons.assignment_turned_in_outlined,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.hrLeaveRequests),
                        ),
                        _Action(
                          title: 'التقارير',
                          subtitle: 'فتح تقارير الحضور والإجازات.',
                          icon: Icons.table_chart_outlined,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.hrReports),
                        ),
                        _Action(
                          title: 'رمز الحضور QR',
                          subtitle: 'عرض رمز الحضور المحلي للموظفين.',
                          icon: Icons.qr_code_2_rounded,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.hrQrDisplay),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _AdminPanel(
                      summary: summary,
                      accountCount: _profiles.length,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _AdminHero extends StatelessWidget {
  const _AdminHero({
    required this.unreadCount,
    required this.accountCount,
    required this.pendingHrCount,
  });

  final int unreadCount;
  final int accountCount;
  final int pendingHrCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF7C2D12), Color(0xFFB45309)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'لوحة إدارة النظام',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (unreadCount > 0)
                Badge(
                  label: Text('$unreadCount'),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'تحكم مركزي بحسابات المديرين والموارد البشرية وسجلات الموظفين والتقارير والاعتمادات النهائية.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroTag(label: 'الحسابات: $accountCount'),
              _HeroTag(label: 'بانتظار الاعتماد النهائي: $pendingHrCount'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 255,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 255,
      height: 196,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: AppPalette.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: AppPalette.warning),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_back_rounded,
                  color: AppPalette.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminPanel extends StatelessWidget {
  const _AdminPanel({required this.summary, required this.accountCount});

  final AppDashboardSummary? summary;
  final int accountCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ملخص الإدارة', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _AdminInfoLine(label: 'الحسابات المدارة', value: '$accountCount'),
            _AdminInfoLine(
              label: 'الطلبات المرفوضة',
              value: '${summary?.rejectedRequestsCount ?? 0}',
            ),
            _AdminInfoLine(
              label: 'الإشعارات غير المقروءة',
              value: '${summary?.unreadNotificationsCount ?? 0}',
            ),
            const SizedBox(height: 10),
            Text(
              'استخدم إدارة الحسابات لإنشاء أو تعديل حسابات المديرين والموارد البشرية والموظفين.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminInfoLine extends StatelessWidget {
  const _AdminInfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
