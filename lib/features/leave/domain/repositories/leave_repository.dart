import '../../../hr/domain/models/hr_leave_request.dart';
import '../../../manager/domain/models/manager_leave_request.dart';
import '../models/create_leave_request_payload.dart';
import '../models/employee_leave_request.dart';

abstract class LeaveRepository {
  Future<List<EmployeeLeaveRequest>> fetchEmployeeLeaveHistory();

  Future<EmployeeLeaveRequest> createLeaveRequest(
    CreateLeaveRequestPayload payload,
  );

  Future<List<ManagerLeaveRequest>> fetchManagerLeaveRequests();

  Future<ManagerLeaveRequest> submitManagerDecision({
    required String leaveId,
    required bool approve,
    String? note,
  });

  Future<List<HrLeaveRequest>> fetchHrLeaveRequests();

  Future<HrLeaveRequest> submitHrDecision({
    required String leaveId,
    required bool approve,
    String? note,
  });
}
