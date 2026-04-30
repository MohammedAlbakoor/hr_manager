import '../../common/domain/models/app_user_role.dart';
import '../domain/models/attendance_qr_session.dart';
import '../domain/models/attendance_record.dart';
import '../domain/models/attendance_scan_payload.dart';
import '../domain/repositories/attendance_repository.dart';
import 'mock_attendance_records.dart';

class MockAttendanceRepository implements AttendanceRepository {
  MockAttendanceRepository()
    : _records = List<AttendanceRecord>.from(mockAttendanceRecords);

  final List<AttendanceRecord> _records;
  final Map<AppUserRole, AttendanceQrSession> _sessions =
      <AppUserRole, AttendanceQrSession>{};

  @override
  Future<List<AttendanceRecord>> fetchAttendanceHistory() async {
    await Future<void>.delayed(const Duration(milliseconds: 340));
    return List<AttendanceRecord>.from(_records);
  }

  @override
  Future<AttendanceRecord> scanAttendance(AttendanceScanPayload payload) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));

    final now = DateTime.now();
    final todayLabel = _formatDate(now);
    final alreadyScannedToday = _records.any(
      (record) => record.dateLabel == todayLabel,
    );
    if (alreadyScannedToday) {
      throw StateError('تم تسجيل حضور اليوم بالفعل، ولا يمكن تكرار العملية.');
    }

    final record = AttendanceRecord(
      id: 'ATT-${now.millisecondsSinceEpoch}',
      dateLabel: todayLabel,
      dayLabel: _weekdayLabel(now),
      checkInTimeLabel: _formatTime(now),
      status: AttendanceRecordStatus.present,
      method: 'QR',
      locationLabel: 'المكتب الرئيسي',
      note: 'تم تسجيل الحضور بواسطة رمز الجلسة ${payload.token}.',
    );

    _records.insert(0, record);
    return record;
  }

  @override
  Future<AttendanceQrSession> createAttendanceQrSession({
    required AppUserRole role,
    bool refresh = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));

    final existingSession = _sessions[role];
    if (!refresh && existingSession != null) {
      return existingSession;
    }

    final now = DateTime.now();
    final prefix = switch (role) {
      AppUserRole.manager => 'MGR',
      AppUserRole.hr => 'HR',
      AppUserRole.admin => 'ADM',
      AppUserRole.employee => 'EMP',
    };
    final datePart =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timePart =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final randomish = ((now.millisecond * 97) % 9999).toString().padLeft(
      4,
      '0',
    );
    final token = '$prefix-$datePart-$timePart-$randomish';

    final session = AttendanceQrSession(
      id: 'QR-${now.millisecondsSinceEpoch}',
      token: token,
      payload: token,
      generatedAt: now,
      expiresAt: now.add(const Duration(days: 3650)),
    );

    _sessions[role] = session;
    return session;
  }

  String _formatDate(DateTime date) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _weekdayLabel(DateTime date) {
    const weekdays = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return weekdays[date.weekday - 1];
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12
        ? date.hour - 12
        : date.hour == 0
        ? 12
        : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'م' : 'ص';
    return '${hour.toString().padLeft(2, '0')}:$minute $suffix';
  }
}
