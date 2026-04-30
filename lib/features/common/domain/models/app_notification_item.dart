import 'package:flutter/material.dart';

enum AppNotificationCategory {
  leave(
    label: 'الإجازات',
    icon: Icons.event_note_rounded,
    color: Color(0xFF1D4ED8),
  ),
  attendance(
    label: 'الدوام',
    icon: Icons.qr_code_scanner_rounded,
    color: Color(0xFF0F766E),
  ),
  system(
    label: 'النظام',
    icon: Icons.notifications_active_outlined,
    color: Color(0xFFEA580C),
  );

  const AppNotificationCategory({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeLabel,
    required this.category,
    required this.isRead,
    required this.actionLabel,
    this.actionRoute,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String title;
  final String message;
  final String timeLabel;
  final AppNotificationCategory category;
  final bool isRead;
  final String actionLabel;
  final String? actionRoute;
  final Map<String, dynamic> metadata;

  AppNotificationItem copyWith({bool? isRead}) {
    return AppNotificationItem(
      id: id,
      title: title,
      message: message,
      timeLabel: timeLabel,
      category: category,
      isRead: isRead ?? this.isRead,
      actionLabel: actionLabel,
      actionRoute: actionRoute,
      metadata: metadata,
    );
  }
}
