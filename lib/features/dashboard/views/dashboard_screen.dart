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
import '../../../shared/dialogs/create_client_dialog.dart';
import '../../../core/services/firebase_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Individual Client Dashboard & Command Center Screen
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showPortfolioOverview = false;

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientProvider);
    final activeClient = clientState.activeClient;

    if (clientState.isLoading) {
      return const Scaffold(
        backgroundColor: ClinicSageColors.neutral,
        body: Center(child: CircularProgressIndicator(color: ClinicSageColors.tertiary)),
      );
    }

    if (clientState.clients.isEmpty || activeClient == null) {
      return Scaffold(
        backgroundColor: ClinicSageColors.neutral,
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: ClinicSageColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ClinicSageColors.border),
              boxShadow: ClinicSageShadows.card,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: ClinicSageColors.tertiaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.business_outlined, size: 44, color: ClinicSageColors.tertiary),
                ),
                const SizedBox(height: 20),
                const Text(
                  'No Client Workspaces',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ClinicSageColors.primary),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your online Firestore database has 0 clients. Create your first client workspace to start ingesting discovery inputs, generating SWOT strategies, and automating deliverables.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: ClinicSageColors.secondary, height: 1.5),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClinicSageColors.tertiary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
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
                  label: const Text('Create New Client Workspace', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ClinicSageColors.neutral,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ClinicSageSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header & Client Selector Banner ──────────────────────
            _ClientDashboardHeader(
              activeClient: activeClient,
              allClients: clientState.clients,
              showPortfolioOverview: _showPortfolioOverview,
              onToggleMode: (val) => setState(() => _showPortfolioOverview = val),
            ),
            const SizedBox(height: ClinicSageSpacing.lg),

            if (_showPortfolioOverview) ...[
              // ── Global Agency Portfolio Overview ──────────────────
              _GlobalMetricsRow(clientCount: clientState.clients.length),
              const SizedBox(height: ClinicSageSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _ClientRosterTable(clients: clientState.clients),
                  ),
                  const SizedBox(width: ClinicSageSpacing.md),
                  const Expanded(
                    flex: 2,
                    child: _RecentActivityPanel(),
                  ),
                ],
              ),
            ] else ...[
              // ── Dedicated Individual Client Command Center ─────────
              _IndividualClientMetricsRow(client: activeClient),
              const SizedBox(height: ClinicSageSpacing.lg),

              // Phase Progress Lifecycle Stepper
              _PhaseLifecycleCard(client: activeClient),
              const SizedBox(height: ClinicSageSpacing.lg),

              // Deliverables Matrix & Knowledge Base Side-by-Side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 11 Deliverables Matrix for THIS client
                  Expanded(
                    flex: 3,
                    child: _IndividualDeliverablesMatrix(client: activeClient),
                  ),
                  const SizedBox(width: ClinicSageSpacing.md),
                  // Ingested Inputs Summary & Client Activity
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _IngestedKnowledgeSummaryCard(client: activeClient),
                        const SizedBox(height: ClinicSageSpacing.md),
                        _IndividualClientActivityCard(client: activeClient),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Client Dashboard Header Banner
// ─────────────────────────────────────────────────────────────────────────────
class _ClientDashboardHeader extends ConsumerWidget {
  final ClientModel activeClient;
  final List<ClientModel> allClients;
  final bool showPortfolioOverview;
  final ValueChanged<bool> onToggleMode;

  const _ClientDashboardHeader({
    required this.activeClient,
    required this.allClients,
    required this.showPortfolioOverview,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final accentColors = [
      ClinicSageColors.tertiary,
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
    ];
    final accentIndex = activeClient.name.isNotEmpty
        ? activeClient.name.codeUnitAt(0) % accentColors.length
        : 0;
    final accent = accentColors[accentIndex];

    return ClinicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Client Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent.withValues(alpha: 0.2), accent.withValues(alpha: 0.05)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(
                    activeClient.name.isNotEmpty
                        ? activeClient.name.substring(0, 1).toUpperCase()
                        : 'C',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Title & Client Selector Dropdown
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
                          child: Text(
                            showPortfolioOverview
                                ? 'ALL CLIENTS PORTFOLIO'
                                : 'INDIVIDUAL CLIENT WORKSPACE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: ClinicSageColors.tertiary,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (activeClient.industry.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: ClinicSageColors.neutral,
                              borderRadius: BorderRadius.circular(ClinicSageRadius.full),
                              border: Border.all(color: ClinicSageColors.border),
                            ),
                            child: Text(
                              activeClient.industry,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: ClinicSageColors.secondary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          showPortfolioOverview ? 'Agency Portfolio Overview' : activeClient.name,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: ClinicSageColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Client Selector Dropdown Button
                        if (allClients.length > 1)
                          PopupMenuButton<String>(
                            tooltip: 'Switch Client Workspace',
                            onSelected: (selectedId) {
                              ref.read(clientProvider.notifier).setActiveClient(selectedId);
                              onToggleMode(false);
                            },
                            itemBuilder: (ctx) => allClients.map((c) {
                              final isCurrent = c.id == activeClient.id;
                              return PopupMenuItem<String>(
                                value: c.id,
                                child: Row(
                                  children: [
                                    Icon(
                                      isCurrent ? Icons.check_circle : Icons.business,
                                      size: 16,
                                      color: isCurrent ? ClinicSageColors.tertiary : ClinicSageColors.secondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      c.name,
                                      style: TextStyle(
                                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                        color: isCurrent ? ClinicSageColors.tertiary : ClinicSageColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: ClinicSageColors.neutral,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: ClinicSageColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Switch Client',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: ClinicSageColors.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_drop_down, size: 16, color: ClinicSageColors.secondary),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Mode Toggle (Individual vs Global Portfolio)
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Client View'),
                    icon: Icon(Icons.person_pin, size: 14),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('All Clients'),
                    icon: Icon(Icons.grid_view, size: 14),
                  ),
                ],
                selected: {showPortfolioOverview},
                onSelectionChanged: (set) => onToggleMode(set.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 12),

              // New Client Button
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
          ),

          if (!showPortfolioOverview && activeClient.websiteUrl != null && activeClient.websiteUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.link, size: 14, color: ClinicSageColors.secondary),
                const SizedBox(width: 6),
                Text(
                  'Website Context: ',
                  style: theme.textTheme.labelSmall?.copyWith(color: ClinicSageColors.secondary),
                ),
                Text(
                  activeClient.websiteUrl!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: ClinicSageColors.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Last Activity: ${DateFormat('MMM d, yyyy · h:mm a').format(activeClient.lastActivity)}',
                  style: theme.textTheme.labelSmall?.copyWith(color: ClinicSageColors.secondary, fontSize: 10),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual Client Metrics Row
// ─────────────────────────────────────────────────────────────────────────────
class _IndividualClientMetricsRow extends ConsumerWidget {
  final ClientModel client;
  const _IndividualClientMetricsRow({required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int totalInputs = 0;
    if (client.websiteUrl != null && client.websiteUrl!.isNotEmpty) totalInputs++;
    if (client.pitchDeckStoragePath != null) totalInputs++;
    totalInputs += client.imageStoragePaths.length;
    totalInputs += client.documentStoragePaths.length;

    final amId = ref.watch(authProvider).user?.id ?? 'am-default';

    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: FirebaseService.instance.getDeliverables(amId, client.id),
      builder: (context, snapshot) {
        final deliverables = snapshot.data ?? {};
        int generatedCount = 0;
        int vettedCount = 0;

        for (final type in ContentType.values) {
          final data = deliverables[type.value];
          if (data != null) {
            final text = (data['vettedOutputText'] as String?) ?? (data['content'] as String?) ?? '';
            if (text.trim().isNotEmpty) {
              generatedCount++;
              final status = data['status'] as String? ?? 'draft';
              if (status == VettingStatus.vetted.value || status == VettingStatus.locked.value) {
                vettedCount++;
              }
            }
          }
        }

        final vettedPercentage = (vettedCount / 11 * 100).round();

        final metrics = [
          (
            icon: Icons.folder_zip_outlined,
            label: 'Ingested Files & Context',
            value: '$totalInputs Files',
            delta: '${client.questionnaireAnswers.length}/6 Answers',
            gradient: ClinicSageGradients.tertiary,
          ),
          (
            icon: Icons.auto_graph_outlined,
            label: 'Strategic Frameworks',
            value: client.extractedPdfContent != null ? 'Ready' : 'Pending',
            delta: 'Pitch Deck & SWOT',
            gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)]),
          ),
          (
            icon: Icons.collections_bookmark_outlined,
            label: 'Deliverables Generated',
            value: '$generatedCount / 11',
            delta: 'Phase 3 Production',
            gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]),
          ),
          (
            icon: Icons.verified_user_outlined,
            label: 'Vetted & Approved',
            value: '$vettedCount / 11',
            delta: '$vettedPercentage% Vetted',
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
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase Progress Lifecycle Stepper Card
// ─────────────────────────────────────────────────────────────────────────────
class _PhaseLifecycleCard extends StatelessWidget {
  final ClientModel client;
  const _PhaseLifecycleCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final phases = [
      (
        num: '01',
        title: 'Client Inputs',
        desc: 'Website, PDF Pitch Deck, Images & Documents Ingestion',
        route: AppRoutes.clientInputsPath(client.id),
        status: 'Ingested',
        icon: Icons.cloud_upload_outlined,
        color: ClinicSageColors.tertiary,
      ),
      (
        num: '02',
        title: 'Strategy Hub',
        desc: 'AI SWOT, Target SEO Keywords & Personas',
        route: AppRoutes.clientStrategyPath(client.id),
        status: 'Generated',
        icon: Icons.auto_awesome_outlined,
        color: const Color(0xFF3B82F6),
      ),
      (
        num: '03',
        title: 'Content Studio',
        desc: '11 Campaign Deliverable Types & Media Assets',
        route: AppRoutes.clientContentPath(client.id),
        status: 'In Production',
        icon: Icons.movie_creation_outlined,
        color: const Color(0xFF8B5CF6),
      ),
      (
        num: '04',
        title: 'Vetting & Review',
        desc: 'Human AM Sign-Off & Master Bundle Export',
        route: AppRoutes.clientReviewPath(client.id),
        status: 'Ready',
        icon: Icons.verified_outlined,
        color: const Color(0xFFF59E0B),
      ),
    ];

    return ClinicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    child: const Icon(Icons.alt_route, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text('Client Workflow Lifecycle', style: theme.textTheme.titleMedium),
                ],
              ),
              Text(
                'Active Workspace: ${client.name}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: ClinicSageColors.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: phases.asMap().entries.map((entry) {
              final idx = entry.key;
              final p = entry.value;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: idx < phases.length - 1 ? 12 : 0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ClinicSageColors.surface,
                    borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                    border: Border.all(color: p.color.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: p.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'PHASE ${p.num}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: p.color,
                                fontWeight: FontWeight.w800,
                                fontSize: 9,
                              ),
                            ),
                          ),
                          Icon(p.icon, size: 16, color: p.color),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        p.title,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.desc,
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => context.go(p.route),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: p.color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Open Phase',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: p.color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Icon(Icons.arrow_forward, size: 12, color: p.color),
                            ],
                          ),
                        ),
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// 11 Deliverables Matrix for THIS Specific Client
// ─────────────────────────────────────────────────────────────────────────────
class _IndividualDeliverablesMatrix extends ConsumerWidget {
  final ClientModel client;
  const _IndividualDeliverablesMatrix({required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final amId = ref.watch(authProvider).user?.id ?? 'am-default';

    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: FirebaseService.instance.getDeliverables(amId, client.id),
      builder: (context, snapshot) {
        final deliverables = snapshot.data ?? {};

        return ClinicCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
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
                          child: const Icon(Icons.dashboard_customize_outlined, size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${client.name} — 11 Campaign Deliverables', style: theme.textTheme.titleMedium),
                            Text('Real-time production and vetting status across all deliverable types in Firestore', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => context.go(AppRoutes.clientContentPath(client.id)),
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: const Text('Open Content Studio'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ContentType.values.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (ctx, idx) {
                  final type = ContentType.values[idx];
                  final delData = deliverables[type.value];
                  final text = delData != null ? ((delData['vettedOutputText'] as String?) ?? (delData['content'] as String?) ?? '') : '';
                  final isGenerated = text.trim().isNotEmpty;
                  final statusStr = delData != null ? (delData['status'] as String? ?? 'draft') : 'draft';
                  final status = isGenerated ? VettingStatus.fromString(statusStr) : VettingStatus.draft;

                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ClinicSageColors.tertiaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_typeIcon(type), size: 16, color: ClinicSageColors.tertiary),
                    ),
                    title: Text(
                      type.label,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      isGenerated ? 'Generated and saved to online Firestore' : 'Ready for AI generation',
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusBadge(status: status, compact: true),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 12, color: ClinicSageColors.secondary),
                          onPressed: () => context.go(AppRoutes.clientContentPath(client.id)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _typeIcon(ContentType type) {
    switch (type) {
      case ContentType.socialMediaPosts:
        return Icons.share_outlined;
      case ContentType.blogArticles:
        return Icons.article_outlined;
      case ContentType.emailCampaign:
        return Icons.email_outlined;
      case ContentType.seoKeywordAudit:
        return Icons.search_outlined;
      case ContentType.seoTechnicalAudit:
        return Icons.analytics_outlined;
      case ContentType.introDeck:
        return Icons.slideshow_outlined;
      case ContentType.salesPitchDeck:
        return Icons.present_to_all_outlined;
      case ContentType.explainerVideos:
        return Icons.video_library_outlined;
      case ContentType.testimonialVideos:
        return Icons.video_camera_front_outlined;
      case ContentType.otherDesigns:
        return Icons.palette_outlined;
      case ContentType.otherCopies:
        return Icons.text_snippet_outlined;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ingested Knowledge Base Summary Card
// ─────────────────────────────────────────────────────────────────────────────
class _IngestedKnowledgeSummaryCard extends StatelessWidget {
  final ClientModel client;
  const _IngestedKnowledgeSummaryCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClinicCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: ClinicSageColors.tertiaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.inventory_2_outlined, size: 16, color: ClinicSageColors.tertiary),
              ),
              const SizedBox(width: 10),
              Text('Ingested Knowledge Base', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 14),

          _knowledgeRow(
            icon: Icons.language,
            label: 'Website Crawler Context',
            value: client.websiteUrl != null && client.websiteUrl!.isNotEmpty ? client.websiteUrl! : 'Not ingested',
            isDone: client.websiteUrl != null && client.websiteUrl!.isNotEmpty,
          ),
          const SizedBox(height: 10),
          _knowledgeRow(
            icon: Icons.picture_as_pdf,
            label: 'PDF Pitch Deck Reference',
            value: client.pitchDeckStoragePath != null ? 'Uploaded PDF Deck' : 'Not uploaded',
            isDone: client.pitchDeckStoragePath != null,
          ),
          const SizedBox(height: 10),
          _knowledgeRow(
            icon: Icons.image,
            label: 'Brand Photos & Images',
            value: '${client.imageStoragePaths.length} Uploaded Files',
            isDone: client.imageStoragePaths.isNotEmpty,
          ),
          const SizedBox(height: 10),
          _knowledgeRow(
            icon: Icons.description,
            label: 'Word Docs & Reference PDFs',
            value: '${client.documentStoragePaths.length} Reference Docs',
            isDone: client.documentStoragePaths.isNotEmpty,
          ),
          const SizedBox(height: 10),
          _knowledgeRow(
            icon: Icons.quiz,
            label: 'Discovery Questionnaire',
            value: '${client.questionnaireAnswers.length}/6 Target Answers',
            isDone: client.questionnaireAnswers.length >= 6,
          ),
        ],
      ),
    );
  }

  Widget _knowledgeRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDone,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: isDone ? ClinicSageColors.tertiary : ClinicSageColors.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              Text(value, style: TextStyle(fontSize: 10, color: isDone ? ClinicSageColors.tertiary : ClinicSageColors.secondary)),
            ],
          ),
        ),
        Icon(
          isDone ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 14,
          color: isDone ? ClinicSageColors.tertiary : ClinicSageColors.border,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual Client Activity Card
// ─────────────────────────────────────────────────────────────────────────────
class _IndividualClientActivityCard extends StatelessWidget {
  final ClientModel client;
  const _IndividualClientActivityCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final activities = [
      _ActivityItem(
        icon: Icons.check_circle_outline,
        title: '${client.name} — Social Media Campaign vetted',
        time: 'Just now',
        type: VettingStatus.vetted,
      ),
      _ActivityItem(
        icon: Icons.auto_awesome,
        title: '${client.name} — AI SWOT matrix generated',
        time: '10 mins ago',
        type: VettingStatus.draft,
      ),
      _ActivityItem(
        icon: Icons.cloud_done_outlined,
        title: '${client.name} — Brand photos & docs ingested',
        time: '1 hour ago',
        type: VettingStatus.locked,
      ),
    ];

    return ClinicCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history, size: 16, color: Color(0xFF3B82F6)),
                ),
                const SizedBox(width: 10),
                Text('Activity History', style: theme.textTheme.titleMedium),
              ],
            ),
          ),
          const Divider(height: 1),
          ...activities.map((a) => _ActivityTile(activity: a)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Global Agency Portfolio Row & Table (For "All Clients" view)
// ─────────────────────────────────────────────────────────────────────────────
class _GlobalMetricsRow extends StatelessWidget {
  final int clientCount;
  const _GlobalMetricsRow({required this.clientCount});

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
        value: '${clientCount * 11}',
        delta: 'In progress',
        gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)]),
      ),
      (
        icon: Icons.verified_outlined,
        label: 'Vetted & Approved',
        value: '${(clientCount * 7.5).round()}',
        delta: '67% vetted',
        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]),
      ),
      (
        icon: Icons.pending_actions_outlined,
        label: 'Pending Review',
        value: '${clientCount * 3}',
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
                TextButton.icon(
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
                ),
              ],
            ),
          ),
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
          onTap: () {
            ref.read(clientProvider.notifier).setActiveClient(widget.client.id);
            GoRouter.of(context).go(AppRoutes.clientInputsPath(widget.client.id));
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
            decoration: BoxDecoration(
              color: _isHovered
                  ? ClinicSageColors.tertiaryLight.withValues(alpha: 0.6)
                  : widget.isEven
                      ? ClinicSageColors.surface
                      : ClinicSageColors.neutral.withValues(alpha: 0.4),
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
                            colors: [accent.withValues(alpha: 0.15), accent.withValues(alpha: 0.05)],
                          ),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: accent.withValues(alpha: 0.3)),
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
                        '11 assets',
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
                            onTap: () {
                              ref.read(clientProvider.notifier).setActiveClient(widget.client.id);
                              GoRouter.of(context).go(AppRoutes.clientInputsPath(widget.client.id));
                            },
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
          color: _isHovered ? ClinicSageColors.neutral.withValues(alpha: 0.6) : Colors.transparent,
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
