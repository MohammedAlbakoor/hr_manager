class AttendanceQrSession {
  const AttendanceQrSession({
    required this.id,
    required this.token,
    required this.payload,
    required this.generatedAt,
    required this.expiresAt,
  });

  final String id;
  final String token;
  final String payload;
  final DateTime generatedAt;
  final DateTime expiresAt;

  int get lifetimeSeconds {
    final seconds = expiresAt.difference(generatedAt).inSeconds;
    return seconds <= 0 ? 30 : seconds;
  }
}
