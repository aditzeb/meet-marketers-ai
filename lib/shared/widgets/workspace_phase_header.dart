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
      (index: 1, title: 'Client Inputs', icon: Icons.description_outlined, route: AppRoutes.clientInputsPath(client.id)),
      (index: 2, title: 'Strategy Hub', icon: Icons.insights_outlined, route: AppRoutes.clientStrategyPath(client.id)),
      (index: 3, title: 'Content Studio', icon: Icons.video_library_outlined, route: AppRoutes.clientContentPath(client.id)),
      (index: 4, title: 'Vetting Review', icon: Icons.verified_outlined, route: AppRoutes.clientReviewPath(client.id)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: ClinicSageColors.surface,
        border: Border(bottom: BorderSide(color: ClinicSageColors.border)),
      ),
      child: Row(
        children: [
          // Client Badge
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ClinicSageColors.tertiaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    client.name.isNotEmpty ? client.name.substring(0, 1) : 'C',
                    style: theme.textTheme.titleSmall?.copyWith(color: ClinicSageColors.tertiary, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(client.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  Text(client.industry, style: theme.textTheme.labelSmall?.copyWith(color: ClinicSageColors.secondary)),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Phase Stepper Tabs
          Row(
            children: phases.map((p) {
              final isActive = p.index == activePhaseIndex;
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: InkWell(
                  onTap: () => GoRouter.of(context).go(p.route),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? ClinicSageColors.tertiary : ClinicSageColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? ClinicSageColors.tertiary : ClinicSageColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          p.icon,
                          size: 14,
                          color: isActive ? Colors.white : ClinicSageColors.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Phase ${p.index}: ${p.title}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isActive ? Colors.white : ClinicSageColors.primary,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
