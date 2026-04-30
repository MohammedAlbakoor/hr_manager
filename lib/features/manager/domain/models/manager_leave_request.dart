import 'package:flutter/material.dart';

enum ManagerLeaveWorkflowStatus {
  pendingReview(
    label: 'بانتظار مراجعة المدير',
    color: Color(0xFF7C3AED),
    icon: Icons.pending_actions_rounded,
  ),
  managerApproved(
    label: 'بانتظار الموارد البشرية',
    color: Color(0xFF1D4ED8),
    icon: Icons.approval_outlined,
  ),
  fullyApproved(
    label: 'معتمد نهائي',
    color: Color(0xFF0F766E),
    icon: Icons.verified_rounded,
  ),
  rejected(
    label: 'مرفوض',
    color: Color(0xFFDC2626),
    icon: Icons.cancel_rounded,
  );

  const ManagerLeaveWorkflowStatus({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

class ManagerLeaveRequest {
  const ManagerLeaveRequest({
    required this.id,
    required this.employeeName,
    required this.employeeCode,
    required this.department,
    required this.leaveType,
    required this.periodLabel,
    required this.startDateLabel,
    required this.endDateLabel,
    required this.daysCount,
    required this.submittedAtLabel,
    required this.employeeNote,
    required this.currentBalanceLabel,
    required this.remainingBalanceLabel,
    required this.monthlyIncrementLabel,
    required this.lastAttendanceLabel,
    required this.status,
    required this.managerNote,
    required this.hrNote,
  });

  final String id;
  final String employeeName;
  final String employeeCode;
  final String department;
  final String leaveType;
  final String periodLabel;
  final String startDateLabel;
  final String endDateLabel;
  final int daysCount;
  final String submittedAtLabel;
  final String employeeNote;
  final String currentBalanceLabel;
  final String remainingBalanceLabel;
  final String monthlyIncrementLabel;
  final String lastAttendanceLabel;
  final ManagerLeaveWorkflowStatus status;
  final String managerNote;
  final String hrNote;

  ManagerLeaveRequest copyWith({
    ManagerLeaveWorkflowStatus? status,
    String? managerNote,
    String? hrNote,
  }) {
    return ManagerLeaveRequest(
      id: id,
      employeeName: employeeName,
      employeeCode: employeeCode,
      department: department,
      leaveType: leaveType,
      periodLabel: periodLabel,
      startDateLabel: startDateLabel,
      endDateLabel: endDateLabel,
      daysCount: daysCount,
      submittedAtLabel: submittedAtLabel,
      employeeNote: employeeNote,
      currentBalanceLabel: currentBalanceLabel,
      remainingBalanceLabel: remainingBalanceLabel,
      monthlyIncrementLabel: monthlyIncrementLabel,
      lastAttendanceLabel: lastAttendanceLabel,
      status: status ?? this.status,
      managerNote: managerNote ?? this.managerNote,
      hrNote: hrNote ?? this.hrNote,
    );
  }
}
