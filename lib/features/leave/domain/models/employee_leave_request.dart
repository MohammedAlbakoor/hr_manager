import 'package:flutter/material.dart';

enum LeaveRequestStatus {
  approved(
    label: 'موافق عليه',
    color: Color(0xFF0F766E),
    icon: Icons.check_circle_rounded,
  ),
  pending(
    label: 'قيد الانتظار',
    color: Color(0xFF7C3AED),
    icon: Icons.pending_actions_rounded,
  ),
  rejected(
    label: 'مرفوض',
    color: Color(0xFFDC2626),
    icon: Icons.cancel_rounded,
  );

  const LeaveRequestStatus({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

enum LeaveApprovalStatus {
  approved(
    label: 'تمت الموافقة',
    color: Color(0xFF0F766E),
    icon: Icons.check_circle_outline_rounded,
  ),
  pending(
    label: 'بانتظار المراجعة',
    color: Color(0xFF7C3AED),
    icon: Icons.schedule_rounded,
  ),
  rejected(
    label: 'تم الرفض',
    color: Color(0xFFDC2626),
    icon: Icons.highlight_off_rounded,
  );

  const LeaveApprovalStatus({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

class EmployeeLeaveRequest {
  const EmployeeLeaveRequest({
    required this.id,
    required this.title,
    required this.type,
    required this.periodLabel,
    required this.daysCount,
    required this.status,
    required this.note,
    required this.requestedAtLabel,
    required this.startDateLabel,
    required this.endDateLabel,
    required this.currentBalanceLabel,
    required this.remainingBalanceLabel,
    required this.managerStatus,
    required this.hrStatus,
    required this.managerNote,
    required this.hrNote,
  });

  final String id;
  final String title;
  final String type;
  final String periodLabel;
  final int daysCount;
  final LeaveRequestStatus status;
  final String note;
  final String requestedAtLabel;
  final String startDateLabel;
  final String endDateLabel;
  final String currentBalanceLabel;
  final String remainingBalanceLabel;
  final LeaveApprovalStatus managerStatus;
  final LeaveApprovalStatus hrStatus;
  final String managerNote;
  final String hrNote;
}
