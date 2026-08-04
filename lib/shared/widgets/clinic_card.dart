import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Reusable Meet Marketers AI styled card widget with hover effect
class ClinicCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool elevated;
  final Color? backgroundColor;

  const ClinicCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.elevated = false,
    this.backgroundColor,
  });

  @override
  State<ClinicCard> createState() => _ClinicCardState();
}

class _ClinicCardState extends State<ClinicCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final canHover = widget.onTap != null;

    return MouseRegion(
      onEnter: canHover ? (_) => setState(() => _isHovered = true) : null,
      onExit: canHover ? (_) => setState(() => _isHovered = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: (widget.elevated || (canHover && _isHovered)
                ? ClinicSageDecorations.cardElevated
                : ClinicSageDecorations.card)
            .copyWith(color: widget.backgroundColor ?? ClinicSageColors.surface),
        child: widget.onTap != null
            ? Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(ClinicSageRadius.lg),
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(ClinicSageRadius.lg),
                  splashColor: ClinicSageColors.tertiaryLight,
                  highlightColor: ClinicSageColors.tertiaryLight.withOpacity(0.5),
                  child: Padding(
                    padding: widget.padding ?? const EdgeInsets.all(24),
                    child: widget.child,
                  ),
                ),
              )
            : Padding(
                padding: widget.padding ?? const EdgeInsets.all(24),
                child: widget.child,
              ),
      ),
    );
  }
}

/// Section header with optional action
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

/// Premium metric stat card for dashboard
class MetricCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? accentColor;
  final String? delta;
  final LinearGradient? iconGradient;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor,
    this.delta,
    this.iconGradient,
  });

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.accentColor ?? ClinicSageColors.tertiary;
    final gradient = widget.iconGradient ?? LinearGradient(colors: [accent, accent.withOpacity(0.7)]);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ClinicSageColors.surface,
          borderRadius: BorderRadius.circular(ClinicSageRadius.lg),
          border: Border.all(
            color: _isHovered ? accent.withOpacity(0.3) : ClinicSageColors.border,
          ),
          boxShadow: _isHovered ? ClinicSageShadows.cardHover : ClinicSageShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                    boxShadow: _isHovered ? ClinicSageShadows.aiGlow : [],
                  ),
                  child: Icon(widget.icon, size: 17, color: Colors.white),
                ),
                if (widget.delta != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ClinicSageColors.tertiaryLight,
                      borderRadius: BorderRadius.circular(ClinicSageRadius.full),
                    ),
                    child: Text(
                      widget.delta!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: ClinicSageColors.tertiary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(widget.label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
