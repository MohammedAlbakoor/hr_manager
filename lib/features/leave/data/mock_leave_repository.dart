import '../../hr/data/mock_hr_leave_requests.dart';
import '../../hr/domain/models/hr_leave_request.dart';
import '../../manager/data/mock_manager_leave_requests.dart';
import '../../manager/domain/models/manager_leave_request.dart';
import '../domain/models/create_leave_request_payload.dart';
import '../domain/models/employee_leave_request.dart';
import '../domain/repositories/leave_repository.dart';
import 'mock_employee_leave_requests.dart';

class MockLeaveRepository implements LeaveRepository {
  MockLeaveRepository()
    : _employeeRequests = List<EmployeeLeaveRequest>.from(
        mockEmployeeLeaveRequests,
      ),
      _managerRequests = List<ManagerLeaveRequest>.from(
        mockManagerLeaveRequests,
      ),
      _hrRequests = List<HrLeaveRequest>.from(mockHrLeaveRequests);

  final List<EmployeeLeaveRequest> _employeeRequests;
  final List<ManagerLeaveRequest> _managerRequests;
  final List<HrLeaveRequest> _hrRequests;

  @override
  Future<List<EmployeeLeaveRequest>> fetchEmployeeLeaveHistory() async {
    await Future<void>.delayed(const Duration(milliseconds: 360));
    return List<EmployeeLeaveRequest>.from(_employeeRequests);
  }

