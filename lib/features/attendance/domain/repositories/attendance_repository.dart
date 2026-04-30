import '../../../common/domain/models/app_user_role.dart';
import '../models/attendance_qr_session.dart';
import '../models/attendance_scan_payload.dart';
import '../models/attendance_record.dart';

abstract class AttendanceRepository {
  Future<List<AttendanceRecord>> fetchAttendanceHistory();

  Future<AttendanceRecord> scanAttendance(AttendanceScanPayload payload);

  Future<AttendanceQrSession> createAttendanceQrSession({
    required AppUserRole role,
    bool refresh = false,
  });
}
