import '../../../../core/session/app_user_session.dart';
import '../models/login_request.dart';

abstract class AuthRepository {
  Future<AppUserSession?> restoreSession();

  Future<AppUserSession> signIn(LoginRequest request);

  Future<void> signOut();
}
