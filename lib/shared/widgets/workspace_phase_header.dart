import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../data/models/client_model.dart';

class WorkspacePhaseHeader extends StatelessWidget {
  final ClientModel client;
  final int activePhaseIndex; // 1 = Inputs, 2 = Strategy, 3 = Content, 4 = Review

  const WorkspacePhaseHeader({
    super.key,
    required this.client,
    required this.activePhaseIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final phases = [
      (index: 1, title: 'Client Inputs', shortTitle: 'Inputs', icon: Icons.description_outlined, route: AppRoutes.clientInputsPath(client.id)),
      (index: 2, title: 'Strategy Hub', shortTitle: 'Strategy', icon: Icons.insights_outlined, route: AppRoutes.clientStrategyPath(client.id)),
      (index: 3, title: 'Content Studio', shortTitle: 'Content', icon: Icons.video_library_outlined, route: AppRoutes.clientContentPath(client.id)),
      (index: 4, title: 'Vetting Review', shortTitle: 'Review', icon: Icons.verified_outlined, route: AppRoutes.clientReviewPath(client.id)),
    ];

    // Accent color for client avatar
    final accentColors = [
      ClinicSageColors.tertiary,
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];
    final accentIndex = client.name.isNotEmpty ? client.name.codeUnitAt(0) % accentColors.length : 0;
    final accent = accentColors[accentIndex];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      decoration: const BoxDecoration(
        color: ClinicSageColors.surface,
        border: Border(bottom: BorderSide(color: ClinicSageColors.border)),
      ),
      height: 56,
      child: Row(
        children: [
          // Client Badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent.withOpacity(0.2), accent.withOpacity(0.08)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent.withOpacity(0.35)),
                ),
                child: Center(
                  child: Text(
                    client.name.isNotEmpty ? client.name.substring(0, 1).toUpperCase() : 'C',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    client.name,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    client.industry,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: ClinicSageColors.secondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Separator
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: ClinicSageColors.border,
          ),

          // Phase Stepper
          Expanded(
            child: Row(
              children: phases.asMap().entries.map((entry) {
                final idx = entry.key;
                final p = entry.value;
                final isActive = p.index == activePhaseIndex;
                final isCompleted = p.index < activePhaseIndex;
                final isLast = idx == phases.length - 1;

                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _PhaseTab(
                          index: p.index,
                          title: p.title,
                          icon: p.icon,
                          isActive: isActive,
                          isCompleted: isCompleted,
                          onTap: () => GoRouter.of(context).go(p.route),
                        ),
                      ),
                      if (!isLast)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.chevron_right,
                            size: 14,
                            color: isCompleted
                                ? ClinicSageColors.tertiary.withOpacity(0.5)
                                : ClinicSageColors.border,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseTab extends StatefulWidget {
  final int index;
  final String title;
  final IconData icon;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback onTap;

  const _PhaseTab({
    required this.index,
    required this.title,
    required this.icon,
    required this.isActive,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  State<_PhaseTab> createState() => _PhaseTabState();
}

class _PhaseTabState extends State<_PhaseTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color textColor;
    Color bgColor;
    Color borderColor;

    if (widget.isActive) {
      textColor = ClinicSageColors.tertiary;
      bgColor = ClinicSageColors.tertiaryLight;
      borderColor = ClinicSageColors.tertiary.withOpacity(0.3);
    } else if (widget.isCompleted) {
      textColor = ClinicSageColors.secondary;
      bgColor = Colors.transparent;
      borderColor = Colors.transparent;
    } else {
      textColor = _isHovered ? ClinicSageColors.primary : ClinicSageColors.secondary;
      bgColor = _isHovered ? ClinicSageColors.neutral : Colors.transparent;
      borderColor = Colors.transparent;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Phase number badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: widget.isActive ? ClinicSageGradients.tertiary : null,
                    color: widget.isActive ? null : (widget.isCompleted ? ClinicSageColors.tertiaryLight : ClinicSageColors.neutral),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: widget.isCompleted && !widget.isActive
                        ? Icon(Icons.check, size: 10, color: ClinicSageColors.tertiary)
                        : Text(
                            '${widget.index}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: widget.isActive ? Colors.white : ClinicSageColors.secondary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: textColor,
                      fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
