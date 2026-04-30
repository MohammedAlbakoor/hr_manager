import '../domain/models/app_notification_item.dart';
import '../domain/models/app_user_role.dart';
import 'mock_common_data.dart';

class MockNotificationStore {
  MockNotificationStore._();

  static final Map<AppUserRole, List<AppNotificationItem>>
  _notificationsByRole = {
    for (final role in AppUserRole.values)
      role: List<AppNotificationItem>.from(notificationsForRole(role)),
  };

  static List<AppNotificationItem> itemsForRole(AppUserRole role) {
    return List<AppNotificationItem>.from(
      _notificationsByRole.putIfAbsent(
        role,
        () => List<AppNotificationItem>.from(notificationsForRole(role)),
      ),
    );
  }

  static void markAllRead(AppUserRole role) {
    _notificationsByRole[role] = itemsForRole(
      role,
    ).map((item) => item.copyWith(isRead: true)).toList();
  }

  static void markRead(AppUserRole role, String notificationId) {
    _notificationsByRole[role] = itemsForRole(role)
        .map(
          (item) =>
              item.id == notificationId ? item.copyWith(isRead: true) : item,
        )
        .toList();
  }

  static void addPasswordChangeRequest() {
    final current = itemsForRole(AppUserRole.hr);
    _notificationsByRole[AppUserRole.hr] = [
      AppNotificationItem(
        id: 'PWD-${DateTime.now().millisecondsSinceEpoch}',
        title: 'طلب تغيير كلمة مرور',
        message:
            'طلب الموظف تغيير كلمة المرور. يحتاج الطلب إلى موافقة الموارد البشرية قبل تطبيقه.',
        timeLabel: 'الآن',
        category: AppNotificationCategory.system,
        isRead: false,
        actionLabel: 'مراجعة الطلب',
        actionRoute: '/hr/password-requests',
        metadata: const {'action': 'password_change_request'},
      ),
      ...current,
    ];
  }

  static AppNotificationItem approvePasswordChange(
    AppUserRole role,
    String notificationId,
  ) {
    AppNotificationItem? updated;
    _notificationsByRole[role] = itemsForRole(role).map((item) {
      if (item.id != notificationId) {
        return item;
      }

      updated = AppNotificationItem(
        id: item.id,
        title: item.title,
        message: item.message,
        timeLabel: item.timeLabel,
        category: item.category,
        isRead: true,
        actionLabel: 'تمت الموافقة',
        actionRoute: item.actionRoute,
        metadata: {...item.metadata, 'status': 'approved'},
      );
      return updated!;
    }).toList();

    return updated ??
        AppNotificationItem(
          id: notificationId,
          title: 'طلب تغيير كلمة مرور',
          message: 'تمت الموافقة على الطلب.',
          timeLabel: 'الآن',
          category: AppNotificationCategory.system,
          isRead: true,
          actionLabel: 'تمت الموافقة',
        );
  }

  static void broadcastFromManager({
    String? broadcastId,
    required String title,
    required String message,
    List<AppUserRole> targetRoles = const [
      AppUserRole.employee,
      AppUserRole.hr,
    ],
  }) {
    final baseId =
        broadcastId ?? 'TEMP-${DateTime.now().millisecondsSinceEpoch}';

    for (final role in targetRoles) {
      final current = itemsForRole(role);
      _notificationsByRole[role] = [
        AppNotificationItem(
          id: _notificationId(baseId, role),
          title: title,
          message: message,
          timeLabel: 'الآن',
          category: AppNotificationCategory.system,
          isRead: false,
          actionLabel: 'عرض الإشعار',
        ),
        ...current,
      ];
    }
  }

  static void updateBroadcast({
    required String broadcastId,
    required String title,
    required String message,
    List<AppUserRole> targetRoles = const [
      AppUserRole.employee,
      AppUserRole.hr,
    ],
  }) {
    for (final role in const [AppUserRole.employee, AppUserRole.hr]) {
      if (!targetRoles.contains(role)) {
        _notificationsByRole[role] = itemsForRole(role)
            .where((item) => item.id != _notificationId(broadcastId, role))
            .toList();
        continue;
      }
      _notificationsByRole[role] = itemsForRole(role)
          .map(
            (item) => item.id == _notificationId(broadcastId, role)
                ? AppNotificationItem(
                    id: item.id,
                    title: title,
                    message: message,
                    timeLabel: item.timeLabel,
                    category: item.category,
                    isRead: item.isRead,
                    actionLabel: item.actionLabel,
                  )
                : item,
          )
          .toList();

      final hasItem = _notificationsByRole[role]!.any(
        (item) => item.id == _notificationId(broadcastId, role),
      );
      if (!hasItem) {
        _notificationsByRole[role] = [
          AppNotificationItem(
            id: _notificationId(broadcastId, role),
            title: title,
            message: message,
            timeLabel: 'الآن',
            category: AppNotificationCategory.system,
            isRead: false,
            actionLabel: 'عرض الإشعار',
          ),
          ..._notificationsByRole[role]!,
        ];
      }
    }
  }

  static void deleteBroadcast(String broadcastId) {
    for (final role in const [AppUserRole.employee, AppUserRole.hr]) {
      _notificationsByRole[role] = itemsForRole(
        role,
      ).where((item) => item.id != _notificationId(broadcastId, role)).toList();
    }
  }

  static String _notificationId(String broadcastId, AppUserRole role) {
    return 'BROADCAST-$broadcastId-${role.name.toUpperCase()}';
  }
}
