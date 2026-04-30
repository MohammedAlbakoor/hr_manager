class AttendanceScanPayload {
  const AttendanceScanPayload({required this.token, required this.deviceId});

  final String token;
  final String deviceId;

  Map<String, dynamic> toJson() {
    return {'token': token, 'device_id': deviceId};
  }
}
