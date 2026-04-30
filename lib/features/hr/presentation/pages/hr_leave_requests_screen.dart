import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/services/app_services.dart';
import '../../../common/domain/models/app_user_role.dart';
import '../../../common/presentation/widgets/app_empty_state.dart';
import '../../../common/presentation/widgets/app_error_state.dart';
import '../../../common/presentation/widgets/app_loading_state.dart';
import '../../../common/presentation/widgets/role_bottom_navigation_bar.dart';
import '../../domain/models/hr_leave_request.dart';
import 'hr_leave_request_details_screen.dart';

class HrLeaveRequestsScreen extends StatefulWidget {
  const HrLeaveRequestsScreen({super.key});

  @override
  State<HrLeaveRequestsScreen> createState() => _HrLeaveRequestsScreenState();
}

class _HrLeaveRequestsScreenState extends State<HrLeaveRequestsScreen> {
  List<HrLeaveRequest> _requests = const [];
  HrRequestsFilter _selectedFilter = HrRequestsFilter.all;
  bool _isLoading = true;
  String? _errorMessage;

  AppUserRole get _role =>
      AppServices.session.currentSession?.role == AppUserRole.admin
      ? AppUserRole.admin
      : AppUserRole.hr;

  @override
  void initState() {
    super.initState();
    unawaited(_loadRequests());
  }

  List<HrLeaveRequest> get _filteredRequests {
    switch (_selectedFilter) {
      case HrRequestsFilter.all:
        return _requests;
      case HrRequestsFilter.waitingManager:
        return _requests
            .where(
              (request) =>
                  request.status == HrLeaveWorkflowStatus.waitingManager,
            )
            .toList();
      case HrRequestsFilter.pendingHr:
        return _requests
            .where(
              (request) => request.status == HrLeaveWorkflowStatus.pendingHr,
            )
            .toList();
      case HrRequestsFilter.approved:
        return _requests
            .where(
              (request) => request.status == HrLeaveWorkflowStatus.approved,
            )
            .toList();
      case HrRequestsFilter.rejected:
        return _requests
            .where(
              (request) => request.status == HrLeaveWorkflowStatus.rejected,
            )
            .toList();
    }
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requests = await AppServices.leaveRepository.fetchHrLeaveRequests();
      if (!mounted) {
        return;
      }

      setState(() {
        _requests = requests;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'تعذر تحميل طلبات الإجازة حالياً.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openDetails(HrLeaveRequest request) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HrLeaveRequestDetailsScreen(request: request),
      ),
    );
  }

  void _handlePrimaryNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(
          _role == AppUserRole.admin
              ? AppRoutes.adminDashboard
              : AppRoutes.hrDashboard,
        );
        return;
      case 1:
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
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final cardWidth = isWide
        ? 250.0
        : ((width - 40).clamp(240.0, 460.0)).toDouble();

    final pendingHrCount = _requests
        .where((request) => request.status == HrLeaveWorkflowStatus.pendingHr)
        .length;
    final approvedCount = _requests
        .where((request) => request.status == HrLeaveWorkflowStatus.approved)
        .length;
    final rejectedCount = _requests
        .where((request) => request.status == HrLeaveWorkflowStatus.rejected)
        .length;

    return Scaffold(
      bottomNavigationBar: RoleBottomNavigationBar(
        role: _role,
        selectedIndex: 1,
        onDestinationSelected: _handlePrimaryNavigation,
      ),
      appBar: AppBar(title: const Text('طلبات الإجازة'), centerTitle: true),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFF0F9FF)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Hero(
                      pendingHrCount: pendingHrCount,
                      approvedCount: approvedCount,
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children:
                          [
                                _SummaryCard(
                                  title: 'بانتظار HR',
                                  value: '$pendingHrCount',
                                  icon: Icons.approval_outlined,
                                  color: const Color(0xFF1D4ED8),
                                ),
                                _SummaryCard(
                                  title: 'معتمدة نهائياً',
                                  value: '$approvedCount',
                                  icon: Icons.verified_outlined,
                                  color: const Color(0xFF0F766E),
                                ),
                                _SummaryCard(
                                  title: 'مرفوضة',
                                  value: '$rejectedCount',
                                  icon: Icons.cancel_outlined,
                                  color: const Color(0xFFDC2626),
                                ),
                              ]
                              .map(
                                (card) =>
                                    SizedBox(width: cardWidth, child: card),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'قائمة الطلبات',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 14),
                          if (_isLoading)
                            const AppLoadingState(
                              title: 'جاري تحميل الطلبات',
                              message:
                                  'نجهز الطلبات المحالة إلى الموارد البشرية.',
                            )
                          else if (_errorMessage != null)
                            AppErrorState(
                              title: 'حدث خطأ',
                              message: _errorMessage!,
                              onRetry: _loadRequests,
                            )
                          else ...[
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: HrRequestsFilter.values
                                  .map(
                                    (filter) => ChoiceChip(
                                      label: Text(filter.label),
                                      selected: _selectedFilter == filter,
                                      onSelected: (_) {
                                        setState(() {
                                          _selectedFilter = filter;
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 18),
                            if (_filteredRequests.isEmpty)
                              const AppEmptyState(
                                title: 'لا توجد طلبات',
                                message:
                                    'لا يوجد أي طلب ضمن الفلتر الحالي حالياً.',
                                icon: Icons.assignment_outlined,
                              )
                            else
                              ..._filteredRequests.map(
                                (request) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _RequestCard(
                                    request: request,
                                    onTap: () => _openDetails(request),
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum HrRequestsFilter {
  all('الكل'),
  waitingManager('بانتظار المدير'),
  pendingHr('بانتظار HR'),
  approved('معتمدة'),
  rejected('مرفوضة');

  const HrRequestsFilter(this.label);

  final String label;
}

class _Hero extends StatelessWidget {
  const _Hero({required this.pendingHrCount, required this.approvedCount});

  final int pendingHrCount;
  final int approvedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF2A0F20), Color(0xFF5C1041), Color(0xFFD81DB9)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'طلبات الموارد البشرية',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'كل طلب يعرض لك حالة المدير أولاً، ثم يمكنك اتخاذ القرار النهائي عندما يصبح جاهزاً للموارد البشرية.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroTag(label: 'بانتظار HR: $pendingHrCount'),
              _HeroTag(label: 'معتمدة: $approvedCount'),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onTap});

  final HrLeaveRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: request.status.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(request.status.icon, color: request.status.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          request.employeeName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      _StatusChip(status: request.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${request.leaveType} - ${request.periodLabel}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${request.department} • ${request.daysCount} يوم • ${request.managerStatusLabel}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_left_rounded),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final HrLeaveWorkflowStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: status.color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
