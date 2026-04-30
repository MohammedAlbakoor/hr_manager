import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'app_state_card.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppStateCard(
      title: title,
      message: message,
      visual: Container(
        height: 78,
        width: 78,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppPalette.primary.withValues(alpha: 0.14),
              AppPalette.secondary.withValues(alpha: 0.11),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(icon, color: AppPalette.primary, size: 34),
      ),
      actions: actionLabel != null && onAction != null
          ? [
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(actionLabel!),
              ),
            ]
          : const [],
    );
  }
}