  @override
  Future<EmployeeLeaveRequest> createLeaveRequest(
    CreateLeaveRequestPayload payload,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 480));

    final daysCount = payload.endDate.difference(payload.startDate).inDays + 1;
    final leaveTypeLabel = _leaveTypeLabel(payload.leaveType);
    const currentBalance = 18.5;
    final remainingBalance = (currentBalance - daysCount).clamp(
      0,
      currentBalance,
    );
    final id = 'LEAVE-${DateTime.now().millisecondsSinceEpoch}';
    final submittedAt = DateTime.now();

    final employeeRequest = EmployeeLeaveRequest(
      id: id,
      title: leaveTypeLabel,
      type: leaveTypeLabel,
      periodLabel:
          '${_formatDate(payload.startDate)} - ${_formatDate(payload.endDate)}',
      daysCount: daysCount,
      status: LeaveRequestStatus.pending,
      note: payload.note.trim().isEmpty
          ? 'لا توجد ملاحظات إضافية.'
          : payload.note.trim(),
      requestedAtLabel: _formatDateTime(submittedAt),
      startDateLabel: _formatDate(payload.startDate),
      endDateLabel: _formatDate(payload.endDate),
      currentBalanceLabel: '${currentBalance.toStringAsFixed(1)} يوم',
      remainingBalanceLabel: '${remainingBalance.toStringAsFixed(1)} يوم',
      managerStatus: LeaveApprovalStatus.pending,
      hrStatus: LeaveApprovalStatus.pending,
      managerNote: 'بانتظار مراجعة المدير المباشر.',
      hrNote: 'بانتظار مرور الطلب على المدير أولاً.',
    );

    final managerRequest = ManagerLeaveRequest(
      id: id,
      employeeName: 'أحمد خالد',
      employeeCode: 'EMP-014',
      department: 'المبيعات',
      leaveType: leaveTypeLabel,
      periodLabel: employeeRequest.periodLabel,
      startDateLabel: employeeRequest.startDateLabel,
      endDateLabel: employeeRequest.endDateLabel,
      daysCount: daysCount,
      submittedAtLabel: employeeRequest.requestedAtLabel,
      employeeNote: employeeRequest.note,
      currentBalanceLabel: employeeRequest.currentBalanceLabel,
      remainingBalanceLabel: employeeRequest.remainingBalanceLabel,
      monthlyIncrementLabel: '1.5 يوم',
      lastAttendanceLabel: 'اليوم 08:12 ص',
      status: ManagerLeaveWorkflowStatus.pendingReview,
      managerNote: 'بانتظار مراجعة المدير المباشر.',
      hrNote: 'بانتظار قرار المدير.',
    );

    final hrRequest = HrLeaveRequest(
      id: id,
      employeeName: managerRequest.employeeName,
      employeeCode: managerRequest.employeeCode,
      department: managerRequest.department,
      leaveType: managerRequest.leaveType,
      periodLabel: managerRequest.periodLabel,
      startDateLabel: managerRequest.startDateLabel,
      endDateLabel: managerRequest.endDateLabel,
      daysCount: managerRequest.daysCount,
      submittedAtLabel: managerRequest.submittedAtLabel,
      employeeNote: managerRequest.employeeNote,
      currentBalanceLabel: managerRequest.currentBalanceLabel,
      remainingBalanceLabel: managerRequest.remainingBalanceLabel,
      managerStatusLabel: 'بانتظار قرار المدير',
      managerNote: 'لم تتم المراجعة بعد.',
      hrNote: 'بانتظار إحالة الطلب من المدير المباشر.',
      status: HrLeaveWorkflowStatus.waitingManager,
    );

    _employeeRequests.insert(0, employeeRequest);
    _managerRequests.insert(0, managerRequest);
    _hrRequests.insert(0, hrRequest);

    return employeeRequest;
  }

  @override
  Future<List<ManagerLeaveRequest>> fetchManagerLeaveRequests() async {
    await Future<void>.delayed(const Duration(milliseconds: 360));
    return List<ManagerLeaveRequest>.from(_managerRequests);
  }

  @override
  Future<ManagerLeaveRequest> submitManagerDecision({
    required String leaveId,
    required bool approve,
    String? note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 360));

    final requestIndex = _managerRequests.indexWhere(
      (item) => item.id == leaveId,
    );
    if (requestIndex == -1) {
      throw StateError('تعذر العثور على طلب الإجازة المطلوب.');
    }

    final current = _managerRequests[requestIndex];
    final trimmedNote = note?.trim() ?? '';
    final nextRequest = current.copyWith(
      status: approve
          ? ManagerLeaveWorkflowStatus.managerApproved
          : ManagerLeaveWorkflowStatus.rejected,
      managerNote: trimmedNote.isEmpty
          ? approve
                ? 'تمت الموافقة من المدير وإحالة الطلب إلى الموارد البشرية.'
                : 'تم رفض الطلب من المدير المباشر.'
          : trimmedNote,
      hrNote: approve
          ? 'بانتظار اعتماد الموارد البشرية بعد موافقة المدير.'
          : 'توقف مسار الطلب بسبب رفض المدير.',
    );
    _managerRequests[requestIndex] = nextRequest;

    final employeeIndex = _employeeRequests.indexWhere(
      (item) => item.id == leaveId,
    );
    if (employeeIndex != -1) {
      final employee = _employeeRequests[employeeIndex];
      _employeeRequests[employeeIndex] = EmployeeLeaveRequest(
        id: employee.id,
        title: employee.title,
        type: employee.type,
        periodLabel: employee.periodLabel,
        daysCount: employee.daysCount,
        status: approve
            ? LeaveRequestStatus.pending
            : LeaveRequestStatus.rejected,
        note: employee.note,
        requestedAtLabel: employee.requestedAtLabel,
        startDateLabel: employee.startDateLabel,
        endDateLabel: employee.endDateLabel,
        currentBalanceLabel: employee.currentBalanceLabel,
        remainingBalanceLabel: employee.remainingBalanceLabel,
        managerStatus: approve
            ? LeaveApprovalStatus.approved
            : LeaveApprovalStatus.rejected,
        hrStatus: approve
            ? LeaveApprovalStatus.pending
            : LeaveApprovalStatus.rejected,
        managerNote: nextRequest.managerNote,
        hrNote: nextRequest.hrNote,
      );
    }

    final hrIndex = _hrRequests.indexWhere((item) => item.id == leaveId);
    if (hrIndex != -1) {
      final hrRequest = _hrRequests[hrIndex];
      _hrRequests[hrIndex] = hrRequest.copyWith(
        status: approve
            ? HrLeaveWorkflowStatus.pendingHr
            : HrLeaveWorkflowStatus.rejected,
        hrNote: approve
            ? 'بانتظار قرار الموارد البشرية.'
            : 'توقف الطلب قبل وصوله إلى الموارد البشرية.',
      );
    }

    return nextRequest;
  }

  @override
  Future<List<HrLeaveRequest>> fetchHrLeaveRequests() async {
    await Future<void>.delayed(const Duration(milliseconds: 360));
    return List<HrLeaveRequest>.from(_hrRequests);
  }

  @override
  Future<HrLeaveRequest> submitHrDecision({
    required String leaveId,
    required bool approve,
    String? note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 360));

    final requestIndex = _hrRequests.indexWhere((item) => item.id == leaveId);
    if (requestIndex == -1) {
      throw StateError('تعذر العثور على طلب الإجازة المطلوب.');
    }

    final current = _hrRequests[requestIndex];
    final trimmedNote = note?.trim() ?? '';
    final nextRequest = current.copyWith(
      status: approve
          ? HrLeaveWorkflowStatus.approved
          : HrLeaveWorkflowStatus.rejected,
      hrNote: trimmedNote.isEmpty
          ? approve
                ? 'تم الاعتماد النهائي من الموارد البشرية.'
                : 'تم رفض الطلب من الموارد البشرية.'
          : trimmedNote,
    );
    _hrRequests[requestIndex] = nextRequest;

    final employeeIndex = _employeeRequests.indexWhere(
      (item) => item.id == leaveId,
    );
    if (employeeIndex != -1) {
      final employee = _employeeRequests[employeeIndex];
      _employeeRequests[employeeIndex] = EmployeeLeaveRequest(
        id: employee.id,
        title: employee.title,
        type: employee.type,
        periodLabel: employee.periodLabel,
        daysCount: employee.daysCount,
        status: approve
            ? LeaveRequestStatus.approved
            : LeaveRequestStatus.rejected,
        note: employee.note,
        requestedAtLabel: employee.requestedAtLabel,
        startDateLabel: employee.startDateLabel,
        endDateLabel: employee.endDateLabel,
        currentBalanceLabel: employee.currentBalanceLabel,
        remainingBalanceLabel: employee.remainingBalanceLabel,
        managerStatus: employee.managerStatus,
        hrStatus: approve
            ? LeaveApprovalStatus.approved
            : LeaveApprovalStatus.rejected,
        managerNote: employee.managerNote,
        hrNote: nextRequest.hrNote,
      );
    }

    final managerIndex = _managerRequests.indexWhere(
      (item) => item.id == leaveId,
    );
    if (managerIndex != -1) {
      final managerRequest = _managerRequests[managerIndex];
      _managerRequests[managerIndex] = managerRequest.copyWith(
        status: approve
            ? ManagerLeaveWorkflowStatus.fullyApproved
            : ManagerLeaveWorkflowStatus.rejected,
        hrNote: nextRequest.hrNote,
      );
    }

    return nextRequest;
  }

  String _leaveTypeLabel(String leaveType) {
    switch (leaveType) {
      case 'annual':
        return 'إجازة سنوية';
      case 'sick':
        return 'إجازة مرضية';
      case 'emergency':
        return 'إجازة اضطرارية';
      case 'unpaid':
        return 'إجازة بدون راتب';
      default:
        return 'إجازة';
    }
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

  String _formatDateTime(DateTime date) {
    final hour = date.hour > 12
        ? date.hour - 12
        : date.hour == 0
        ? 12
        : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'م' : 'ص';
    return '${_formatDate(date)} - ${hour.toString().padLeft(2, '0')}:$minute $suffix';
  }
}
