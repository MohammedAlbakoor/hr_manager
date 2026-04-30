import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../common/domain/models/app_dashboard_summary.dart';
import '../../../common/domain/models/app_user_role.dart';
import '../../../common/presentation/widgets/app_empty_state.dart';
import '../../../common/presentation/widgets/app_error_state.dart';
import '../../../common/presentation/widgets/app_loading_state.dart';
import '../../../common/presentation/widgets/responsive_card_grid.dart';
import '../../../common/presentation/widgets/role_bottom_navigation_bar.dart';
import '../../domain/models/manager_leave_request.dart';
import 'manager_leave_request_details_screen.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  AppDashboardSummary? _summary;
  List<ManagerLeaveRequest> _requests = const [];
  bool _isLoading = true;
  String? _errorMessage;

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
      final results = await Future.wait([
        AppServices.commonRepository.fetchDashboardSummary(AppUserRole.manager),
        AppServices.leaveRepository.fetchManagerLeaveRequests(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = results[0] as AppDashboardSummary;
        _requests = results[1] as List<ManagerLeaveRequest>;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'تعذر تحميل لوحة المدير حالياً.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handlePrimaryNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        return;
      case 1:
        Navigator.of(
          context,
        ).pushReplacementNamed(AppRoutes.managerLeaveRequests);
        return;
      case 2:
        Navigator.of(
          context,
        ).pushReplacementNamed(AppRoutes.managerEmployeeDetails);
        return;
      case 3:
        Navigator.of(context).pushReplacementNamed(AppRoutes.managerBroadcasts);
        return;
      case 4:
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.notifications,
          arguments: AppUserRole.manager,
        );
        return;
      case 5:
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.profileAccount,
          arguments: AppUserRole.manager,
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final pendingRequests = _requests
        .where(
          (request) =>
              request.status == ManagerLeaveWorkflowStatus.pendingReview,
        )
        .toList();

    return Scaffold(
      bottomNavigationBar: RoleBottomNavigationBar(
        role: AppUserRole.manager,
        selectedIndex: 0,
        onDestinationSelected: (index) =>
            _handlePrimaryNavigation(context, index),
      ),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingState(
                title: 'جاري تحميل لوحة المدير',
                message: 'نجهز الطلبات والفريق والإحصاءات الحالية.',
              )
            : _errorMessage != null
            ? AppErrorState(
                title: 'حدث خطأ',
                message: _errorMessage!,
                onRetry: _loadDashboard,
              )
            : summary == null || summary.employeeCount == 0
            ? const AppEmptyState(
                title: 'لا توجد بيانات فريق',
                message: 'لم يتم العثور على موظفين ضمن فريق المدير حالياً.',
                icon: Icons.groups_outlined,
              )
            : RefreshIndicator(
                onRefresh: _loadDashboard,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  children: [
                    _Hero(
                      unreadCount: summary.unreadNotificationsCount,
                      pendingCount: summary.pendingRequestsCount,
                      employeeCount: summary.employeeCount,
                    ),
                    const SizedBox(height: 20),
                    ResponsiveCardGrid(
                      children: [
                        _Metric(
                          'طلبات معلقة',
                          '${summary.pendingRequestsCount}',
                          'تحتاج قرار المدير الآن',
                          Icons.pending_actions_rounded,
                        ),
                        _Metric(
                          'عدد الموظفين',
                          '${summary.employeeCount}',
                          'ضمن فريق المدير المباشر',
                          Icons.groups_2_outlined,
                        ),
                        _Metric(
                          'مراجعات منجزة',
                          '${summary.reviewedByManagerCount}',
                          'تم اتخاذ قرار عليها من المدير',
                          Icons.fact_check_outlined,
                        ),
                        _Metric(
                          'متوسط الزيادة',
                          summary.averageMonthlyIncrementLabel,
                          'متوسط الزيادة الشهرية الحالية',
                          Icons.trending_up_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ResponsiveCardGrid(
                      children: [
                        _Action(
                          'طلبات الإجازة',
                          'عرض كل طلبات الفريق ومراجعتها',
                          Icons.assignment_outlined,
                          () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.managerLeaveRequests),
                        ),
                        _Action(
                          'تفاصيل الموظفين',
                          'بحث وفلترة وإدارة المحذوفين',
                          Icons.badge_outlined,
                          () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.managerEmployeeDetails),
                        ),
                        _Action(
                          'الرسائل الجماعية',
                          'إرسال الرسائل العامة أو المخصصة ومراجعتها لاحقًا',
                          Icons.outbox_outlined,
                          () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.managerBroadcasts),
                        ),
                        _Action(
                          'سياسة الإجازات',
                          'تعديل الزيادة الشهرية للفريق',
                          Icons.settings_suggest_outlined,
                          () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.managerLeavePolicy),
                        ),
                        _Action(
                          'عرض QR',
                          'إظهار رمز الحضور للموظفين',
                          Icons.qr_code_2_rounded,
                          () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.managerQrDisplay),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _Snapshot(
                      attendanceLabel: summary.attendanceTodayRatioLabel,
                      leavesLabel: '${summary.leavesThisWeekCount} طلب',
                      followUpLabel: '${summary.followUpCasesCount}',
                    ),
                    const SizedBox(height: 20),
                    _RequestsPanel(requests: pendingRequests),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.unreadCount,
    required this.pendingCount,
    required this.employeeCount,
  });

  final int unreadCount;
  final int pendingCount;
  final int employeeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF102A5C), Color(0xFF1D4ED8)],
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
              Expanded(
                child: Text(
                  'لوحة المدير المباشر',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              unreadCount > 0
                  ? Badge(
                      label: Text('$unreadCount'),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                    ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'الطلبات المعلقة الآن: $pendingCount',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'عدد الموظفين في الفريق: $employeeCount',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.title, this.value, this.caption, this.icon);
  final String title;
  final String value;
  final String caption;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  color: AppPalette.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppPalette.primary),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(caption, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(this.title, this.subtitle, this.icon, this.onTap);
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 255,
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
                    color: AppPalette.secondary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: AppPalette.secondary),
                ),
                const SizedBox(height: 12),
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(subtitle, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
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

class _Snapshot extends StatelessWidget {
  const _Snapshot({
    required this.attendanceLabel,
    required this.leavesLabel,
    required this.followUpLabel,
  });

  final String attendanceLabel;
  final String leavesLabel;
  final String followUpLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نظرة سريعة على الفريق',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SnapshotItem(
                  icon: Icons.how_to_reg_rounded,
                  label: 'حضور اليوم',
                  value: attendanceLabel,
                ),
                _SnapshotItem(
                  icon: Icons.event_available_rounded,
                  label: 'إجازات هذا الأسبوع',
                  value: leavesLabel,
                ),
                _SnapshotItem(
                  icon: Icons.flag_rounded,
                  label: 'تحتاج متابعة',
                  value: followUpLabel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SnapshotItem extends StatelessWidget {
  const _SnapshotItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppPalette.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.titleSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestsPanel extends StatelessWidget {
  const _RequestsPanel({required this.requests});
  final List<ManagerLeaveRequest> requests;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'طلبات تحتاج قراراً الآن',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (requests.isEmpty)
            const Text('لا توجد طلبات معلقة حالياً.')
          else
            ...requests
                .take(3)
                .map(
                  (request) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(request.employeeName),
                    subtitle: Text(
                      '${request.leaveType} - ${request.periodLabel}',
                    ),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ManagerLeaveRequestDetailsScreen(
                            request: request,
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    ),
  );
}
