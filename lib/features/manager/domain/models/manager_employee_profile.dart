import 'package:flutter/material.dart';

import '../../../common/domain/models/app_user_role.dart';
import 'manager_leave_request.dart';

enum ManagerAttendanceStatus {
  present(
    label: 'حضور',
    color: Color(0xFF0F766E),
    icon: Icons.check_circle_rounded,
  ),
  late(
    label: 'متأخر',
    color: Color(0xFFEA580C),
    icon: Icons.watch_later_rounded,
  ),
  absent(
    label: 'غياب',
    color: Color(0xFFDC2626),
    icon: Icons.person_off_rounded,
  );

  const ManagerAttendanceStatus({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

class ManagerEmployeeProfile {
  const ManagerEmployeeProfile({
    required this.id,
    required this.name,
    required this.code,
    required this.jobTitle,
    required this.department,
    required this.email,
    required this.phone,
    required this.leaveBalanceLabel,
    required this.usedLeavesLabel,
    required this.monthlyIncrement,
    required this.pendingLeavesCount,
    required this.todayAttendanceLabel,
    required this.lastCheckInLabel,
    required this.leaveItems,
    required this.attendanceItems,
    required this.workLocation,
    required this.workSchedule,
    required this.joinDate,
    this.role = AppUserRole.employee,
    this.roleLabel,
    this.deletedAt,
    this.managerId,
    this.managerName,
    this.managerCode,
  });

  final String id;
  final String name;
  final String code;
  final String jobTitle;
  final String department;
  final String email;
  final String phone;
  final String leaveBalanceLabel;
  final String usedLeavesLabel;
  final double monthlyIncrement;
  final int pendingLeavesCount;
  final String todayAttendanceLabel;
  final String lastCheckInLabel;
  final List<ManagerEmployeeLeaveItem> leaveItems;
  final List<ManagerEmployeeAttendanceItem> attendanceItems;
  final String workLocation;
  final String workSchedule;
  final String joinDate;
  final AppUserRole role;
  final String? roleLabel;
  final String? deletedAt;
  final int? managerId;
  final String? managerName;
  final String? managerCode;

  bool get isDeleted => deletedAt != null;
  bool get isActive => !isDeleted;

  ManagerEmployeeProfile copyWith({
    String? id,
    String? name,
    String? code,
    String? jobTitle,
    String? department,
    String? email,
    String? phone,
    String? leaveBalanceLabel,
    String? usedLeavesLabel,
    double? monthlyIncrement,
    int? pendingLeavesCount,
    String? todayAttendanceLabel,
    String? lastCheckInLabel,
    List<ManagerEmployeeLeaveItem>? leaveItems,
    List<ManagerEmployeeAttendanceItem>? attendanceItems,
    String? workLocation,
    String? workSchedule,
    String? joinDate,
    AppUserRole? role,
    String? roleLabel,
    String? deletedAt,
    int? managerId,
    String? managerName,
    String? managerCode,
    bool clearManager = false,
    bool clearDeletedAt = false,
  }) {
    return ManagerEmployeeProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      jobTitle: jobTitle ?? this.jobTitle,
      department: department ?? this.department,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      leaveBalanceLabel: leaveBalanceLabel ?? this.leaveBalanceLabel,
      usedLeavesLabel: usedLeavesLabel ?? this.usedLeavesLabel,
      monthlyIncrement: monthlyIncrement ?? this.monthlyIncrement,
      pendingLeavesCount: pendingLeavesCount ?? this.pendingLeavesCount,
      todayAttendanceLabel: todayAttendanceLabel ?? this.todayAttendanceLabel,
      lastCheckInLabel: lastCheckInLabel ?? this.lastCheckInLabel,
      leaveItems: leaveItems ?? this.leaveItems,
      attendanceItems: attendanceItems ?? this.attendanceItems,
      workLocation: workLocation ?? this.workLocation,
      workSchedule: workSchedule ?? this.workSchedule,
      joinDate: joinDate ?? this.joinDate,
      role: role ?? this.role,
      roleLabel: roleLabel ?? this.roleLabel,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      managerId: clearManager ? null : (managerId ?? this.managerId),
      managerName: clearManager ? null : (managerName ?? this.managerName),
      managerCode: clearManager ? null : (managerCode ?? this.managerCode),
    );
  }
}

class ManagerEmployeeLeaveItem {
  const ManagerEmployeeLeaveItem({
    required this.title,
    required this.periodLabel,
    required this.daysCount,
    required this.status,
  });

  final String title;
  final String periodLabel;
  final int daysCount;
  final ManagerLeaveWorkflowStatus status;
}

class ManagerEmployeeAttendanceItem {
  const ManagerEmployeeAttendanceItem({
    required this.dateLabel,
    required this.checkInLabel,
    required this.status,
  });

  final String dateLabel;
  final String checkInLabel;
  final ManagerAttendanceStatus status;
}
