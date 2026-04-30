import 'package:flutter/material.dart';

class ResponsiveCardGrid extends StatelessWidget {
  const ResponsiveCardGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.desktopItemWidth = 255,
    this.maxColumns = 4,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double desktopItemWidth;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final compactSpacing = availableWidth < 560 ? 12.0 : spacing;
        final requestedColumns = availableWidth < 560
            ? 2
            : (availableWidth / (desktopItemWidth + spacing)).floor();
        final columns = requestedColumns
            .clamp(1, maxColumns)
            .clamp(1, children.length);
        final itemWidth =
            (availableWidth - (compactSpacing * (columns - 1))) / columns;

        return Wrap(
          spacing: compactSpacing,
          runSpacing: runSpacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}
