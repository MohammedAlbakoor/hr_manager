import 'device_identifier_service_stub.dart'
    if (dart.library.io) 'device_identifier_service_io.dart'
    if (dart.library.html) 'device_identifier_service_web.dart'
    as platform_device_identifier;

class DeviceIdentifierException implements Exception {
  const DeviceIdentifierException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DeviceIdentifierService {
  const DeviceIdentifierService();

  Future<String> getDeviceIdentifier() async {
    try {
      final identifier =
          (await platform_device_identifier.getPlatformDeviceIdentifier())
              .trim();
      if (identifier.isEmpty) {
        throw const DeviceIdentifierException(
          'تعذر تحديد معرف الجهاز الحالي. حاول إعادة تشغيل التطبيق ثم جرّب مجددًا.',
        );
      }
      return identifier;
    } on DeviceIdentifierException {
      rethrow;
    } catch (error) {
      final message = error.toString().replaceFirst('Bad state: ', '').trim();
      throw DeviceIdentifierException(
        message.isEmpty
            ? 'تعذر تحديد معرف الجهاز الحالي. حاول إعادة تشغيل التطبيق ثم جرّب مجددًا.'
            : message,
      );
    }
  }
}
