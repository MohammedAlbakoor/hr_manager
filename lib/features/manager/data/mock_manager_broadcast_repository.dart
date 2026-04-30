import '../../common/data/mock_common_data.dart';
import '../../common/data/mock_notification_store.dart';
import '../../common/domain/models/app_user_role.dart';
import '../domain/models/manager_broadcast_message.dart';
import '../domain/models/manager_broadcast_recipient.dart';
import '../domain/repositories/manager_broadcast_repository.dart';
import 'mock_manager_employee_profiles.dart';

class MockManagerBroadcastRepository implements ManagerBroadcastRepository {
  static final List<ManagerBroadcastMessage> _broadcasts = [];

  @override
  Future<List<ManagerBroadcastMessage>> fetchBroadcasts() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return List<ManagerBroadcastMessage>.from(_broadcasts);
  }

  @override
  Future<List<ManagerBroadcastRecipient>> fetchRecipientOptions() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final recipients = <ManagerBroadcastRecipient>[
      ...mockManagerEmployeeProfiles.map(
        (profile) => ManagerBroadcastRecipient(
          id: int.tryParse(profile.code.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
          name: profile.name,
          code: profile.code,
          department: profile.department,
          jobTitle: profile.jobTitle,
          role: 'employee',
        ),
      ),
      ManagerBroadcastRecipient(
        id: 9001,
        name: profileForRole(AppUserRole.hr).name,
        code: profileForRole(AppUserRole.hr).code,
        department: profileForRole(AppUserRole.hr).department,
        jobTitle: profileForRole(AppUserRole.hr).jobTitle,
        role: 'hr',
      ),
    ];

    return recipients;
  }

  @override
  Future<ManagerBroadcastMessage> createBroadcast({
    required String title,
    required String message,
    required String audienceType,
    List<int> recipientIds = const [],
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final id = '${DateTime.now().millisecondsSinceEpoch}';
    final recipients = await fetchRecipientOptions();
    final selectedRecipients = audienceType == 'all'
        ? recipients
        : _recipientsByIds(recipients, recipientIds);

    final item = ManagerBroadcastMessage(
      id: id,
      title: title,
      message: message,
      audienceType: audienceType,
      recipientIds: selectedRecipients.map((item) => item.id).toList(),
      recipientNames: selectedRecipients
          .map((item) => item.name)
          .take(4)
          .toList(),
      createdAtLabel: 'الآن',
      updatedAtLabel: 'الآن',
      recipientCount: selectedRecipients.length,
    );
    _broadcasts.insert(0, item);
    MockNotificationStore.broadcastFromManager(
      broadcastId: id,
      title: title,
      message: message,
      targetRoles: _targetRoles(selectedRecipients),
    );
    return item;
  }

  @override
  Future<ManagerBroadcastMessage> updateBroadcast({
    required String broadcastId,
    required String title,
    required String message,
    required String audienceType,
    List<int> recipientIds = const [],
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final index = _broadcasts.indexWhere((item) => item.id == broadcastId);
    if (index == -1) {
      throw StateError('تعذر العثور على الرسالة المطلوبة.');
    }

    final recipients = await fetchRecipientOptions();
    final selectedRecipients = audienceType == 'all'
        ? recipients
        : _recipientsByIds(recipients, recipientIds);
    final current = _broadcasts[index];
    final updated = ManagerBroadcastMessage(
      id: current.id,
      title: title,
      message: message,
      audienceType: audienceType,
      recipientIds: selectedRecipients.map((item) => item.id).toList(),
      recipientNames: selectedRecipients
          .map((item) => item.name)
          .take(4)
          .toList(),
      createdAtLabel: current.createdAtLabel,
      updatedAtLabel: 'الآن',
      recipientCount: selectedRecipients.length,
    );
    _broadcasts[index] = updated;
    MockNotificationStore.updateBroadcast(
      broadcastId: broadcastId,
      title: title,
      message: message,
      targetRoles: _targetRoles(selectedRecipients),
    );
    return updated;
  }

  @override
  Future<void> deleteBroadcast(String broadcastId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    _broadcasts.removeWhere((item) => item.id == broadcastId);
    MockNotificationStore.deleteBroadcast(broadcastId);
  }

  List<ManagerBroadcastRecipient> _recipientsByIds(
    List<ManagerBroadcastRecipient> allRecipients,
    List<int> recipientIds,
  ) {
    final ids = recipientIds.toSet();
    return allRecipients.where((item) => ids.contains(item.id)).toList();
  }

  List<AppUserRole> _targetRoles(List<ManagerBroadcastRecipient> recipients) {
    final roles = <AppUserRole>{};
    for (final recipient in recipients) {
      roles.add(recipient.isHr ? AppUserRole.hr : AppUserRole.employee);
    }
    return roles.toList();
  }
}
