import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/clinic_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../data/models/client_model.dart';
import '../../../data/models/content_deliverable_model.dart';
import '../providers/client_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/dialogs/create_client_dialog.dart';

/// AM Dashboard — client roster overview + metrics
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientState = ref.watch(clientProvider);

    return Scaffold(
      backgroundColor: ClinicSageColors.neutral,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ClinicSageSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────
            _DashboardHeader(),
            const SizedBox(height: ClinicSageSpacing.lg),

            // ── Metrics Row ───────────────────────────────────
            _MetricsRow(clientCount: clientState.clients.length),
            const SizedBox(height: ClinicSageSpacing.lg),

            // ── Content Body ─────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Client Roster Table
                Expanded(
                  flex: 3,
                  child: _ClientRosterTable(clients: clientState.clients),
                ),
                const SizedBox(width: ClinicSageSpacing.md),
                // Recent Activity
                const Expanded(
                  flex: 2,
                  child: _RecentActivityPanel(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authUser = ref.watch(authProvider).user;
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Good morning' : now.hour < 17 ? 'Good afternoon' : 'Good evening';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, ${authUser?.displayName ?? "Account Manager"}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Client Dashboard',
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(now),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            CreateClientDialog.show(
              context,
              onCreate: (name, industry, websiteUrl) async {
                final newClient = await ref.read(clientProvider.notifier).createClient(name, industry, websiteUrl);
                if (context.mounted) {
                  context.go(AppRoutes.clientInputsPath(newClient.id));
                }
              },
            );
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('New Client Workspace'),
        ),
      ],
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final int clientCount;
  const _MetricsRow({required this.clientCount});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (icon: Icons.people_outline, label: 'Active Clients', value: '$clientCount', delta: '+2 this month'),
      (icon: Icons.article_outlined, label: 'Deliverables', value: '${clientCount * 4}', delta: 'In progress'),
      (icon: Icons.verified_outlined, label: 'Vetted & Approved', value: '${(clientCount * 2.5).round()}', delta: '67% vetted'),
      (icon: Icons.pending_actions_outlined, label: 'Pending Review', value: '${clientCount * 2}', delta: 'Needs AM review'),
    ];

    return Row(
      children: metrics.map((m) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: metrics.last == m ? 0 : ClinicSageSpacing.md),
          child: MetricCard(
            icon: m.icon,
            label: m.label,
            value: m.value,
            delta: m.delta,
          ),
        ),
      )).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Client Roster Table
// ─────────────────────────────────────────────────────────────────────────────
class _ClientRosterTable extends ConsumerWidget {
  final List<ClientModel> clients;
  const _ClientRosterTable({required this.clients});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ClinicCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Client Portfolio', style: theme.textTheme.titleMedium),
                TextButton(
                  onPressed: () {
                    CreateClientDialog.show(
                      context,
                      onCreate: (name, industry, websiteUrl) async {
                        final newClient = await ref.read(clientProvider.notifier).createClient(name, industry, websiteUrl);
                        if (context.mounted) {
                          context.go(AppRoutes.clientInputsPath(newClient.id));
                        }
                      },
                    );
                  },
                  child: const Text('Add Client +'),
                ),
              ],
            ),
          ),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: const BoxDecoration(
              color: ClinicSageColors.neutral,
              border: Border.symmetric(
                horizontal: BorderSide(color: ClinicSageColors.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('CLIENT', style: theme.textTheme.labelSmall)),
                Expanded(flex: 2, child: Text('INDUSTRY', style: theme.textTheme.labelSmall)),
                Expanded(child: Text('DELIVERABLES', style: theme.textTheme.labelSmall, textAlign: TextAlign.center)),
                Expanded(child: Text('STATUS', style: theme.textTheme.labelSmall)),
                const SizedBox(width: 40),
              ],
            ),
          ),
          // Rows
          if (clients.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text('No clients yet. Click "Add Client +" to create a workspace.', style: theme.textTheme.bodySmall),
              ),
            )
          else
            ...clients.map((c) => _ClientTableRow(client: c)),
        ],
      ),
    );
  }
}

class _ClientTableRow extends ConsumerWidget {
  final ClientModel client;
  const _ClientTableRow({required this.client});

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Client Project'),
        content: Text(
          'Are you sure you want to delete "${client.name}"? This will permanently delete the client and all associated deliverables directly from Firestore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(clientProvider.notifier).deleteClient(client.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Client "${client.name}" deleted from Firestore.')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => GoRouter.of(context).go(AppRoutes.clientInputsPath(client.id)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: ClinicSageColors.border, width: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: ClinicSageColors.neutral,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: ClinicSageColors.border),
                      ),
                      child: Center(
                        child: Text(
                          client.name.isNotEmpty ? client.name.substring(0, 1) : 'C',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        client.name,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(client.industry, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                child: Text(
                  '4 deliverables',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ClientStatusChip(
                  label: client.status.label,
                  isActive: client.status == ClientStatus.active,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: Colors.red.shade400,
                    tooltip: 'Delete client project from Firestore',
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 14),
                    color: ClinicSageColors.secondary,
                    onPressed: () => GoRouter.of(context).go(AppRoutes.clientInputsPath(client.id)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Activity Panel
// ─────────────────────────────────────────────────────────────────────────────
class _RecentActivityPanel extends StatelessWidget {
  const _RecentActivityPanel();

  static const _activities = [
    _ActivityItem(
      icon: Icons.check_circle_outline,
      title: 'AlphaWave — Video Script vetted',
      time: '2 hours ago',
      type: VettingStatus.vetted,
    ),
    _ActivityItem(
      icon: Icons.edit_outlined,
      title: 'BetaForm — Ad Copy refined',
      time: '4 hours ago',
      type: VettingStatus.inReview,
    ),
    _ActivityItem(
      icon: Icons.auto_awesome,
      title: 'Gamma Health — SWOT generated',
      time: 'Yesterday 3pm',
      type: VettingStatus.draft,
    ),
    _ActivityItem(
      icon: Icons.lock_outlined,
      title: 'DeltaCore — Design Brief locked',
      time: 'Yesterday 11am',
      type: VettingStatus.locked,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClinicCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Text('Recent Activity', style: theme.textTheme.titleMedium),
          ),
          const Divider(height: 1),
          ..._activities.map((a) => _ActivityTile(activity: a)),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final _ActivityItem activity;
  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ClinicSageColors.border, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: ClinicSageColors.neutral,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(activity.icon, size: 14, color: ClinicSageColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title, style: theme.textTheme.bodySmall?.copyWith(
                  color: ClinicSageColors.primary,
                  fontWeight: FontWeight.w500,
                )),
                const SizedBox(height: 2),
                Text(activity.time, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(status: activity.type, compact: true),
        ],
      ),
    );
  }
}

class _ActivityItem {
  final IconData icon;
  final String title, time;
  final VettingStatus type;
  const _ActivityItem({required this.icon, required this.title, required this.time, required this.type});
}
