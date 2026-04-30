import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/services/app_services.dart';
import '../../../common/domain/models/app_user_role.dart';
import '../../../common/presentation/widgets/app_empty_state.dart';
import '../../../common/presentation/widgets/app_error_state.dart';
import '../../../common/presentation/widgets/app_loading_state.dart';
import '../../../common/presentation/widgets/role_bottom_navigation_bar.dart';
import '../../domain/models/employee_leave_request.dart';
import 'employee_leave_details_screen.dart';

class EmployeeLeaveHistoryScreen extends StatefulWidget {
  const EmployeeLeaveHistoryScreen({super.key});

  @override
  State<EmployeeLeaveHistoryScreen> createState() =>
      _EmployeeLeaveHistoryScreenState();
}

class _EmployeeLeaveHistoryScreenState
    extends State<EmployeeLeaveHistoryScreen> {
  List<EmployeeLeaveRequest> _requests = const [];
  LeaveHistoryFilter _selectedFilter = LeaveHistoryFilter.all;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadLeaveHistory());
  }

  List<EmployeeLeaveRequest> get _filteredRequests {
    switch (_selectedFilter) {
      case LeaveHistoryFilter.all:
        return _requests;
      case LeaveHistoryFilter.pending:
        return _requests
            .where((request) => request.status == LeaveRequestStatus.pending)
            .toList();
      case LeaveHistoryFilter.approved:
        return _requests
            .where((request) => request.status == LeaveRequestStatus.approved)
            .toList();
      case LeaveHistoryFilter.rejected:
        return _requests
            .where((request) => request.status == LeaveRequestStatus.rejected)
            .toList();
    }
  }

  Future<void> _loadLeaveHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requests = await AppServices.leaveRepository
          .fetchEmployeeLeaveHistory();
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
        _errorMessage = 'تعذر تحميل سجل الإجازات حالياً.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openDetails(EmployeeLeaveRequest request) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmployeeLeaveDetailsScreen(request: request),
      ),
    );
  }

  void _handlePrimaryNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRoutes.employeeDashboard);
        return;
      case 1:
        return;
      case 2:
        Navigator.of(
          context,
        ).pushReplacementNamed(AppRoutes.employeeAttendanceHistory);
        return;
      case 3:
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.notifications,
          arguments: AppUserRole.employee,
        );
        return;
      case 4:
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.profileAccount,
          arguments: AppUserRole.employee,
        );
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

    final approvedCount = _requests
        .where((request) => request.status == LeaveRequestStatus.approved)
        .length;
    final pendingCount = _requests
        .where((request) => request.status == LeaveRequestStatus.pending)
        .length;
    final rejectedCount = _requests
        .where((request) => request.status == LeaveRequestStatus.rejected)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('سجل الإجازات'), centerTitle: true),
      bottomNavigationBar: RoleBottomNavigationBar(
        role: AppUserRole.employee,
        selectedIndex: 1,
        onDestinationSelected: _handlePrimaryNavigation,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.createLeaveRequest);
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text('طلب جديد'),
      ),
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
                    _LeaveHistoryHero(
                      totalRequests: _requests.length,
                      approvedCount: approvedCount,
                      pendingCount: pendingCount,
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children:
                          [
                                _HistorySummaryStat(
                                  title: 'كل الطلبات',
                                  value: '${_requests.length}',
                                  icon: Icons.inventory_2_outlined,
                                  color: const Color(0xFF1D4ED8),
                                ),
                                _HistorySummaryStat(
                                  title: 'طلبات معلقة',
                                  value: '$pendingCount',
                                  icon: Icons.pending_actions_rounded,
                                  color: const Color(0xFF7C3AED),
                                ),
                                _HistorySummaryStat(
                                  title: 'طلبات معتمدة',
                                  value: '$approvedCount',
                                  icon: Icons.check_circle_outline_rounded,
                                  color: const Color(0xFF0F766E),
                                ),
                                _HistorySummaryStat(
                                  title: 'طلبات مرفوضة',
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
                              title: 'جاري تحميل الإجازات',
                              message: 'نجهز الطلبات السابقة وتفاصيلها.',
                            )
                          else if (_errorMessage != null)
                            AppErrorState(
                              title: 'حدث خطأ',
                              message: _errorMessage!,
                              onRetry: _loadLeaveHistory,
                            )
                          else ...[
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: LeaveHistoryFilter.values
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
                                    'لا يوجد أي طلب إجازة ضمن الفلتر الحالي.',
                                icon: Icons.event_busy_outlined,
                              )
                            else
                              ..._filteredRequests.map(
                                (request) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _HistoryRequestCard(
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

enum LeaveHistoryFilter {
  all('الكل'),
  pending('قيد الانتظار'),
  approved('موافق عليه'),
  rejected('مرفوض');

  const LeaveHistoryFilter(this.label);

  final String label;
}

class _LeaveHistoryHero extends StatelessWidget {
  const _LeaveHistoryHero({
    required this.totalRequests,
    required this.approvedCount,
    required this.pendingCount,
  });

  final int totalRequests;
  final int approvedCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0F172A), Color(0xFF102A5C), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'كل طلبات الإجازة في مكان واحد',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'يمكنك متابعة حالة كل طلب، ومعرفة ما إذا كان بانتظار الموافقة أو تم اعتماده أو رفضه.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroTag(label: 'إجمالي الطلبات: $totalRequests'),
              _HeroTag(label: 'معتمدة: $approvedCount'),
              _HeroTag(label: 'قيد الانتظار: $pendingCount'),
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

class _HistorySummaryStat extends StatelessWidget {
  const _HistorySummaryStat({
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

class _HistoryRequestCard extends StatelessWidget {
  const _HistoryRequestCard({required this.request, required this.onTap});

  final EmployeeLeaveRequest request;
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
                          request.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      _RequestStatusChip(status: request.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    request.periodLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    request.note,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _MiniBadge(
                        label: '${request.daysCount} يوم',
                        color: const Color(0xFFEA580C),
                      ),
                      const SizedBox(width: 8),
                      _MiniBadge(
                        label: request.id,
                        color: const Color(0xFF1D4ED8),
                      ),
                    ],
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

class _RequestStatusChip extends StatelessWidget {
  const _RequestStatusChip({required this.status});

  final LeaveRequestStatus status;

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

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
