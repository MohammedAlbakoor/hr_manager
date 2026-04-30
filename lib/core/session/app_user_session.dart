import 'dart:convert';

import '../../features/common/domain/models/account_profile_data.dart';
import '../../features/common/domain/models/app_user_role.dart';
import 'app_session_storage.dart';

class AppUserSession {
  const AppUserSession({
    required this.profile,
    required this.accessToken,
    required this.rememberMe,
    required this.authenticatedAt,
  });

  final AccountProfileData profile;
  final String accessToken;
  final bool rememberMe;
  final DateTime authenticatedAt;

  AppUserRole get role => profile.role;
  String get userName => profile.name;
  String get userCode => profile.code;
  String get email => profile.email;

  factory AppUserSession.fromJson(Map<String, dynamic> json) {
    return AppUserSession(
      profile: AccountProfileData.fromJson(
        json['profile'] as Map<String, dynamic>? ?? const {},
      ),
      accessToken: json['access_token']?.toString() ?? '',
      rememberMe: json['remember_me'] == true,
      authenticatedAt:
          DateTime.tryParse(json['authenticated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile': profile.toJson(),
      'access_token': accessToken,
      'remember_me': rememberMe,
      'authenticated_at': authenticatedAt.toIso8601String(),
    };
  }
}

class AppSessionController {
  AppSessionController({AppSessionStorage? storage})
    : _storage = storage ?? AppSessionStorage();

  final AppSessionStorage _storage;

  AppUserSession? _currentSession;
  bool _isSessionInvalidated = false;

  AppUserSession? get currentSession => _currentSession;
  bool get isAuthenticated => _currentSession != null;
  bool get isSessionInvalidated => _isSessionInvalidated;

  Future<void> setSession(AppUserSession session) async {
    _currentSession = session;
    _isSessionInvalidated = false;

    if (session.rememberMe) {
      await _storage.writeRawSession(jsonEncode(session.toJson()));
      return;
    }

    await _storage.clear();
  }

  Future<AppUserSession?> restorePersistedSession() async {
    final rawSession = await _storage.readRawSession();
    if (rawSession == null || rawSession.isEmpty) {
      _currentSession = null;
      _isSessionInvalidated = false;
      return null;
    }

    try {
      final decoded = jsonDecode(rawSession);
      if (decoded is! Map<String, dynamic>) {
        await _storage.clear();
        _currentSession = null;
        _isSessionInvalidated = false;
        return null;
      }

      final session = AppUserSession.fromJson(decoded);
      if (!session.rememberMe || session.accessToken.isEmpty) {
        await _storage.clear();
        _currentSession = null;
        _isSessionInvalidated = false;
        return null;
      }

      _currentSession = session;
      _isSessionInvalidated = false;
      return session;
    } catch (_) {
      await _storage.clear();
      _currentSession = null;
      _isSessionInvalidated = false;
      return null;
    }
  }

  Future<void> clear({bool invalidate = false}) async {
    _currentSession = null;
    _isSessionInvalidated = invalidate;
    await _storage.clear();
  }
}
