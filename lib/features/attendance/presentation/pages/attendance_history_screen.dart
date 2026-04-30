import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/services/app_services.dart';
import '../../../common/domain/models/app_user_role.dart';
import '../../../common/presentation/widgets/app_empty_state.dart';
import '../../../common/presentation/widgets/app_error_state.dart';
import '../../../common/presentation/widgets/app_loading_state.dart';
import '../../../common/presentation/widgets/role_bottom_navigation_bar.dart';
import '../../domain/models/attendance_record.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<AttendanceRecord> _records = const [];
  AttendanceFilter _selectedFilter = AttendanceFilter.all;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAttendanceHistory());
  }

  List<AttendanceRecord> get _filteredRecords {
    switch (_selectedFilter) {
      case AttendanceFilter.all:
        return _records;
      case AttendanceFilter.present:
        return _records
            .where((record) => record.status == AttendanceRecordStatus.present)
            .toList();
      case AttendanceFilter.late:
        return _records
            .where((record) => record.status == AttendanceRecordStatus.late)
            .toList();
      case AttendanceFilter.absent:
        return _records
            .where((record) => record.status == AttendanceRecordStatus.absent)
            .toList();
    }
  }

  Future<void> _loadAttendanceHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final records = await AppServices.attendanceRepository
          .fetchAttendanceHistory();
      if (!mounted) {
        return;
      }

      setState(() {
        _records = records;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'تعذر تحميل سجل الدوام حالياً.';
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
        Navigator.of(context).pushReplacementNamed(AppRoutes.employeeDashboard);
        return;
      case 1:
        Navigator.of(
          context,
        ).pushReplacementNamed(AppRoutes.employeeLeaveHistory);
        return;
      case 2:
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

    final presentCount = _records
        .where((record) => record.status == AttendanceRecordStatus.present)
        .length;
    final lateCount = _records
        .where((record) => record.status == AttendanceRecordStatus.late)
        .length;
    final absentCount = _records
        .where((record) => record.status == AttendanceRecordStatus.absent)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('سجل الدوام'), centerTitle: true),
      bottomNavigationBar: RoleBottomNavigationBar(
        role: AppUserRole.employee,
        selectedIndex: 2,
        onDestinationSelected: _handlePrimaryNavigation,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.scanQrAttendance);
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('تسجيل حضور'),
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
                    _AttendanceHero(
                      totalDays: _records.length,
                      presentCount: presentCount,
                      lateCount: lateCount,
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children:
                          [
                                _AttendanceStatCard(
                                  title: 'أيام حضور',
                                  value: '$presentCount',
                                  icon: Icons.check_circle_outline_rounded,
                                  color: const Color(0xFF0F766E),
                                ),
                                _AttendanceStatCard(
                                  title: 'أيام تأخير',
                                  value: '$lateCount',
                                  icon: Icons.watch_later_outlined,
                                  color: const Color(0xFFEA580C),
                                ),
                                _AttendanceStatCard(
                                  title: 'أيام غياب',
                                  value: '$absentCount',
                                  icon: Icons.person_off_outlined,
                                  color: const Color(0xFFDC2626),
                                ),
                                _AttendanceStatCard(
                                  title: 'آخر حضور',
                                  value: _records.isEmpty
                                      ? '--'
                                      : _records.first.checkInTimeLabel,
                                  icon: Icons.qr_code_2_rounded,
                                  color: const Color(0xFF1D4ED8),
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
                          Text('سجل الأيام', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 14),
                          if (_isLoading)
                            const AppLoadingState(
                              title: 'جاري تحميل الدوام',
                              message: 'نجهز سجل الحضور والغياب الخاص بك.',
                            )
                          else if (_errorMessage != null)
                            AppErrorState(
                              title: 'حدث خطأ',
                              message: _errorMessage!,
                              onRetry: _loadAttendanceHistory,
                            )
                          else ...[
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: AttendanceFilter.values
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
                            if (_filteredRecords.isEmpty)
                              const AppEmptyState(
                                title: 'لا توجد سجلات',
                                message:
                                    'لا يوجد أي يوم دوام ضمن الفلتر الحالي.',
                                icon: Icons.calendar_month_outlined,
                              )
                            else
                              ..._filteredRecords.map(
                                (record) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _AttendanceRecordCard(record: record),
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

enum AttendanceFilter {
  all('الكل'),
  present('حضور'),
  late('متأخر'),
  absent('غياب');

  const AttendanceFilter(this.label);

  final String label;
}

class _AttendanceHero extends StatelessWidget {
  const _AttendanceHero({
    required this.totalDays,
    required this.presentCount,
    required this.lateCount,
  });

  final int totalDays;
  final int presentCount;
  final int lateCount;

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
            'متابعة حضورك يوماً بيوم',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'من هنا يمكنك مراجعة تواريخ الحضور، وقت الدخول، وحالة كل يوم سواء كان حضوراً أو تأخيراً أو غياباً.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroTag(label: 'إجمالي الأيام: $totalDays'),
              _HeroTag(label: 'حضور: $presentCount'),
              _HeroTag(label: 'تأخير: $lateCount'),
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

class _AttendanceStatCard extends StatelessWidget {
  const _AttendanceStatCard({
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

class _AttendanceRecordCard extends StatelessWidget {
  const _AttendanceRecordCard({required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: record.status.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(record.status.icon, color: record.status.color),
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
                        '${record.dayLabel} - ${record.dateLabel}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    _AttendanceStatusChip(status: record.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'وقت الدخول: ${record.checkInTimeLabel}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'طريقة التسجيل: ${record.method}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'الموقع: ${record.locationLabel}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  record.note,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceStatusChip extends StatelessWidget {
  const _AttendanceStatusChip({required this.status});

  final AttendanceRecordStatus status;

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
