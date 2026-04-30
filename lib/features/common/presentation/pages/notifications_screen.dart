import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/services/app_services.dart';
import '../../domain/models/app_notification_item.dart';
import '../../domain/models/app_user_role.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_state.dart';
import '../widgets/app_loading_state.dart';
import '../widgets/role_bottom_navigation_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.role});

  final AppUserRole role;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotificationItem> _notifications = const [];
  NotificationFilter _selectedFilter = NotificationFilter.all;
  bool _isLoading = true;
  bool _isMarkingAllRead = false;
  String? _updatingNotificationId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadNotifications());
  }

  int get _unreadCount =>
      _notifications.where((item) => item.isRead == false).length;

  List<AppNotificationItem> get _filteredNotifications {
    switch (_selectedFilter) {
      case NotificationFilter.all:
        return _notifications;
      case NotificationFilter.leave:
        return _notifications
            .where((item) => item.category == AppNotificationCategory.leave)
            .toList();
      case NotificationFilter.attendance:
        return _notifications
            .where(
              (item) => item.category == AppNotificationCategory.attendance,
            )
            .toList();
      case NotificationFilter.system:
        return _notifications
            .where((item) => item.category == AppNotificationCategory.system)
            .toList();
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await AppServices.commonRepository.fetchNotifications(
        widget.role,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = items;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'تعذر تحميل الإشعارات حاليًا.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAllRead || _unreadCount == 0) {
      return;
    }

    setState(() {
      _isMarkingAllRead = true;
    });

    try {
      await AppServices.commonRepository.markAllNotificationsRead(widget.role);
      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = _notifications
            .map((item) => item.copyWith(isRead: true))
            .toList();
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnack('تعذر تحديث حالة الإشعارات حاليًا.');
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingAllRead = false;
        });
      }
    }
  }

  Future<void> _openNotification(AppNotificationItem item) async {
    if (item.isRead == false) {
      setState(() {
        _updatingNotificationId = item.id;
      });

      try {
        await AppServices.commonRepository.markNotificationRead(
          role: widget.role,
          notificationId: item.id,
        );
        if (!mounted) {
          return;
        }

        setState(() {
          _notifications = _notifications
              .map(
                (notification) => notification.id == item.id
                    ? notification.copyWith(isRead: true)
                    : notification,
              )
              .toList();
        });
      } catch (_) {
        if (!mounted) {
          return;
        }
        _showSnack('تعذر تحديث حالة هذا الإشعار حاليًا.');
      } finally {
        if (mounted) {
          setState(() {
            _updatingNotificationId = null;
          });
        }
      }
    }

    if (!mounted) {
      return;
    }

    await _performNotificationAction(item);
  }

  Future<void> _performNotificationAction(AppNotificationItem item) async {
    final route = item.actionRoute?.trim();
    if (route != null && route.isNotEmpty) {
      final handled = await _performActionRoute(route, item);
      if (handled) {
        return;
      }
    }

    switch (item.category) {
      case AppNotificationCategory.leave:
        _openLeaveAction();
        return;
      case AppNotificationCategory.attendance:
        _openAttendanceAction();
        return;
      case AppNotificationCategory.system:
        await _openSystemAction(item);
        return;
    }
  }

  Future<bool> _performActionRoute(
    String route,
    AppNotificationItem item,
  ) async {
    switch (route) {
      case '/hr/password-requests':
        await _openPasswordChangeRequest(item);
        return true;
      case '/manager/leave-requests':
        _openNamedRoute(AppRoutes.managerLeaveRequests);
        return true;
      case '/hr/leave-requests':
        _openNamedRoute(AppRoutes.hrLeaveRequests);
        return true;
      case '/employee/leave-history':
        _openNamedRoute(AppRoutes.employeeLeaveHistory);
        return true;
      case '/employee/attendance-history':
        _openNamedRoute(AppRoutes.employeeAttendanceHistory);
        return true;
      case '/employee/dashboard':
        _openNamedRoute(AppRoutes.employeeDashboard);
        return true;
      case '/team/attendance':
        _openAttendanceAction();
        return true;
      case '/notifications':
        await _showNotificationDetails(item);
        return true;
      default:
        return false;
    }
  }

  void _openLeaveAction() {
    switch (widget.role) {
      case AppUserRole.employee:
        _openNamedRoute(AppRoutes.employeeLeaveHistory);
        return;
      case AppUserRole.manager:
        _openNamedRoute(AppRoutes.managerLeaveRequests);
        return;
      case AppUserRole.hr:
      case AppUserRole.admin:
        _openNamedRoute(AppRoutes.hrLeaveRequests);
        return;
    }
  }

  void _openAttendanceAction() {
    switch (widget.role) {
      case AppUserRole.employee:
        _openNamedRoute(AppRoutes.employeeAttendanceHistory);
        return;
      case AppUserRole.manager:
        _openNamedRoute(AppRoutes.managerEmployeeDetails);
        return;
      case AppUserRole.hr:
      case AppUserRole.admin:
        _openNamedRoute(AppRoutes.hrEmployeeDetails);
        return;
    }
  }

  Future<void> _openSystemAction(AppNotificationItem item) async {
    if (_labelMatches(item.actionLabel, const ['عرض الرصيد'])) {
      if (widget.role == AppUserRole.employee) {
        _openNamedRoute(AppRoutes.employeeDashboard);
        return;
      }
    }

    if (_labelMatches(item.actionLabel, const ['عرض السياسة'])) {
      if (widget.role == AppUserRole.manager) {
        _openNamedRoute(AppRoutes.managerLeavePolicy);
        return;
      }
    }

    if (_labelMatches(item.actionLabel, const ['فتح الملفات'])) {
      switch (widget.role) {
        case AppUserRole.employee:
          _openNamedRoute(AppRoutes.employeeDashboard);
          return;
        case AppUserRole.manager:
          _openNamedRoute(AppRoutes.managerEmployeeDetails);
          return;
        case AppUserRole.hr:
        case AppUserRole.admin:
          _openNamedRoute(AppRoutes.hrEmployeeDetails);
          return;
      }
    }

    await _showNotificationDetails(item);
  }

  Future<void> _openPasswordChangeRequest(AppNotificationItem item) async {
    if (widget.role != AppUserRole.hr && widget.role != AppUserRole.admin) {
      await _showNotificationDetails(item);
      return;
    }

    final status = item.metadata['status']?.toString();
    if (status == 'approved' || item.actionLabel.contains('تمت الموافقة')) {
      await _showNotificationDetails(item);
      return;
    }

    final employeeName =
        item.metadata['employee_name']?.toString().trim() ?? 'الموظف';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('موافقة تغيير كلمة المرور'),
          content: Text(
            'هل تريد الموافقة على طلب تغيير كلمة مرور $employeeName؟ سيتم تطبيق كلمة المرور الجديدة وإنهاء جلساته الحالية.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('موافقة وتطبيق'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _updatingNotificationId = item.id;
    });

    try {
      final updated = await AppServices.commonRepository.approvePasswordChange(
        role: widget.role,
        notificationId: item.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _notifications = _notifications
            .map(
              (notification) =>
                  notification.id == item.id ? updated : notification,
            )
            .toList();
      });
      _showSnack('تمت الموافقة وتغيير كلمة المرور.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnack('تعذر الموافقة على طلب تغيير كلمة المرور حالياً.');
    } finally {
      if (mounted) {
        setState(() {
          _updatingNotificationId = null;
        });
      }
    }
  }

  bool _labelMatches(String value, List<String> patterns) {
    final normalized = value.trim().toLowerCase();
    for (final pattern in patterns) {
      if (normalized.contains(pattern.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  Future<void> _showNotificationDetails(AppNotificationItem item) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: item.category.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.category.label,
                  style: TextStyle(
                    color: item.category.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(item.message),
              const SizedBox(height: 12),
              Text(
                item.timeLabel,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  void _openNamedRoute(String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _handlePrimaryNavigation(int index) {
    switch (widget.role) {
      case AppUserRole.employee:
        switch (index) {
          case 0:
            Navigator.of(
              context,
            ).pushReplacementNamed(AppRoutes.employeeDashboard);
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
            return;
          case 4:
            Navigator.of(context).pushReplacementNamed(
              AppRoutes.profileAccount,
              arguments: widget.role,
            );
            return;
        }
      case AppUserRole.manager:
        switch (index) {
          case 0:
            Navigator.of(
              context,
            ).pushReplacementNamed(AppRoutes.managerDashboard);
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
            Navigator.of(
              context,
            ).pushReplacementNamed(AppRoutes.managerBroadcasts);
            return;
          case 4:
            return;
          case 5:
            Navigator.of(context).pushReplacementNamed(
              AppRoutes.profileAccount,
              arguments: widget.role,
            );
            return;
        }
      case AppUserRole.hr:
      case AppUserRole.admin:
        switch (index) {
          case 0:
            Navigator.of(context).pushReplacementNamed(
              widget.role == AppUserRole.admin
                  ? AppRoutes.adminDashboard
                  : AppRoutes.hrDashboard,
            );
            return;
          case 1:
            Navigator.of(
              context,
            ).pushReplacementNamed(AppRoutes.hrLeaveRequests);
            return;
          case 2:
            Navigator.of(
              context,
            ).pushReplacementNamed(AppRoutes.hrEmployeeDetails);
            return;
          case 3:
            return;
          case 4:
            Navigator.of(context).pushReplacementNamed(
              AppRoutes.profileAccount,
              arguments: widget.role,
            );
            return;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 920;

    return Scaffold(
      bottomNavigationBar: RoleBottomNavigationBar(
        role: widget.role,
        selectedIndex: widget.role == AppUserRole.manager ? 4 : 3,
        onDestinationSelected: _handlePrimaryNavigation,
      ),
      appBar: AppBar(
        title: const Text('الإشعارات'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading || _isMarkingAllRead || _unreadCount == 0
                ? null
                : _markAllAsRead,
            child: Text(
              _isMarkingAllRead ? 'جارٍ التحديث...' : 'تحديد الكل كمقروء',
            ),
          ),
        ],
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
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Hero(role: widget.role, unreadCount: _unreadCount),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children:
                          [
                                _MetricCard(
                                  title: 'غير مقروءة',
                                  value: '$_unreadCount',
                                  icon: Icons.mark_email_unread_outlined,
                                  color: const Color(0xFF1D4ED8),
                                ),
                                _MetricCard(
                                  title: 'إشعارات الإجازات',
                                  value:
                                      '${_notifications.where((item) => item.category == AppNotificationCategory.leave).length}',
                                  icon: Icons.event_note_rounded,
                                  color: const Color(0xFF0F766E),
                                ),
                                _MetricCard(
                                  title: 'إشعارات الدوام',
                                  value:
                                      '${_notifications.where((item) => item.category == AppNotificationCategory.attendance).length}',
                                  icon: Icons.qr_code_scanner_rounded,
                                  color: const Color(0xFFEA580C),
                                ),
                              ]
                              .map(
                                (card) => SizedBox(
                                  width: isWide ? 250 : width - 40,
                                  child: card,
                                ),
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
                            'قائمة الإشعارات',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 14),
                          if (_isLoading)
                            const AppLoadingState(
                              title: 'جارٍ تحميل الإشعارات',
                              message: 'نجهز آخر التنبيهات الخاصة بحسابك.',
                            )
                          else if (_errorMessage != null)
                            AppErrorState(
                              title: 'حدث خطأ',
                              message: _errorMessage!,
                              onRetry: _loadNotifications,
                            )
                          else ...[
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: NotificationFilter.values
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
                            if (_filteredNotifications.isEmpty)
                              const AppEmptyState(
                                title: 'لا توجد إشعارات',
                                message:
                                    'لا يوجد أي تنبيه ضمن الفلتر الحالي حاليًا.',
                                icon: Icons.notifications_off_outlined,
                              )
                            else
                              ..._filteredNotifications.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _NotificationTile(
                                    item: item,
                                    isUpdating:
                                        _updatingNotificationId == item.id,
                                    onTap: () => _openNotification(item),
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

enum NotificationFilter {
  all('الكل'),
  leave('الإجازات'),
  attendance('الدوام'),
  system('النظام');

  const NotificationFilter(this.label);

  final String label;
}

class _Hero extends StatelessWidget {
  const _Hero({required this.role, required this.unreadCount});

  final AppUserRole role;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0F2A10), Color(0xFF105C11), Color(0xFF1CBE32)],
        ),
        borderRadius: BorderRadius.circular(30),
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
                  Icons.notifications_active_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إشعارات ${role.label}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role.subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
              Badge(
                label: Text('$unreadCount'),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'اضغط على أي إشعار لتنفيذ الإجراء مباشرة، سواء كان مراجعة طلب، فتح سجل، أو عرض تفاصيل الإشعار نفسه.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.isUpdating,
    required this.onTap,
  });

  final AppNotificationItem item;
  final bool isUpdating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isUpdating ? null : onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: item.isRead
              ? const Color(0xFFF8FAFC)
              : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: item.isRead
                ? const Color(0xFFE2E8F0)
                : item.category.color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: item.category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.category.icon, color: item.category.color),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (item.isRead == false)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'جديد',
                            style: TextStyle(
                              color: Color(0xFF1D4ED8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        item.timeLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                      ),

                      // const Spacer(),
                    ],
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: isUpdating
                        ? SizedBox(
                            key: const ValueKey('loading'),
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: item.category.color,
                            ),
                          )
                        : Row(
                            key: const ValueKey('action'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.actionLabel,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: item.category.color,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: item.category.color,
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
    );
  }
}
