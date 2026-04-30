import '../../../core/network/api_exception.dart';
import '../../../core/session/app_user_session.dart';
import '../../common/data/mock_common_data.dart';
import '../../common/domain/models/account_profile_data.dart';
import 'mock_credentials_store.dart';
import '../domain/models/login_request.dart';
import '../domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository({required this.sessionController});

  final AppSessionController sessionController;

  @override
  Future<AppUserSession?> restoreSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return sessionController.restorePersistedSession();
  }

  @override
  Future<AppUserSession> signIn(LoginRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    final profile = _profileForRequest(request);
    final session = AppUserSession(
      profile: profile,
      accessToken: 'mock-token-${profile.role.name}-${profile.code}',
      rememberMe: request.rememberMe,
      authenticatedAt: DateTime.now(),
    );

    return session;
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
  }

  AccountProfileData _profileForRequest(LoginRequest request) {
    final profile = profileForEmail(request.email);
    final password = MockCredentialsStore.passwordForEmail(request.email);
    if (profile == null || password == null || request.password != password) {
      throw const ApiException('بيانات تسجيل الدخول غير صحيحة.');
    }

    return profile;
  }
}
