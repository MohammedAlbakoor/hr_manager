import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/app_user_session.dart';
import '../../../core/utils/arabic_date_time_formatter.dart';
import '../domain/models/manager_broadcast_message.dart';
import '../domain/models/manager_broadcast_recipient.dart';
import '../domain/repositories/manager_broadcast_repository.dart';

class RemoteManagerBroadcastRepository implements ManagerBroadcastRepository {
  RemoteManagerBroadcastRepository({
    required this.apiClient,
    required this.sessionController,
  });

  final ApiClient apiClient;
  final AppSessionController sessionController;

  @override
  Future<List<ManagerBroadcastMessage>> fetchBroadcasts() async {
    final response = await apiClient.get(
      ApiEndpoints.managerBroadcasts,
      accessToken: _token,
      handleUnauthorized: true,
    );
    return _unwrapList(response).map(_mapBroadcast).toList();
  }

  @override
  Future<List<ManagerBroadcastRecipient>> fetchRecipientOptions() async {
    final response = await apiClient.get(
      ApiEndpoints.managerBroadcastRecipients,
      accessToken: _token,
      handleUnauthorized: true,
    );
    return _unwrapList(response).map(_mapRecipient).toList();
  }

  @override
  Future<ManagerBroadcastMessage> createBroadcast({
    required String title,
    required String message,
    required String audienceType,
    List<int> recipientIds = const [],
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.managerBroadcasts,
      accessToken: _token,
      body: _broadcastBody(
        title: title,
        message: message,
        audienceType: audienceType,
        recipientIds: recipientIds,
      ),
      handleUnauthorized: true,
    );
    return _mapBroadcast(_unwrapMap(response));
  }

  @override
  Future<ManagerBroadcastMessage> updateBroadcast({
    required String broadcastId,
    required String title,
    required String message,
    required String audienceType,
    List<int> recipientIds = const [],
  }) async {
    final response = await apiClient.patch(
      ApiEndpoints.managerBroadcast(broadcastId),
      accessToken: _token,
      body: _broadcastBody(
        title: title,
        message: message,
        audienceType: audienceType,
        recipientIds: recipientIds,
      ),
      handleUnauthorized: true,
    );
    return _mapBroadcast(_unwrapMap(response));
  }

  @override
  Future<void> deleteBroadcast(String broadcastId) async {
    await apiClient.delete(
      ApiEndpoints.managerBroadcast(broadcastId),
      accessToken: _token,
      handleUnauthorized: true,
    );
  }

  String get _token {
    final token = sessionController.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw const ApiException('لا توجد جلسة دخول نشطة لتنفيذ العملية.');
    }
    return token;
  }

  List<Map<String, dynamic>> _unwrapList(dynamic value) {
    if (value is Map<String, dynamic>) {
      final data = value['data'];
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
    }
    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList();
    }
    throw const ApiException('صيغة بيانات الرسائل المرسلة غير متوقعة.');
  }

  Map<String, dynamic> _unwrapMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      final data = value['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return value;
    }
    throw const ApiException('صيغة الرسالة المرسلة غير متوقعة.');
  }

  Map<String, dynamic> _broadcastBody({
    required String title,
    required String message,
    required String audienceType,
    required List<int> recipientIds,
  }) {
    final body = <String, dynamic>{
      'title': title,
      'message': message,
      'audience_type': audienceType,
    };

    if (audienceType == 'custom') {
      body['recipient_ids'] = recipientIds;
    }

    return body;
  }

  ManagerBroadcastMessage _mapBroadcast(Map<String, dynamic> json) {
    return ManagerBroadcastMessage(
      id: '${json['id'] ?? '--'}',
      title: '${json['title'] ?? 'رسالة'}',
      message: '${json['message'] ?? ''}',
      audienceType: '${json['audience_type'] ?? 'all'}',
      recipientIds: _toIntList(json['recipient_ids']),
      recipientNames: _toStringList(json['recipient_names']),
      createdAtLabel: ArabicDateTimeFormatter.dateTime(json['created_at']),
      updatedAtLabel: ArabicDateTimeFormatter.dateTime(json['updated_at']),
      recipientCount: _toInt(json['recipient_count']),
    );
  }

  ManagerBroadcastRecipient _mapRecipient(Map<String, dynamic> json) {
    return ManagerBroadcastRecipient(
      id: _toInt(json['id']),
      name: '${json['name'] ?? '--'}',
      code: '${json['code'] ?? '--'}',
      department: '${json['department'] ?? '--'}',
      jobTitle: '${json['job_title'] ?? '--'}',
      role: '${json['role'] ?? 'employee'}',
    );
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('${value ?? ''}') ?? 0;
  }

  List<int> _toIntList(dynamic value) {
    if (value is List) {
      return value.map(_toInt).toList();
    }
    return const [];
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => '$item'.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }
}
