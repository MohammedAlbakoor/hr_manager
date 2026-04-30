import 'package:flutter/material.dart';

enum HrLeaveWorkflowStatus {
  waitingManager(
    label: 'بانتظار قرار المدير',
    color: Color(0xFF7C3AED),
    icon: Icons.pending_actions_rounded,
  ),
  pendingHr(
    label: 'بانتظار قرار الموارد البشرية',
    color: Color(0xFF1D4ED8),
    icon: Icons.approval_outlined,
  ),
  approved(
    label: 'معتمد نهائي',
    color: Color(0xFF0F766E),
    icon: Icons.verified_rounded,
  ),
  rejected(
    label: 'مرفوض',
    color: Color(0xFFDC2626),
    icon: Icons.cancel_rounded,
  );

  const HrLeaveWorkflowStatus({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

class HrLeaveRequest {
  const HrLeaveRequest({
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
    required this.managerStatusLabel,
    required this.managerNote,
    required this.hrNote,
    required this.status,
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
  final String managerStatusLabel;
  final String managerNote;
  final String hrNote;
  final HrLeaveWorkflowStatus status;

  HrLeaveRequest copyWith({HrLeaveWorkflowStatus? status, String? hrNote}) {
    return HrLeaveRequest(
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
      managerStatusLabel: managerStatusLabel,
      managerNote: managerNote,
      hrNote: hrNote ?? this.hrNote,
      status: status ?? this.status,
    );
  }
}
