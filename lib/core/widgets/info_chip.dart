import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Small rounded pill: an optional icon and a label. Sits on sand cards.
class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.label,
    this.icon,
    this.emphasised = false,
    this.color,
  });

  final String label;
  final IconData? icon;

  /// Filled with the primary colour (navy) instead of white.
  final bool emphasised;

  /// Overrides the text and icon colour for non-emphasised chips.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;
    final bg = emphasised
        ? scheme.primary
        : (isLight ? Colors.white : AppColors.darkBackground);
    final fg = emphasised ? scheme.onPrimary : (color ?? scheme.onSurface);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
