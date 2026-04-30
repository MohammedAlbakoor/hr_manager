import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class ApiConfig {
  ApiConfig._();

  static const String _localNetworkBaseUrl = 'http://192.168.1.50:8000/api';

  static String get baseUrl {
    const configuredBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );

    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    if (kIsWeb) {
      return '${Uri.base.origin}/api';
    }

    return _localNetworkBaseUrl;
  }

  static bool get useMockRepositories {
    const useMockRepositories = bool.fromEnvironment(
      'USE_MOCK_REPOSITORIES',
      defaultValue: false,
    );

    return !kReleaseMode &&
        (useMockRepositories ||
            const bool.fromEnvironment('FLUTTER_TEST') ||
            _hasTestBinding());
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  static bool _hasTestBinding() {
    try {
      final bindingName = WidgetsBinding.instance.runtimeType.toString();
      return bindingName.contains('TestWidgetsFlutterBinding');
    } catch (_) {
      return false;
    }
  }
}
