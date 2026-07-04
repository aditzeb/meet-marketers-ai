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
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(ClinicSageRadius.sm),
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
            ),
          ),
          const SizedBox(width: 6),
          Text(
            compact ? _shortLabel(status) : status.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: config.textColor,
              fontWeight: FontWeight.w600,
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
          backgroundColor: Color(0xFFF5F2E8),
          borderColor: Color(0xFFE0D9C0),
          textColor: Color(0xFF8B7A4E),
          dotColor: Color(0xFF8B7A4E),
        );
      case VettingStatus.vetted:
        return const _StatusConfig(
          backgroundColor: ClinicSageColors.statusVettedBg,
          borderColor: Color(0xFFC0D9C8),
          textColor: ClinicSageColors.statusVetted,
          dotColor: ClinicSageColors.statusVetted,
        );
      case VettingStatus.locked:
        return const _StatusConfig(
          backgroundColor: ClinicSageColors.statusApprovedBg,
          borderColor: Color(0xFFA8C8B0),
          textColor: ClinicSageColors.statusApproved,
          dotColor: ClinicSageColors.statusApproved,
        );
    }
  }
}

/// Client status chip
class ClientStatusChip extends StatelessWidget {
  final String label;
  final bool isActive;

  const ClientStatusChip({super.key, required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? ClinicSageColors.statusVettedBg : ClinicSageColors.statusDraftBg,
        borderRadius: BorderRadius.circular(ClinicSageRadius.sm),
        border: Border.all(
          color: isActive ? const Color(0xFFC0D9C8) : const Color(0xFFD0DAD5),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isActive ? ClinicSageColors.tertiary : ClinicSageColors.secondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
