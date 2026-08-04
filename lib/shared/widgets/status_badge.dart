import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/content_deliverable_model.dart';

/// Status badge for vetting workflow states
class StatusBadge extends StatelessWidget {
  final VettingStatus status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _StatusConfig.forStatus(status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(ClinicSageRadius.full),
        border: Border.all(color: config.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: config.dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: config.dotColor.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            compact ? _shortLabel(status) : status.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: config.textColor,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }

  String _shortLabel(VettingStatus s) {
    switch (s) {
      case VettingStatus.draft:
        return 'Draft';
      case VettingStatus.inReview:
        return 'Review';
      case VettingStatus.vetted:
        return 'Vetted';
      case VettingStatus.locked:
        return 'Locked';
    }
  }
}

class _StatusConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color dotColor;

  const _StatusConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.dotColor,
  });

  static _StatusConfig forStatus(VettingStatus status) {
    switch (status) {
      case VettingStatus.draft:
        return const _StatusConfig(
          backgroundColor: ClinicSageColors.statusDraftBg,
          borderColor: Color(0xFFD0DAD5),
          textColor: ClinicSageColors.statusDraft,
          dotColor: ClinicSageColors.statusDraft,
        );
      case VettingStatus.inReview:
        return const _StatusConfig(
          backgroundColor: Color(0xFFFEF3C7),
          borderColor: Color(0xFFFDE68A),
          textColor: Color(0xFF92400E),
          dotColor: Color(0xFFF59E0B),
        );
      case VettingStatus.vetted:
        return const _StatusConfig(
          backgroundColor: ClinicSageColors.statusVettedBg,
          borderColor: Color(0xFFA7D8BF),
          textColor: ClinicSageColors.statusVetted,
          dotColor: ClinicSageColors.statusVetted,
        );
      case VettingStatus.locked:
        return _StatusConfig(
          backgroundColor: const Color(0xFFEFF6FF),
          borderColor: const Color(0xFFBFDBFE),
          textColor: const Color(0xFF1D4ED8),
          dotColor: const Color(0xFF3B82F6),
        );
    }
  }
}

/// Client status chip — premium pill style
class ClientStatusChip extends StatelessWidget {
  final String label;
  final bool isActive;

  const ClientStatusChip({super.key, required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? ClinicSageColors.statusVettedBg : ClinicSageColors.statusDraftBg,
        borderRadius: BorderRadius.circular(ClinicSageRadius.full),
        border: Border.all(
          color: isActive ? const Color(0xFFA7D8BF) : const Color(0xFFD0DAD5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: isActive ? ClinicSageColors.tertiary : ClinicSageColors.secondary,
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [BoxShadow(color: ClinicSageColors.tertiary.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)]
                  : [],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isActive ? ClinicSageColors.tertiary : ClinicSageColors.secondary,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
