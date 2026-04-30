import 'dart:convert';
import 'dart:math';

import 'package:web/web.dart' as web;

Future<String> getPlatformDeviceIdentifier() async {
  const storageKey = 'hr_manager_device_id';

  final existingIdentifier = web.window.localStorage.getItem(storageKey);
  if (existingIdentifier != null && existingIdentifier.trim().isNotEmpty) {
    return existingIdentifier;
  }

  final random = Random.secure();
  final seed = [
    web.window.navigator.userAgent,
    web.window.navigator.language,
    DateTime.now().microsecondsSinceEpoch.toString(),
    random.nextInt(1 << 32).toString(),
  ].join('|');

  final identifier =
      'web-${base64Url.encode(utf8.encode(seed)).replaceAll('=', '')}';
  web.window.localStorage.setItem(storageKey, identifier);

  return identifier;
}
