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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ClinicSageColors.tertiaryLight,
                      borderRadius: BorderRadius.circular(ClinicSageRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: ClinicSageColors.tertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          DateFormat('EEEE, MMMM d').format(now),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: ClinicSageColors.tertiary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '$greeting, ${authUser?.displayName ?? "Account Manager"} 👋',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: ClinicSageColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Client Dashboard',
                style: theme.textTheme.headlineLarge,
              ),
            ],
          ),
        ),
        Consumer(builder: (context, ref, _) {
          return ElevatedButton.icon(
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
          );
        }),
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
      (
        icon: Icons.people_outline,
        label: 'Active Clients',
        value: '$clientCount',
        delta: '+2 this month',
        gradient: ClinicSageGradients.tertiary,
      ),
      (
        icon: Icons.article_outlined,
        label: 'Deliverables',
        value: '${clientCount * 4}',
        delta: 'In progress',
        gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)]),
      ),
      (
        icon: Icons.verified_outlined,
        label: 'Vetted & Approved',
        value: '${(clientCount * 2.5).round()}',
        delta: '67% vetted',
        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]),
      ),
      (
        icon: Icons.pending_actions_outlined,
        label: 'Pending Review',
        value: '${clientCount * 2}',
        delta: 'Needs AM review',
        gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
      ),
    ];

    return Row(
      children: metrics.asMap().entries.map((entry) {
        final i = entry.key;
        final m = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < metrics.length - 1 ? ClinicSageSpacing.md : 0),
            child: MetricCard(
              icon: m.icon,
              label: m.label,
              value: m.value,
              delta: m.delta,
              iconGradient: m.gradient,
            ),
          ),
        );
      }).toList(),
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
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        gradient: ClinicSageGradients.tertiary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.people_outline, size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Text('Client Portfolio', style: theme.textTheme.titleMedium),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: ClinicSageColors.tertiaryLight,
                        borderRadius: BorderRadius.circular(ClinicSageRadius.full),
                      ),
                      child: Text(
                        '${clients.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: ClinicSageColors.tertiary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                Consumer(builder: (context, ref, _) {
                  return TextButton.icon(
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
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Add Client'),
                  );
                }),
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
                Expanded(flex: 3, child: Text('CLIENT', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.8))),
                Expanded(flex: 2, child: Text('INDUSTRY', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.8))),
                Expanded(child: Text('DELIVERABLES', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.8), textAlign: TextAlign.center)),
                Expanded(child: Text('STATUS', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.8))),
                const SizedBox(width: 56),
              ],
            ),
          ),
          // Rows
          if (clients.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ClinicSageColors.neutral,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.work_outline, size: 28, color: ClinicSageColors.secondary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No clients yet',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Click "Add Client" to create your first workspace.',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...clients.asMap().entries.map((e) => _ClientTableRow(client: e.value, isEven: e.key % 2 == 0)),
        ],
      ),
    );
  }
}

class _ClientTableRow extends ConsumerStatefulWidget {
  final ClientModel client;
  final bool isEven;
  const _ClientTableRow({required this.client, required this.isEven});

  @override
  ConsumerState<_ClientTableRow> createState() => _ClientTableRowState();
}

class _ClientTableRowState extends ConsumerState<_ClientTableRow> {
  bool _isHovered = false;

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Client Project'),
        content: Text(
          'Are you sure you want to delete "${widget.client.name}"? This will permanently delete the client and all associated deliverables directly from Firestore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B1C1C),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(clientProvider.notifier).deleteClient(widget.client.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Client "${widget.client.name}" deleted from Firestore.')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Consistent color per client
    final accentColors = [
      ClinicSageColors.tertiary,
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];
    final accentIndex = widget.client.name.isNotEmpty ? widget.client.name.codeUnitAt(0) % accentColors.length : 0;
    final accent = accentColors[accentIndex];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => GoRouter.of(context).go(AppRoutes.clientInputsPath(widget.client.id)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
            decoration: BoxDecoration(
              color: _isHovered
                  ? ClinicSageColors.tertiaryLight.withOpacity(0.6)
                  : widget.isEven
                      ? ClinicSageColors.surface
                      : ClinicSageColors.neutral.withOpacity(0.4),
              border: const Border(bottom: BorderSide(color: ClinicSageColors.border, width: 0.5)),
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
                          gradient: LinearGradient(
                            colors: [accent.withOpacity(0.15), accent.withOpacity(0.05)],
                          ),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: accent.withOpacity(0.3)),
                        ),
                        child: Center(
                          child: Text(
                            widget.client.name.isNotEmpty ? widget.client.name.substring(0, 1).toUpperCase() : 'C',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.client.name,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(widget.client.industry, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: ClinicSageColors.neutral,
                        borderRadius: BorderRadius.circular(ClinicSageRadius.full),
                        border: Border.all(color: ClinicSageColors.border),
                      ),
                      child: Text(
                        '4 assets',
                        style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ClientStatusChip(
                    label: widget.client.status.label,
                    isActive: widget.client.status == ClientStatus.active,
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: _isHovered ? 1.0 : 0.4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'Delete client',
                          child: InkWell(
                            onTap: () => _confirmDelete(context),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade400),
                            ),
                          ),
                        ),
                        Tooltip(
                          message: 'Open workspace',
                          child: InkWell(
                            onTap: () => GoRouter.of(context).go(AppRoutes.clientInputsPath(widget.client.id)),
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.arrow_forward_ios, size: 12, color: ClinicSageColors.secondary),
                            ),
                          ),
                        ),
                      ],
                    ),
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text('Recent Activity', style: theme.textTheme.titleMedium),
              ],
            ),
          ),
          const Divider(height: 1),
          ..._activities.map((a) => _ActivityTile(activity: a)),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatefulWidget {
  final _ActivityItem activity;
  const _ActivityTile({required this.activity});

  @override
  State<_ActivityTile> createState() => _ActivityTileState();
}

class _ActivityTileState extends State<_ActivityTile> {
  bool _isHovered = false;

  Color _iconColor(VettingStatus status) {
    switch (status) {
      case VettingStatus.vetted:
        return ClinicSageColors.tertiary;
      case VettingStatus.inReview:
        return const Color(0xFFF59E0B);
      case VettingStatus.locked:
        return const Color(0xFF3B82F6);
      case VettingStatus.draft:
        return ClinicSageColors.secondary;
    }
  }

  Color _iconBg(VettingStatus status) {
    switch (status) {
      case VettingStatus.vetted:
        return ClinicSageColors.tertiaryLight;
      case VettingStatus.inReview:
        return const Color(0xFFFEF3C7);
      case VettingStatus.locked:
        return const Color(0xFFEFF6FF);
      case VettingStatus.draft:
        return ClinicSageColors.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          color: _isHovered ? ClinicSageColors.neutral.withOpacity(0.6) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: ClinicSageColors.border, width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _iconBg(widget.activity.type),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(widget.activity.icon, size: 13, color: _iconColor(widget.activity.type)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.activity.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ClinicSageColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(widget.activity.time, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(status: widget.activity.type, compact: true),
          ],
        ),
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
