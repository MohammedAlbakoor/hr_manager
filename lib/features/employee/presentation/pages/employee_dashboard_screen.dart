import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../attendance/domain/models/attendance_record.dart';
import '../../../common/domain/models/app_dashboard_summary.dart';
import '../../../common/domain/models/app_user_role.dart';
import '../../../common/presentation/widgets/app_empty_state.dart';
import '../../../common/presentation/widgets/app_error_state.dart';
import '../../../common/presentation/widgets/app_loading_state.dart';
import '../../../common/presentation/widgets/responsive_card_grid.dart';
import '../../../common/presentation/widgets/role_bottom_navigation_bar.dart';
import '../../../leave/domain/models/employee_leave_request.dart';
import '../../../leave/presentation/pages/employee_leave_details_screen.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  AppDashboardSummary? _summary;
  List<EmployeeLeaveRequest> _leaveRequests = const [];
  List<AttendanceRecord> _attendanceRecords = const [];
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
        AppServices.commonRepository.fetchDashboardSummary(
          AppUserRole.employee,
        ),
        AppServices.leaveRepository.fetchEmployeeLeaveHistory(),
        AppServices.attendanceRepository.fetchAttendanceHistory(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _summary = results[0] as AppDashboardSummary;
        _leaveRequests = results[1] as List<EmployeeLeaveRequest>;
        _attendanceRecords = results[2] as List<AttendanceRecord>;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'تعذر تحميل لوحة الموظف حالياً.';
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
        Navigator.of(
          context,
        ).pushReplacementNamed(AppRoutes.employeeLeaveHistory);
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
    final summary = _summary;
    final userName = AppServices.session.currentSession?.userName ?? 'الموظف';
    final recentRequests = _leaveRequests.take(3).toList();
    final hasData =
        summary != null ||
        _leaveRequests.isNotEmpty ||
        _attendanceRecords.isNotEmpty;

    final currentBalance =
        summary?.leaveBalanceLabel ??
        (_leaveRequests.isEmpty
            ? '--'
            : _leaveRequests.first.currentBalanceLabel);
    final usedDays =
        summary?.usedLeavesDays ??
        _leaveRequests
            .where((request) => request.status == LeaveRequestStatus.approved)
            .fold<int>(0, (sum, request) => sum + request.daysCount);
    final pendingCount =
        summary?.pendingRequestsCount ??
        _leaveRequests
            .where((request) => request.status == LeaveRequestStatus.pending)
            .length;
    final hasAttendanceToday = summary?.todayAttendanceRecorded ?? false;
    final todayTime =
        summary?.todayCheckInTimeLabel ??
        (_attendanceRecords.isEmpty
            ? '--'
            : _attendanceRecords.first.checkInTimeLabel);
    final todayMethod =
        summary?.todayCheckInMethod ??
        (_attendanceRecords.isEmpty ? '--' : _attendanceRecords.first.method);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.createLeaveRequest);
        },
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text('طلب إجازة'),
      ),
      bottomNavigationBar: RoleBottomNavigationBar(
        role: AppUserRole.employee,
        selectedIndex: 0,
        onDestinationSelected: _handlePrimaryNavigation,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFF8FBFF)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const AppLoadingState(
                  title: 'جاري تحميل لوحة الموظف',
                  message: 'نجهز الرصيد والطلبات وسجل الحضور الحالي.',
                )
              : _errorMessage != null
              ? AppErrorState(
                  title: 'حدث خطأ',
                  message: _errorMessage!,
                  onRetry: _loadDashboard,
                )
              : !hasData
              ? const AppEmptyState(
                  title: 'لا توجد بيانات حالياً',
                  message: 'لم يتم العثور على سجل إجازات أو دوام لعرضه الآن.',
                  icon: Icons.inbox_outlined,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HeroCard(
                            userName: userName,
                            unreadCount: summary?.unreadNotificationsCount ?? 0,
                            onNotifications: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.notifications,
                                arguments: AppUserRole.employee,
                              );
                            },
                            onProfile: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.profileAccount,
                                arguments: AppUserRole.employee,
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          ResponsiveCardGrid(
                            children: [
                              _StatCard(
                                title: 'الرصيد الحالي',
                                value: currentBalance,
                                caption: 'من رصيدك الحقيقي على السيرفر',
                                icon: Icons.wallet_giftcard_rounded,
                              ),
                              _StatCard(
                                title: 'إجازات مستخدمة',
                                value: '$usedDays يوم',
                                caption: 'من الطلبات المعتمدة نهائياً',
                                icon: Icons.event_busy_rounded,
                              ),
                              _StatCard(
                                title: 'طلبات معلقة',
                                value: '$pendingCount',
                                caption: 'بانتظار الموافقات',
                                icon: Icons.pending_actions_rounded,
                              ),
                              _StatCard(
                                title: 'حضور اليوم',
                                value: todayTime,
                                caption: hasAttendanceToday
                                    ? 'تم تسجيل الحضور عبر $todayMethod'
                                    : 'لم يتم تسجيل حضور بعد',
                                icon: Icons.qr_code_2_rounded,
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'إجراءات سريعة',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 14),
                          ResponsiveCardGrid(
                            children: [
                              _ActionCard(
                                title: 'طلب إجازة',
                                subtitle: 'إنشاء طلب جديد بحسب الرصيد المتاح',
                                icon: Icons.event_note_rounded,
                                onTap: () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.createLeaveRequest);
                                },
                              ),
                              _ActionCard(
                                title: 'تسجيل حضور',
                                subtitle: 'مسح QR لتوثيق حضور اليوم',
                                icon: Icons.qr_code_scanner_rounded,
                                onTap: () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.scanQrAttendance);
                                },
                              ),
                              _ActionCard(
                                title: 'سجل الإجازات',
                                subtitle: 'مراجعة كل الطلبات السابقة وحالتها',
                                icon: Icons.history_toggle_off_rounded,
                                onTap: () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.employeeLeaveHistory);
                                },
                              ),
                              _ActionCard(
                                title: 'سجل الدوام',
                                subtitle: 'عرض تواريخ وأوقات الحضور المسجلة',
                                icon: Icons.schedule_rounded,
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                    AppRoutes.employeeAttendanceHistory,
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          _Panel(
                            title: 'آخر طلبات الإجازة',
                            trailing: TextButton(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.employeeLeaveHistory);
                              },
                              child: const Text('عرض الكل'),
                            ),
                            child: recentRequests.isEmpty
                                ? const Text('لا توجد طلبات حديثة حالياً.')
                                : Column(
                                    children: recentRequests
                                        .map(
                                          (request) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: ListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 6,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                side: const BorderSide(
                                                  color: Color(0xFFE2E8F0),
                                                ),
                                              ),
                                              tileColor: const Color(
                                                0xFFF8FAFC,
                                              ),
                                              leading: CircleAvatar(
                                                backgroundColor: request
                                                    .status
                                                    .color
                                                    .withValues(alpha: 0.12),
                                                foregroundColor:
                                                    request.status.color,
                                                child: Icon(
                                                  request.status.icon,
                                                  size: 20,
                                                ),
                                              ),
                                              title: Text(request.title),
                                              subtitle: Text(
                                                request.periodLabel,
                                              ),
                                              trailing: const Icon(
                                                Icons.chevron_left_rounded,
                                              ),
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        EmployeeLeaveDetailsScreen(
                                                          request: request,
                                                        ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          _Panel(
                            title: 'ملخص الحضور',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: hasAttendanceToday
                                        ? const Color(0xFFEAFBF4)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hasAttendanceToday
                                            ? 'تم تسجيل حضور اليوم بنجاح'
                                            : 'لم يتم تسجيل حضور اليوم بعد',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('وقت الدخول: $todayTime'),
                                      const SizedBox(height: 4),
                                      Text('طريقة التسجيل: $todayMethod'),
                                      if ((summary?.todayLocationLabel ?? '')
                                          .isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            'الموقع: ${summary!.todayLocationLabel}',
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 50,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size.fromHeight(
                                              50,
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pushNamed(
                                              AppRoutes.scanQrAttendance,
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.qr_code_scanner_rounded,
                                          ),
                                          label: const Text('مسح QR'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: const Size.fromHeight(
                                              50,
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pushNamed(
                                              AppRoutes
                                                  .employeeAttendanceHistory,
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.history_rounded,
                                          ),
                                          label: const Text('سجل الدوام'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.userName,
    required this.unreadCount,
    required this.onNotifications,
    required this.onProfile,
  });

  final String userName;
  final int unreadCount;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

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
                  'أهلاً $userName',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNotifications,
                tooltip: 'الإشعارات',
                icon: unreadCount > 0
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
              ),
              IconButton(
                onPressed: onProfile,
                tooltip: 'الحساب',
                icon: const Icon(
                  Icons.account_circle_outlined,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'يمكنك من هنا متابعة رصيدك، تقديم طلبات الإجازة، ومسح QR لتسجيل الحضور بسرعة.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
  });

  final String title;
  final String value;
  final String caption;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 255,
      child: _Panel(
        title: title,
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
            const SizedBox(height: 6),
            Text(caption, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
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
    final theme = Theme.of(context);

    return SizedBox(
      width: 255,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: _Panel(
          title: title,
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
              Text(subtitle, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppPalette.primary.withValues(alpha: 0.80),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.border),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
