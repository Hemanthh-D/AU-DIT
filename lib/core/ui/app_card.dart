import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Premium card with subtle gradient border and soft shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.gradientBorder = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool gradientBorder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHighest.withAlpha(100) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withAlpha(isDark ? 60 : 20),
            blurRadius: isDark ? 12 : 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: gradientBorder
              ? AppColors.teal.withAlpha(40)
              : scheme.outlineVariant.withAlpha(isDark ? 80 : 120),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
