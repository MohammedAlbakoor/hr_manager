import 'package:shared_preferences/shared_preferences.dart';

class SavedLoginCredentials {
  const SavedLoginCredentials({required this.email, required this.password});

  final String email;
  final String password;

  bool get isComplete => email.trim().isNotEmpty && password.isNotEmpty;
}

class LocalLoginCredentialsStore {
  LocalLoginCredentialsStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? _createPreferences();

  static const _emailKey = 'auth.saved_credentials.email.v1';
  static const _passwordKey = 'auth.saved_credentials.password.v1';

  final SharedPreferencesAsync? _preferences;
  SavedLoginCredentials? _memoryCredentials;

  static SharedPreferencesAsync? _createPreferences() {
    try {
      return SharedPreferencesAsync();
    } on StateError {
      return null;
    }
  }

  Future<SavedLoginCredentials?> read() async {
    final preferences = _preferences;
    if (preferences == null) {
      return _memoryCredentials?.isComplete == true ? _memoryCredentials : null;
    }

    try {
      final credentials = SavedLoginCredentials(
        email: await preferences.getString(_emailKey) ?? '',
        password: await preferences.getString(_passwordKey) ?? '',
      );
      return credentials.isComplete ? credentials : null;
    } on StateError {
      return _memoryCredentials?.isComplete == true ? _memoryCredentials : null;
    }
  }

  Future<void> save({required String email, required String password}) async {
    final credentials = SavedLoginCredentials(
      email: email.trim(),
      password: password,
    );
    if (!credentials.isComplete) {
      await clear();
      return;
    }

    _memoryCredentials = credentials;
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }

    try {
      await preferences.setString(_emailKey, credentials.email);
      await preferences.setString(_passwordKey, credentials.password);
    } on StateError {
      // Keep the in-memory fallback for environments without plugin setup.
    }
  }

  Future<void> clear() async {
    _memoryCredentials = null;
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }

    try {
      await preferences.remove(_emailKey);
      await preferences.remove(_passwordKey);
    } on StateError {
      // The fallback has already been cleared.
    }
  }
}
