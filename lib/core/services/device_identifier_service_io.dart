import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('hr_manager/device_identifier');

Future<String> getPlatformDeviceIdentifier() async {
  if (_supportsNativeIdentifier) {
    final nativeIdentifier = await _nativeIdentifierOrNull();
    if (nativeIdentifier != null) {
      return _sanitizeIdentifier(nativeIdentifier);
    }
  }

  final desktopIdentifier = _desktopIdentifierOrNull();
  if (desktopIdentifier != null) {
    return desktopIdentifier;
  }

  throw StateError('تعذر تحديد معرف الجهاز على هذه المنصة.');
}

bool get _supportsNativeIdentifier =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

Future<String?> _nativeIdentifierOrNull() async {
  try {
    final nativeIdentifier = await _channel.invokeMethod<String>(
      'getDeviceIdentifier',
    );
    if (nativeIdentifier == null || nativeIdentifier.trim().isEmpty) {
      return null;
    }
    return nativeIdentifier;
  } on MissingPluginException {
    return null;
  } on PlatformException {
    return null;
  }
}

String? _desktopIdentifierOrNull() {
  if (!Platform.isWindows && !Platform.isLinux) {
    return null;
  }

  final hostName =
      Platform.environment['COMPUTERNAME'] ??
      Platform.environment['HOSTNAME'] ??
      Platform.environment['NAME'];
  final userName =
      Platform.environment['USERNAME'] ?? Platform.environment['USER'];

  final segments = <String>[
    'desktop',
    Platform.operatingSystem,
    if (hostName != null && hostName.trim().isNotEmpty) hostName,
    if (userName != null && userName.trim().isNotEmpty) userName,
  ];

  return _sanitizeIdentifier(segments.join('-'));
}

String _sanitizeIdentifier(String rawIdentifier) {
  return rawIdentifier
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-');
}
