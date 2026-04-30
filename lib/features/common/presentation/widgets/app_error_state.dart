import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'app_state_card.dart';

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppStateCard(
      title: title,
      message: message,
      borderColor: const Color(0xFFFECACA),
      boxShadow: const [
        BoxShadow(
          color: AppPalette.shadow,
          blurRadius: 28,
          offset: Offset(0, 16),
        ),
      ],
      visual: Container(
        height: 78,
        width: 78,
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(
          Icons.error_outline_rounded,
          color: AppPalette.danger,
          size: 34,
        ),
      ),
      actions: onRetry != null
          ? [
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ]
          : const [],
    );
  }
}
