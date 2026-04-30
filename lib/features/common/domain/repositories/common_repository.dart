import '../models/account_profile_data.dart';
import '../models/app_dashboard_summary.dart';
import '../models/app_notification_item.dart';
import '../models/app_user_role.dart';

abstract class CommonRepository {
  Future<AppDashboardSummary> fetchDashboardSummary(AppUserRole role);

  Future<List<AppNotificationItem>> fetchNotifications(AppUserRole role);

  Future<void> markAllNotificationsRead(AppUserRole role);

  Future<void> markNotificationRead({
    required AppUserRole role,
    required String notificationId,
  });

  Future<void> requestPasswordChange({required String password});

  Future<AppNotificationItem> approvePasswordChange({
    required AppUserRole role,
    required String notificationId,
  });

  Future<AccountProfileData> fetchProfile(AppUserRole role);
}
