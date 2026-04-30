import 'package:flutter/widgets.dart';

import '../navigation/app_navigator.dart';
import 'app_user_session.dart';

class SessionExpirationCoordinator {
  SessionExpirationCoordinator({required this.sessionController});

  final AppSessionController sessionController;

  Future<void>? _activeInvalidation;

  Future<void> handleUnauthorized() {
    if (sessionController.isSessionInvalidated) {
      return Future.value();
    }

    return _activeInvalidation ??= _invalidateSession();
  }

  Future<void> _invalidateSession() async {
    try {
      await sessionController.clear(invalidate: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppNavigator.resetToLogin();
        AppNavigator.showMessage(
          'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.',
        );
      });
    } finally {
      _activeInvalidation = null;
    }
  }
}
