import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// AppLogo — Displays the official Meet Marketers AI logo with fallback support
class AppLogo extends StatelessWidget {
  final double size;
  final double? borderRadius;
  final bool showBorder;

  const AppLogo({
    super.key,
    this.size = 32,
    this.borderRadius,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? (size * 0.25);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ClinicSageColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: showBorder ? Border.all(color: ClinicSageColors.border, width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: ClinicSageColors.tertiary.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          'assets/logos/meet_marketers_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Graceful fallback if asset file is missing or customized
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: ClinicSageGradients.brandVibrant,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Center(
                child: Icon(
                  Icons.auto_awesome,
                  size: size * 0.5,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
