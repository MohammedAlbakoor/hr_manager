import '../models/manager_broadcast_recipient.dart';
import '../models/manager_broadcast_message.dart';

abstract class ManagerBroadcastRepository {
  Future<List<ManagerBroadcastMessage>> fetchBroadcasts();

  Future<List<ManagerBroadcastRecipient>> fetchRecipientOptions();

  Future<ManagerBroadcastMessage> createBroadcast({
    required String title,
    required String message,
    required String audienceType,
    List<int> recipientIds = const [],
  });

  Future<ManagerBroadcastMessage> updateBroadcast({
    required String broadcastId,
    required String title,
    required String message,
    required String audienceType,
    List<int> recipientIds = const [],
  });

  Future<void> deleteBroadcast(String broadcastId);
}
