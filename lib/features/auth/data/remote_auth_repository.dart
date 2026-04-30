import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/app_user_session.dart';
import '../../common/domain/models/account_profile_data.dart';
import '../../common/domain/models/app_user_role.dart';
import '../domain/models/login_request.dart';
import '../domain/repositories/auth_repository.dart';

class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository({
    required this.apiClient,
    required this.sessionController,
  });

  final ApiClient apiClient;
  final AppSessionController sessionController;

  @override
  Future<AppUserSession?> restoreSession() async {
    return sessionController.restorePersistedSession();
  }

  @override
  Future<AppUserSession> signIn(LoginRequest request) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      body: request.toJson(),
    );
    final data = _unwrapMap(response);
    final user = _unwrapMap(data['user'] ?? data['data'] ?? data);
    final token = _string(data['token']) ?? _string(data['access_token']);
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'استجابة تسجيل الدخول لا تحتوي على access token صالح.',
      );
    }

    return AppUserSession(
      profile: AccountProfileData(
        role: _parseRole(_string(user['role'])),
        name: _string(user['name']) ?? 'مستخدم النظام',
        code:
            _string(user['code']) ??
            _string(user['employee_code']) ??
            _string(user['id']) ??
            '--',
        email: _string(user['email']) ?? request.email,
        phone: _string(user['phone']) ?? '--',
        department: _string(user['department']) ?? '--',
        jobTitle: _string(user['job_title']) ?? '--',
        joinDate: _string(user['join_date']) ?? '--',
        workSchedule: _string(user['work_schedule']) ?? '--',
        workLocation: _string(user['work_location']) ?? '--',
        lastLogin: _string(user['last_login']) ?? '--',
        deviceLabel: _string(user['device_label']) ?? '--',
        permissions: _parsePermissions(user['permissions']),
      ),
      accessToken: token,
      rememberMe: request.rememberMe,
      authenticatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> signOut() async {
    final accessToken = sessionController.currentSession?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }

    try {
      await apiClient.post(ApiEndpoints.logout, accessToken: accessToken);
    } on ApiException {
      // Ignore logout API failures locally; we still clear the local session.
    }
  }

  Map<String, dynamic> _unwrapMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    throw const ApiException('صيغة استجابة المصادقة غير متوقعة.');
  }

  String? _string(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  List<String> _parsePermissions(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }

  AppUserRole _parseRole(String? value) {
    return AppUserRole.fromStorage(value);
  }
}
