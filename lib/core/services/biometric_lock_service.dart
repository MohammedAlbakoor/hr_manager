import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricLockService {
  BiometricLockService({
    LocalAuthentication? localAuthentication,
    SharedPreferencesAsync? preferences,
  }) : _localAuthentication = localAuthentication ?? LocalAuthentication(),
       _preferences = preferences ?? _createPreferences();

  static const _enabledKey = 'security.biometric_lock.enabled.v1';

  final LocalAuthentication _localAuthentication;
  final SharedPreferencesAsync? _preferences;
  bool? _memoryEnabled;

  static SharedPreferencesAsync? _createPreferences() {
    try {
      return SharedPreferencesAsync();
    } on StateError {
      return null;
    }
  }

  Future<bool> isEnabled() async {
    final preferences = _preferences;
    if (preferences == null) {
      return _memoryEnabled ?? false;
    }

    try {
      return await preferences.getBool(_enabledKey) ?? _memoryEnabled ?? false;
    } on StateError {
      return _memoryEnabled ?? false;
    }
  }

  Future<bool> canUseBiometrics() async {
    try {
      final canCheck = await _localAuthentication.canCheckBiometrics;
      if (!canCheck) {
        return false;
      }

      final biometrics = await _localAuthentication.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({required String reason}) async {
    try {
      return _localAuthentication.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _memoryEnabled = enabled;
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }

    try {
      await preferences.setBool(_enabledKey, enabled);
    } on StateError {
      // Keep the in-memory fallback for environments without plugin setup.
    }
  }
}
