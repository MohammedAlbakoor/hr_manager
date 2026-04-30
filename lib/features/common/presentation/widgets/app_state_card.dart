import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class AppStateCard extends StatelessWidget {
  const AppStateCard({
    super.key,
    required this.title,
    required this.message,
    required this.visual,
    this.actions = const [],
    this.borderColor = AppPalette.border,
    this.boxShadow = const [],
    this.maxWidth = 420,
  });

  final String title;
  final String message;
  final Widget visual;
  final List<Widget> actions;
  final Color borderColor;
  final List<BoxShadow> boxShadow;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: borderColor),
              boxShadow: boxShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  visual,
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: actions,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
