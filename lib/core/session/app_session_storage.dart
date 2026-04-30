import 'package:shared_preferences/shared_preferences.dart';

class AppSessionStorage {
  AppSessionStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? _createPreferences();

  static const sessionKey = 'auth.session.v1';

  final SharedPreferencesAsync? _preferences;
  String? _memorySession;

  static SharedPreferencesAsync? _createPreferences() {
    try {
      return SharedPreferencesAsync();
    } on StateError {
      return null;
    }
  }

  Future<String?> readRawSession() async {
    final preferences = _preferences;
    if (preferences == null) {
      return _memorySession;
    }

    try {
      return await preferences.getString(sessionKey);
    } on StateError {
      return _memorySession;
    }
  }

  Future<void> writeRawSession(String value) async {
    _memorySession = value;
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }

    try {
      await preferences.setString(sessionKey, value);
    } on StateError {
      // Keep the in-memory fallback for environments without plugin setup.
    }
  }

  Future<void> clear() async {
    _memorySession = null;
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }

    try {
      await preferences.remove(sessionKey);
    } on StateError {
      // The fallback has already been cleared.
    }
  }
}
