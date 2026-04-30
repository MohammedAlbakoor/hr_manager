import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'app_state_card.dart';

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    super.key,
    this.title = 'جاري التحميل',
    this.message = 'يرجى الانتظار قليلاً.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppStateCard(
      title: title,
      message: message,
      maxWidth: 360,
      boxShadow: const [
        BoxShadow(
          color: AppPalette.shadow,
          blurRadius: 28,
          offset: Offset(0, 16),
        ),
      ],
      visual: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: const BoxDecoration(
              color: AppPalette.surfaceSoft,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(
            height: 42,
            width: 42,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ],
      ),
    );
  }
}
