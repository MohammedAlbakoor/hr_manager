import 'package:flutter/material.dart';

enum AttendanceRecordStatus {
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

  const AttendanceRecordStatus({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.dateLabel,
    required this.dayLabel,
    required this.checkInTimeLabel,
    required this.status,
    required this.method,
    required this.locationLabel,
    required this.note,
  });

  final String id;
  final String dateLabel;
  final String dayLabel;
  final String checkInTimeLabel;
  final AttendanceRecordStatus status;
  final String method;
  final String locationLabel;
  final String note;
}
