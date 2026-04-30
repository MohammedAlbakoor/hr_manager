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
import '../../domain/models/hr_leave_request.dart';
import 'hr_leave_request_details_screen.dart';

class HrDashboardScreen extends StatefulWidget {
  const HrDashboardScreen({super.key});

  @override
  State<HrDashboardScreen> createState() => _HrDashboardScreenState();
}

class _HrDashboardScreenState extends State<HrDashboardScreen> {
  AppDashboardSummary? _summary;
  List<HrLeaveRequest> _requests = const [];
  bool _isLoading = true;
  String? _errorMessage;

  AppUserRole get _role =>
      AppServices.session.currentSession?.role == AppUserRole.admin
      ? AppUserRole.admin
      : AppUserRole.hr;

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
        AppServices.commonRepository.fetchDashboardSummary(_role),
        AppServices.leaveRepository.fetchHrLeaveRequests(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = results[0] as AppDashboardSummary;
        _requests = results[1] as List<HrLeaveRequest>;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'تعذر تحميل لوحة الموارد البشرية حالياً.';
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
        Navigator.of(context).pushReplacementNamed(AppRoutes.hrLeaveRequests);
        return;
      case 2:
        Navigator.of(context).pushReplacementNamed(AppRoutes.hrEmployeeDetails);
        return;
      case 3:
        Navigator.of(
          context,
        ).pushReplacementNamed(AppRoutes.notifications, arguments: _role);
        return;
      case 4:
        Navigator.of(
          context,
        ).pushReplacementNamed(AppRoutes.profileAccount, arguments: _role);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final pendingHrRequests = _requests
        .where((request) => request.status == HrLeaveWorkflowStatus.pendingHr)
        .toList();

    return Scaffold(
      bottomNavigationBar: RoleBottomNavigationBar(
        role: _role,
        selectedIndex: 0,
        onDestinationSelected: (index) =>
            _handlePrimaryNavigation(context, index),
      ),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingState(
                title: 'جاري تحميل لوحة الموارد البشرية',
                message: 'نجهز الطلبات والسجلات والإحصاءات الحالية.',
              )
            : _errorMessage != null
            ? AppErrorState(
                title: 'حدث خطأ',
                message: _errorMessage!,
                onRetry: _loadDashboard,
              )
            : summary == null || summary.employeeCount == 0
            ? const AppEmptyState(
                title: 'لا توجد بيانات موظفين',
                message: 'لم يتم العثور على سجلات موظفين متاحة حالياً.',
                icon: Icons.groups_outlined,
              )
            : RefreshIndicator(
                onRefresh: _loadDashboard,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  children: [
                    _Hero(
                      unreadCount: summary.unreadNotificationsCount,
                      pendingHrCount: summary.pendingHrCount,
                      waitingManagerCount: summary.waitingManagerCount,
                    ),
                    const SizedBox(height: 20),
                    ResponsiveCardGrid(
                      children: [
                        _Metric(
                          'طلبات بانتظار HR',
                          '${summary.pendingHrCount}',
                          Icons.approval_outlined,
                        ),
                        _Metric(
                          'عدد الموظفين',
                          '${summary.employeeCount}',
                          Icons.groups_2_outlined,
                        ),
                        _Metric(
                          'اعتمادات نهائية',
                          '${summary.approvedRequestsCount}',
                          Icons.verified_outlined,
                        ),
                        _Metric(
                          'طلبات مرفوضة',
                          '${summary.rejectedRequestsCount}',
                          Icons.cancel_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ResponsiveCardGrid(
                      children: [
                        _Action(
                          'طلبات الإجازة',
                          'فتح قائمة الطلبات ومراجعتها',
                          Icons.assignment_outlined,
                          () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.hrLeaveRequests),
                        ),
                        _Action(
                          'إدارة الموظفين',
                          'بحث وفلترة وإدارة المحذوفين واسترجاعهم',
                          Icons.folder_shared_outlined,
                          () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.hrEmployeeDetails),
                        ),
                        _Action(
                          'عرض QR',
                          'إظهار رمز الحضور للموظفين',
                          Icons.qr_code_2_rounded,
                          () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.hrQrDisplay),
                        ),
                        _Action(
                          'التقارير',
                          'تصدير CSV للحضور والإجازات',
                          Icons.table_chart_outlined,
                          () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.hrReports),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'نظرة سريعة',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            Text('طلبات بانتظار HR: ${summary.pendingHrCount}'),
                            const SizedBox(height: 8),
                            Text(
                              'طلبات ما زالت عند المدير: ${summary.waitingManagerCount}',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'طلبات موقوفة: ${summary.rejectedRequestsCount}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'طلبات تحتاج قرار HR',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            if (pendingHrRequests.isEmpty)
                              const Text('لا توجد طلبات محالة إلى HR حالياً.')
                            else
                              ...pendingHrRequests.map(
                                (request) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(request.employeeName),
                                  subtitle: Text(
                                    '${request.leaveType} - ${request.periodLabel}',
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_left_rounded,
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            HrLeaveRequestDetailsScreen(
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
                    ),
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
    required this.pendingHrCount,
    required this.waitingManagerCount,
  });

  final int unreadCount;
  final int pendingHrCount;
  final int waitingManagerCount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1DCBB7), Color(0xFF105C53), Color(0xFF0F2D25)],
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
                'لوحة الموارد البشرية',
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
          'طلبات جاهزة لاعتماد HR: $pendingHrCount',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'طلبات ما زالت بانتظار المدير: $waitingManagerCount',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.title, this.value, this.icon);
  final String title;
  final String value;
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
                  color: AppPalette.secondary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppPalette.secondary),
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
                    color: AppPalette.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: AppPalette.primary),
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
