import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/proposal_pdf_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/proposal_model.dart';
import '../dialogs/create_lead_dialog.dart';
import '../providers/proposal_provider.dart';

/// Screen listing all Leads and Proposals with search, filters, metrics, and actions
class ProposalsScreen extends ConsumerStatefulWidget {
  const ProposalsScreen({super.key});

  @override
  ConsumerState<ProposalsScreen> createState() => _ProposalsScreenState();
}

class _ProposalsScreenState extends ConsumerState<ProposalsScreen> {
  String _searchQuery = '';
  String _selectedStatusFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(proposalProvider.notifier).loadProposals();
    });
  }

  void _openCreateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CreateLeadDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(proposalProvider);

    final filtered = state.proposals.where((p) {
      final matchesSearch = p.leadCompanyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.industry.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.websiteUrl.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _selectedStatusFilter == 'all' || p.status.value == _selectedStatusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    final readyCount = state.proposals.where((p) => p.status == ProposalStatus.readyForReview).length;
    final approvedCount = state.proposals.where((p) => p.status == ProposalStatus.approved).length;
    final sentCount = state.proposals.where((p) => p.status == ProposalStatus.sent).length;
    final convertedCount = state.proposals.where((p) => p.status == ProposalStatus.converted).length;

    return Scaffold(
      backgroundColor: ClinicSageColors.neutral,
      body: CustomScrollView(
        slivers: [
          // ── Top Bar ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                color: ClinicSageColors.surface,
                border: Border(bottom: BorderSide(color: ClinicSageColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: ClinicSageGradients.brandVibrant,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: ClinicSageShadows.aiGlow,
                    ),
                    child: const Icon(Icons.description_outlined, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Proposal Generation & Lead Engine',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Automated 13-section strategic proposals, review & PDF export, lead emails, and client conversion',
                        style: theme.textTheme.labelSmall?.copyWith(fontSize: 11, color: ClinicSageColors.secondary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ClinicSageColors.tertiary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    onPressed: _openCreateDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Lead Proposal'),
                  ),
                ],
              ),
            ),
          ),

          // ── Lead Pipeline Metrics Cards ──────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  _MetricCard(
                    title: 'Total Proposals',
                    value: '${state.proposals.length}',
                    icon: Icons.all_inbox_outlined,
                    color: const Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 14),
                  _MetricCard(
                    title: 'Ready for Review',
                    value: '$readyCount',
                    icon: Icons.rate_review_outlined,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 14),
                  _MetricCard(
                    title: 'Approved by AM',
                    value: '$approvedCount',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 14),
                  _MetricCard(
                    title: 'Sent to Lead',
                    value: '$sentCount',
                    icon: Icons.send_outlined,
                    color: const Color(0xFF0EA5E9),
                  ),
                  const SizedBox(width: 14),
                  _MetricCard(
                    title: 'Converted to Client',
                    value: '$convertedCount',
                    icon: Icons.workspace_premium_outlined,
                    color: const Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),
          ),

          // ── Search & Filter Controls ─────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  // Search Input
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search leads by company name, industry, or website...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: ClinicSageColors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                          borderSide: const BorderSide(color: ClinicSageColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                          borderSide: const BorderSide(color: ClinicSageColors.border),
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Filter Chips
                  _FilterChip(
                    label: 'All (${state.proposals.length})',
                    isSelected: _selectedStatusFilter == 'all',
                    onTap: () => setState(() => _selectedStatusFilter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Review ($readyCount)',
                    isSelected: _selectedStatusFilter == ProposalStatus.readyForReview.value,
                    onTap: () => setState(() => _selectedStatusFilter = ProposalStatus.readyForReview.value),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Approved ($approvedCount)',
                    isSelected: _selectedStatusFilter == ProposalStatus.approved.value,
                    onTap: () => setState(() => _selectedStatusFilter = ProposalStatus.approved.value),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Sent ($sentCount)',
                    isSelected: _selectedStatusFilter == ProposalStatus.sent.value,
                    onTap: () => setState(() => _selectedStatusFilter = ProposalStatus.sent.value),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Converted ($convertedCount)',
                    isSelected: _selectedStatusFilter == ProposalStatus.converted.value,
                    onTap: () => setState(() => _selectedStatusFilter = ProposalStatus.converted.value),
                  ),
                ],
              ),
            ),
          ),

          // ── Proposals List ────────────────────────────────────
          if (state.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: ClinicSageColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: ClinicSageColors.border),
                      ),
                      child: const Icon(Icons.description_outlined, size: 48, color: ClinicSageColors.secondary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.proposals.isEmpty ? 'No proposals created yet' : 'No matching proposals found',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Input a lead company name, website, and social URLs to automatically synthesize a 13-section proposal.',
                      style: theme.textTheme.bodySmall?.copyWith(color: ClinicSageColors.secondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ClinicSageColors.tertiary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _openCreateDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Create First Lead Proposal'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final proposal = filtered[index];
                    return _ProposalCard(proposal: proposal);
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metric Card
// ─────────────────────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: ClinicSageColors.surface,
          borderRadius: BorderRadius.circular(ClinicSageRadius.md),
          border: Border.all(color: ClinicSageColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: ClinicSageColors.secondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Chip
// ─────────────────────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? ClinicSageColors.tertiary : ClinicSageColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? ClinicSageColors.tertiary : ClinicSageColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : ClinicSageColors.secondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Proposal Card
// ─────────────────────────────────────────────────────────────────────────────
class _ProposalCard extends ConsumerWidget {
  final ProposalModel proposal;
  const _ProposalCard({required this.proposal});

  Color _getStatusColor(ProposalStatus status) {
    switch (status) {
      case ProposalStatus.draft:
        return const Color(0xFF64748B);
      case ProposalStatus.generating:
        return const Color(0xFF8B5CF6);
      case ProposalStatus.readyForReview:
        return const Color(0xFFF59E0B);
      case ProposalStatus.approved:
        return const Color(0xFF10B981);
      case ProposalStatus.sent:
        return const Color(0xFF0EA5E9);
      case ProposalStatus.converted:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(proposal.status);
    final dateFormat = DateFormat('MMM d, yyyy · HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClinicSageColors.surface,
        borderRadius: BorderRadius.circular(ClinicSageRadius.md),
        border: Border.all(color: ClinicSageColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor, statusColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.description, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),

          // Main Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      proposal.leadCompanyName,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor.withOpacity(0.35)),
                      ),
                      child: Text(
                        proposal.status.label,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.category_outlined, size: 13, color: ClinicSageColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      proposal.industry.isNotEmpty ? proposal.industry : 'General Growth',
                      style: theme.textTheme.bodySmall?.copyWith(color: ClinicSageColors.secondary),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.link, size: 13, color: ClinicSageColors.secondary),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        final url = proposal.websiteUrl;
                        if (url.isNotEmpty) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      },
                      child: Text(
                        proposal.websiteUrl,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ClinicSageColors.tertiary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.schedule, size: 13, color: ClinicSageColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(proposal.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(color: ClinicSageColors.secondary, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Export PDF
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Compiling and downloading Proposal PDF...')),
                  );
                  await ProposalPdfService.instance.exportAndDownloadPdf(proposal);
                },
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 15),
                label: const Text('Export PDF', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),

              // Open & Review
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ClinicSageColors.tertiary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () {
                  ref.read(proposalProvider.notifier).setActiveProposal(proposal.id);
                  context.go(AppRoutes.proposalDetailPath(proposal.id));
                },
                icon: const Icon(Icons.edit_note_outlined, size: 16),
                label: const Text('Open & Review', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
