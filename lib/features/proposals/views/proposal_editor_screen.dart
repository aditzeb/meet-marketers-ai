import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/proposal_pdf_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/proposal_model.dart';
import '../providers/proposal_provider.dart';

/// Comprehensive 13-Section Proposal Review & Editing Workspace
class ProposalEditorScreen extends ConsumerStatefulWidget {
  final String proposalId;
  const ProposalEditorScreen({super.key, required this.proposalId});

  @override
  ConsumerState<ProposalEditorScreen> createState() => _ProposalEditorScreenState();
}

class _ProposalEditorScreenState extends ConsumerState<ProposalEditorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ProposalModel _proposal;
  bool _isLoaded = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initProposal();
    });
  }

  void _initProposal() {
    final state = ref.read(proposalProvider);
    final p = state.getProposal(widget.proposalId);
    if (p != null) {
      setState(() {
        _proposal = p;
        _isLoaded = true;
      });
    } else {
      ref.read(proposalProvider.notifier).loadProposals().then((_) {
        final recheck = ref.read(proposalProvider).getProposal(widget.proposalId);
        if (recheck != null && mounted) {
          setState(() {
            _proposal = recheck;
            _isLoaded = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    await ref.read(proposalProvider.notifier).updateProposal(_proposal);
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✨ Proposal changes saved to Firestore!')),
      );
    }
  }

  Future<void> _handleApprove() async {
    await ref.read(proposalProvider.notifier).approveProposal(_proposal.id);
    setState(() {
      _proposal = _proposal.copyWith(status: ProposalStatus.approved);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Proposal approved! Ready to send to lead.')),
      );
    }
  }

  void _openSendDialog() {
    final nameCtrl = TextEditingController(text: _proposal.contactName);
    final emailCtrl = TextEditingController(text: _proposal.contactEmail);
    final subjectCtrl = TextEditingController(
      text: 'Digital & Content Direction Proposal for ${_proposal.leadCompanyName} — Meet Marketers AI',
    );
    final bodyCtrl = TextEditingController(
      text: '''Hi ${nameCtrl.text.isNotEmpty ? nameCtrl.text : 'Team'},\n\nWe have compiled the comprehensive Digital & Content Direction Proposal for ${_proposal.leadCompanyName}.\n\nOur strategic audit highlights high-impact opportunities across technical SEO, organic search discovery, and high-converting short-form video storytelling to strengthen your category leadership.\n\nPlease review the attached proposal blueprint. We look forward to partnering with your team.\n\nBest regards,\nMeet Marketers AI Team''',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClinicSageColors.surface,
        title: Row(
          children: [
            const Icon(Icons.send_outlined, color: Color(0xFF0EA5E9), size: 20),
            const SizedBox(width: 8),
            const Text('Send Proposal to Lead'),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Lead Contact Name *', hintText: 'e.g. Sarah Tan'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Lead Email Address *', hintText: 'sarah@example.com'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subjectCtrl,
                decoration: const InputDecoration(labelText: 'Email Subject'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Email Body Message'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (emailCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter lead email address')),
                );
                return;
              }

              final contactName = nameCtrl.text.trim();
              final contactEmail = emailCtrl.text.trim();
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(ctx);

              await ref.read(proposalProvider.notifier).markSent(
                _proposal.id,
                contactName: contactName,
                contactEmail: contactEmail,
              );

              setState(() {
                _proposal = _proposal.copyWith(
                  contactName: contactName,
                  contactEmail: contactEmail,
                  status: ProposalStatus.sent,
                  sentAt: DateTime.now(),
                );
              });

              // Launch mailto
              final mailtoUri = Uri(
                scheme: 'mailto',
                path: contactEmail,
                queryParameters: {
                  'subject': subjectCtrl.text,
                  'body': bodyCtrl.text,
                },
              );

              try {
                await launchUrl(mailtoUri);
              } catch (_) {}

              nav.pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('🚀 Proposal marked as Sent to Lead and email launched!')),
              );
            },
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Dispatch Email'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConvertToClient() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClinicSageColors.surface,
        title: const Text('Convert Lead to Client Workspace'),
        content: Text(
          'This will convert "${_proposal.leadCompanyName}" into an active client workspace in Firestore, copy this 13-section strategic proposal into their account folder for future reference, and navigate straight to the workspace.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm & Convert'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final newClient = await ref.read(proposalProvider.notifier).convertToClient(_proposal.id);
      if (newClient != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🎉 "${newClient.name}" converted to active Client Workspace!')),
        );
        context.go(AppRoutes.clientInputsPath(newClient.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final proposalState = ref.watch(proposalProvider);

    if (!_isLoaded) {
      return const Scaffold(
        backgroundColor: ClinicSageColors.neutral,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1111),
      body: Column(
        children: [
          // ── Top Bar ──────────────────────────────────────────
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF161B1B),
              border: Border(bottom: BorderSide(color: Color(0xFF2A3333))),
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => context.go(AppRoutes.proposals),
                  icon: const Icon(Icons.arrow_back, size: 14),
                  label: const Text('All Proposals', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 14),
                Container(width: 1, height: 28, color: ClinicSageColors.border),
                const SizedBox(width: 14),

                // Lead Info
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _proposal.leadCompanyName,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 10),
                        _StatusBadge(status: _proposal.status),
                      ],
                    ),
                    Text(
                      '${_proposal.industry} · ${_proposal.websiteUrl}',
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 10.5, color: ClinicSageColors.secondary),
                    ),
                  ],
                ),
                const Spacer(),

                // Action Buttons
                // Export PDF
                OutlinedButton.icon(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Compiling multi-page proposal PDF...')),
                    );
                    await ProposalPdfService.instance.exportAndDownloadPdf(_proposal);
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 15),
                  label: const Text('Export PDF', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),

                // Save
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _saveChanges,
                  icon: const Icon(Icons.save_outlined, size: 15),
                  label: Text(_isSaving ? 'Saving...' : 'Save', style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),

                // Approve Button
                if (_proposal.status == ProposalStatus.readyForReview || _proposal.status == ProposalStatus.draft)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: _handleApprove,
                    icon: const Icon(Icons.check, size: 15),
                    label: const Text('Approve Proposal', style: TextStyle(fontSize: 12)),
                  ),

                // Send to Lead Button
                if (_proposal.status == ProposalStatus.approved || _proposal.status == ProposalStatus.sent) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: _openSendDialog,
                    icon: const Icon(Icons.send_outlined, size: 15),
                    label: Text(_proposal.status == ProposalStatus.sent ? 'Resend Email' : 'Send to Lead', style: const TextStyle(fontSize: 12)),
                  ),
                ],

                // Convert to Client Button
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: _proposal.status == ProposalStatus.converted ? null : _handleConvertToClient,
                  icon: const Icon(Icons.workspace_premium_outlined, size: 15),
                  label: Text(
                    _proposal.status == ProposalStatus.converted ? 'Converted ✓' : 'Convert to Client →',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // ── Progress Banner if Generating ────────────────────
          if (proposalState.isGenerating)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: const Color(0xFF8B5CF6).withOpacity(0.08),
              child: Row(
                children: [
                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 10),
                  Text(
                    proposalState.generationStage,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

          // ── Tab Navigation ────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF161B1B),
              border: Border(bottom: BorderSide(color: Color(0xFF2A3333))),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFA3E635),
              labelColor: const Color(0xFFA3E635),
              unselectedLabelColor: const Color(0xFF94A3B8),
              tabs: const [
                Tab(text: '1. Strategy & SWOT & 4Ps'),
                Tab(text: '2. PEST & Positioning Map'),
                Tab(text: '3. Creative Direction & Reels'),
                Tab(text: '4. Copywriting & SEO Audit'),
              ],
            ),
          ),

          // ── Tab Views (13 Sections) ───────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1
                _Tab1Strategy(
                  proposal: _proposal,
                  onChanged: (p) => setState(() => _proposal = p),
                ),
                // Tab 2
                _Tab2MarketPositioning(
                  proposal: _proposal,
                  onChanged: (p) => setState(() => _proposal = p),
                ),
                // Tab 3
                _Tab3CreativeDirection(
                  proposal: _proposal,
                  onChanged: (p) => setState(() => _proposal = p),
                ),
                // Tab 4
                _Tab4CopywritingAndSeo(
                  proposal: _proposal,
                  onChanged: (p) => setState(() => _proposal = p),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Badge Helper
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final ProposalStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color col;
    switch (status) {
      case ProposalStatus.draft:
        col = const Color(0xFF64748B);
        break;
      case ProposalStatus.generating:
        col = const Color(0xFF8B5CF6);
        break;
      case ProposalStatus.readyForReview:
        col = const Color(0xFFF59E0B);
        break;
      case ProposalStatus.approved:
        col = const Color(0xFF10B981);
        break;
      case ProposalStatus.sent:
        col = const Color(0xFF0EA5E9);
        break;
      case ProposalStatus.converted:
        col = const Color(0xFF8B5CF6);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: col.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: col.withOpacity(0.35)),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: col),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: Strategy & Executive Summary & SWOT Matrix & 4Ps
// ─────────────────────────────────────────────────────────────────────────────
class _Tab1Strategy extends StatelessWidget {
  final ProposalModel proposal;
  final ValueChanged<ProposalModel> onChanged;

  const _Tab1Strategy({required this.proposal, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Pitch Deck Extraction Banner
        if (proposal.pitchDeckFileName != null || (proposal.extractedPitchDeckText != null && proposal.extractedPitchDeckText!.isNotEmpty))
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.08),
              borderRadius: BorderRadius.circular(ClinicSageRadius.md),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Color(0xFF10B981), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grounded in Company Pitch Deck: ${proposal.pitchDeckFileName ?? "Uploaded Deck.pdf"}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF065F46)),
                      ),
                      Text(
                        '${(proposal.extractedPitchDeckText ?? "").length} characters of brand DNA and strategic offerings extracted with Flutter engine and synthesized into this proposal.',
                        style: const TextStyle(fontSize: 11.5, color: ClinicSageColors.secondary),
                      ),
                    ],
                  ),
                ),
                if (proposal.extractedPitchDeckText != null && proposal.extractedPitchDeckText!.isNotEmpty)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF065F46),
                      side: const BorderSide(color: Color(0xFF10B981)),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: ClinicSageColors.surface,
                          title: Row(
                            children: [
                              const Icon(Icons.description_outlined, color: Color(0xFF10B981), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Extracted Pitch Deck Content — ${proposal.pitchDeckFileName ?? "Deck"}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          content: SizedBox(
                            width: 650,
                            height: 450,
                            child: SingleChildScrollView(
                              child: SelectableText(
                                proposal.extractedPitchDeckText!,
                                style: const TextStyle(fontSize: 12, height: 1.5, fontFamily: 'monospace'),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: const Text('View Extracted Text', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
          ),

        // Executive Summary Card
        _SectionContainer(
          title: 'Executive Summary',
          subtitle: 'Current market position and strategic growth opportunity (Pages 1 & 2 of PDF)',
          children: [
            _EditableField(
              label: 'Current Position Narrative',
              value: proposal.executiveSummaryPosition,
              onChanged: (val) => onChanged(proposal.copyWith(executiveSummaryPosition: val)),
            ),
            const SizedBox(height: 14),
            _EditableField(
              label: 'Strategic Opportunity',
              value: proposal.executiveSummaryOpportunity,
              onChanged: (val) => onChanged(proposal.copyWith(executiveSummaryOpportunity: val)),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 4-Quadrant SWOT Matrix
        _SectionContainer(
          title: 'SWOT Analysis Matrix',
          subtitle: '4-quadrant strategic diagnostic framework',
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SwotEditorBox(
                    title: 'STRENGTHS',
                    color: const Color(0xFF10B981),
                    items: proposal.swot.strengths,
                    onChanged: (list) => onChanged(proposal.copyWith(
                      swot: proposal.swot.copyWith(strengths: list),
                    )),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _SwotEditorBox(
                    title: 'WEAKNESSES',
                    color: const Color(0xFFEF4444),
                    items: proposal.swot.weaknesses,
                    onChanged: (list) => onChanged(proposal.copyWith(
                      swot: proposal.swot.copyWith(weaknesses: list),
                    )),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SwotEditorBox(
                    title: 'OPPORTUNITIES',
                    color: const Color(0xFF8B5CF6),
                    items: proposal.swot.opportunities,
                    onChanged: (list) => onChanged(proposal.copyWith(
                      swot: proposal.swot.copyWith(opportunities: list),
                    )),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _SwotEditorBox(
                    title: 'THREATS',
                    color: const Color(0xFFF59E0B),
                    items: proposal.swot.threats,
                    onChanged: (list) => onChanged(proposal.copyWith(
                      swot: proposal.swot.copyWith(threats: list),
                    )),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Marketing Mix (4Ps)
        _SectionContainer(
          title: 'Marketing Mix (4Ps Analysis)',
          subtitle: 'Product, Price, Place, and Promotion breakdown (Page 3 of PDF)',
          children: [
            _PBox(
              title: 'PRODUCT',
              current: proposal.marketingMix4Ps.productCurrent,
              opportunity: proposal.marketingMix4Ps.productOpportunity,
              onCurrentChanged: (v) => onChanged(proposal.copyWith(
                marketingMix4Ps: proposal.marketingMix4Ps.copyWith(productCurrent: v),
              )),
              onOppChanged: (v) => onChanged(proposal.copyWith(
                marketingMix4Ps: proposal.marketingMix4Ps.copyWith(productOpportunity: v),
              )),
            ),
            const SizedBox(height: 12),
            _PBox(
              title: 'PRICE',
              current: proposal.marketingMix4Ps.priceCurrent,
              opportunity: proposal.marketingMix4Ps.priceOpportunity,
              onCurrentChanged: (v) => onChanged(proposal.copyWith(
                marketingMix4Ps: proposal.marketingMix4Ps.copyWith(priceCurrent: v),
              )),
              onOppChanged: (v) => onChanged(proposal.copyWith(
                marketingMix4Ps: proposal.marketingMix4Ps.copyWith(priceOpportunity: v),
              )),
            ),
            const SizedBox(height: 12),
            _PBox(
              title: 'PLACE',
              current: proposal.marketingMix4Ps.placeCurrent,
              opportunity: proposal.marketingMix4Ps.placeOpportunity,
              onCurrentChanged: (v) => onChanged(proposal.copyWith(
                marketingMix4Ps: proposal.marketingMix4Ps.copyWith(placeCurrent: v),
              )),
              onOppChanged: (v) => onChanged(proposal.copyWith(
                marketingMix4Ps: proposal.marketingMix4Ps.copyWith(placeOpportunity: v),
              )),
            ),
            const SizedBox(height: 12),
            _PBox(
              title: 'PROMOTION',
              current: proposal.marketingMix4Ps.promotionCurrent,
              opportunity: proposal.marketingMix4Ps.promotionOpportunity,
              onCurrentChanged: (v) => onChanged(proposal.copyWith(
                marketingMix4Ps: proposal.marketingMix4Ps.copyWith(promotionCurrent: v),
              )),
              onOppChanged: (v) => onChanged(proposal.copyWith(
                marketingMix4Ps: proposal.marketingMix4Ps.copyWith(promotionOpportunity: v),
              )),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: PEST Analysis, Competitor Benchmark & Perceptual Map
// ─────────────────────────────────────────────────────────────────────────────
class _Tab2MarketPositioning extends StatelessWidget {
  final ProposalModel proposal;
  final ValueChanged<ProposalModel> onChanged;

  const _Tab2MarketPositioning({required this.proposal, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final pest = proposal.pestAnalysis;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // PEST Analysis
        _SectionContainer(
          title: 'PEST Environmental Analysis',
          subtitle: 'Political, Economic, Social, and Technological market drivers (Page 4 of PDF)',
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SwotEditorBox(
                    title: 'POLITICAL',
                    color: const Color(0xFF6366F1),
                    items: pest.political,
                    onChanged: (l) => onChanged(proposal.copyWith(pestAnalysis: pest.copyWith(political: l))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SwotEditorBox(
                    title: 'ECONOMIC',
                    color: const Color(0xFF10B981),
                    items: pest.economic,
                    onChanged: (l) => onChanged(proposal.copyWith(pestAnalysis: pest.copyWith(economic: l))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SwotEditorBox(
                    title: 'SOCIAL',
                    color: const Color(0xFFF59E0B),
                    items: pest.social,
                    onChanged: (l) => onChanged(proposal.copyWith(pestAnalysis: pest.copyWith(social: l))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SwotEditorBox(
                    title: 'TECHNOLOGICAL',
                    color: const Color(0xFF8B5CF6),
                    items: pest.technological,
                    onChanged: (l) => onChanged(proposal.copyWith(pestAnalysis: pest.copyWith(technological: l))),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Competitor & USP Analysis
        _SectionContainer(
          title: 'Competitor & USP Analysis',
          subtitle: 'Unique Selling Propositions across peer landscape (Page 4 of PDF)',
          children: [
            // Table Header in Lime Green
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFA3E635),
                borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 160,
                    child: Text('Brand', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0A0D0D), fontSize: 12.5)),
                  ),
                  Expanded(
                    child: Text('Primary USP', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0A0D0D), fontSize: 12.5)),
                  ),
                ],
              ),
            ),
            // Table Rows
            ...proposal.competitorUsps.map((c) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: c.isLeadBrand ? const Color(0xFF1A2621) : const Color(0xFF111616),
                  border: Border(
                    left: const BorderSide(color: Color(0xFF334141), width: 0.5),
                    right: const BorderSide(color: Color(0xFF334141), width: 0.5),
                    bottom: const BorderSide(color: Color(0xFF334141), width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 160,
                      child: Text(
                        c.brandName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: c.isLeadBrand ? const Color(0xFFA3E635) : Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(c.primaryUsp, style: const TextStyle(fontSize: 13, color: Color(0xFFE2E8F0))),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 20),

        // Perceptual Map & Positioning
        _SectionContainer(
          title: 'Perceptual Map & Strategic Positioning',
          subtitle: 'Coordinate cross positioning framework and strategic insight (Page 5 of PDF)',
          children: [
            // Visual Coordinate Map Preview Box
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF111616),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334141)),
              ),
              child: Column(
                children: [
                  Text(
                    '${proposal.leadCompanyName.toUpperCase()} MARKET POSITIONING',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.white, letterSpacing: 1),
                  ),
                  const SizedBox(height: 12),
                  const Text('HIGH: Premium Experience Perception', style: TextStyle(fontSize: 10, color: Color(0xFFA3E635), fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('LOW\nBreadth', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.white70)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 90,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF445050), width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Stack(
                            children: [
                              // Cross axis lines
                              Center(child: Container(height: 1, color: const Color(0xFF334141))),
                              Center(child: Container(width: 1, color: const Color(0xFF334141))),
                              // Quadrant labels
                              Positioned(
                                top: 8,
                                left: 12,
                                child: Text(
                                  '• ${proposal.leadCompanyName}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFFA3E635)),
                                ),
                              ),
                              const Positioned(
                                top: 8,
                                right: 12,
                                child: Text('• Luxury Peers', style: TextStyle(fontSize: 10, color: Colors.white70)),
                              ),
                              const Positioned(
                                bottom: 8,
                                left: 12,
                                child: Text('• Generic Peers', style: TextStyle(fontSize: 10, color: Colors.white54)),
                              ),
                              const Positioned(
                                bottom: 8,
                                right: 12,
                                child: Text('• Mass Operators', style: TextStyle(fontSize: 10, color: Colors.white54)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('HIGH\nBreadth', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('LOW: Premium Experience Perception', style: TextStyle(fontSize: 10, color: Colors.white70)),
                ],
              ),
            ),
            _EditableField(
              label: 'Positioning Narrative',
              value: proposal.perceptualMapNarrative,
              onChanged: (v) => onChanged(proposal.copyWith(perceptualMapNarrative: v)),
            ),
            const SizedBox(height: 14),
            _EditableField(
              label: 'Key Strategic Insight',
              value: proposal.perceptualMapInsight,
              onChanged: (v) => onChanged(proposal.copyWith(perceptualMapInsight: v)),
            ),
            const SizedBox(height: 14),
            _EditableField(
              label: 'Core Market Opportunity',
              value: proposal.perceptualMapOpportunity,
              onChanged: (v) => onChanged(proposal.copyWith(perceptualMapOpportunity: v)),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3: Creative Direction, Visual Guidelines & Sample Reel
// ─────────────────────────────────────────────────────────────────────────────
class _Tab3CreativeDirection extends StatelessWidget {
  final ProposalModel proposal;
  final ValueChanged<ProposalModel> onChanged;

  const _Tab3CreativeDirection({required this.proposal, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Creative Direction Pillars
        _SectionContainer(
          title: 'Creative Direction: 5 Strategic Content Pillars',
          subtitle: 'Experience, Education, Corporate B2B, Lifestyle, and Customer Proof (Pages 6 & 7 of PDF)',
          children: [
            ...proposal.creativePillars.map((p) {
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ClinicSageColors.neutral,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ClinicSageColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(p.objective, style: const TextStyle(fontSize: 13, color: ClinicSageColors.secondary)),
                    const SizedBox(height: 10),
                    Text('Content Formats: ${p.contentStyle.join(' · ')}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('Sample Topics: “${p.exampleTopics.join('” · “')}”', style: const TextStyle(fontSize: 12, color: Color(0xFF10B981))),
                  ],
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 20),

        // Visual Guidelines & Color Swatches
        _SectionContainer(
          title: 'Visual Guideline & Palette',
          subtitle: 'Brand aesthetic direction and color harmony (Page 8 of PDF)',
          children: [
            _EditableField(
              label: 'Aesthetic Direction Notes',
              value: proposal.visualGuidelineNotes,
              onChanged: (v) => onChanged(proposal.copyWith(visualGuidelineNotes: v)),
            ),
            const SizedBox(height: 14),
            Row(
              children: proposal.brandPaletteHex.map((hex) {
                final clean = hex.replaceAll('#', '');
                final r = int.tryParse(clean.substring(0, 2), radix: 16) ?? 16;
                final g = int.tryParse(clean.substring(2, 4), radix: 16) ?? 185;
                final b = int.tryParse(clean.substring(4, 6), radix: 16) ?? 129;
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(r, g, b, 1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ClinicSageColors.border),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(hex, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Sample Reel Storyboard
        _SectionContainer(
          title: 'Sample Reel & Short-Form Video Blueprint',
          subtitle: 'High-converting 9:16 vertical video storyboard (Page 9 of PDF)',
          children: [
            _EditableField(
              label: 'Reel Topic',
              value: proposal.sampleReelTopic,
              onChanged: (v) => onChanged(proposal.copyWith(sampleReelTopic: v)),
            ),
            const SizedBox(height: 12),
            _EditableField(
              label: 'The 3-Second Hook',
              value: proposal.sampleReelHook,
              onChanged: (v) => onChanged(proposal.copyWith(sampleReelHook: v)),
            ),
            const SizedBox(height: 12),
            _EditableField(
              label: 'Visual Storyboard & Scenes',
              value: proposal.sampleReelVisualScenes,
              maxLines: 4,
              onChanged: (v) => onChanged(proposal.copyWith(sampleReelVisualScenes: v)),
            ),
            const SizedBox(height: 12),
            _EditableField(
              label: 'Call to Action (Outro)',
              value: proposal.sampleReelCta,
              onChanged: (v) => onChanged(proposal.copyWith(sampleReelCta: v)),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4: Copywriting & SEO Audit & Final Thoughts
// ─────────────────────────────────────────────────────────────────────────────
class _Tab4CopywritingAndSeo extends StatelessWidget {
  final ProposalModel proposal;
  final ValueChanged<ProposalModel> onChanged;

  const _Tab4CopywritingAndSeo({required this.proposal, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Sample Blog Article
        _SectionContainer(
          title: 'Sample Copywriting: SEO Blog Article',
          subtitle: 'Long-form thought leadership and storytelling pillar (Page 10 of PDF)',
          children: [
            _EditableField(
              label: 'Suggested Article Title',
              value: proposal.sampleBlogTitle,
              onChanged: (v) => onChanged(proposal.copyWith(sampleBlogTitle: v)),
            ),
            const SizedBox(height: 12),
            _EditableField(
              label: 'Storytelling Narrative Strategy',
              value: proposal.sampleBlogStorytellingIntro,
              onChanged: (v) => onChanged(proposal.copyWith(sampleBlogStorytellingIntro: v)),
            ),
            const SizedBox(height: 12),
            _EditableField(
              label: 'Article Preview Excerpt',
              value: proposal.sampleBlogPreview,
              maxLines: 4,
              onChanged: (v) => onChanged(proposal.copyWith(sampleBlogPreview: v)),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Sample Social Media Post
        _SectionContainer(
          title: 'Sample Social Media Copywriting',
          subtitle: 'High-converting Instagram & LinkedIn caption blueprint (Page 11 of PDF)',
          children: [
            _EditableField(
              label: 'Post Hook',
              value: proposal.sampleSocialCaptionHook,
              onChanged: (v) => onChanged(proposal.copyWith(sampleSocialCaptionHook: v)),
            ),
            const SizedBox(height: 12),
            _EditableField(
              label: 'Body Narrative',
              value: proposal.sampleSocialCaptionBody,
              maxLines: 3,
              onChanged: (v) => onChanged(proposal.copyWith(sampleSocialCaptionBody: v)),
            ),
            const SizedBox(height: 12),
            _EditableField(
              label: 'Call to Action',
              value: proposal.sampleSocialCaptionCta,
              onChanged: (v) => onChanged(proposal.copyWith(sampleSocialCaptionCta: v)),
            ),
            const SizedBox(height: 12),
            Text(
              'Hashtags: ${proposal.sampleSocialHashtags.join(' ')}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF8B5CF6), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // SEO & Digital Audit
        _SectionContainer(
          title: 'SEO & Digital Presence Opportunities',
          subtitle: 'Health score and prioritized optimization roadmap (Page 12 of PDF)',
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Column(
                    children: [
                      const Text('SEO HEALTH SCORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                      Text(
                        '${proposal.seoAudit.healthScore} / 100',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    proposal.seoAudit.summaryText,
                    style: const TextStyle(fontSize: 13, color: ClinicSageColors.secondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('High Priority Initiatives:', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
            ...proposal.seoAudit.highPriority.map((h) => Text('• $h', style: const TextStyle(fontSize: 13))),
            const SizedBox(height: 10),
            const Text('Medium Priority Enhancements:', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6))),
            ...proposal.seoAudit.mediumPriority.map((m) => Text('• $m', style: const TextStyle(fontSize: 13))),
            const SizedBox(height: 10),
            const Text('Long-Term Opportunities:', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
            ...proposal.seoAudit.longTermOpportunities.map((l) => Text('• $l', style: const TextStyle(fontSize: 13))),
          ],
        ),
        const SizedBox(height: 20),

        // Final Thoughts & Recommendation
        _SectionContainer(
          title: 'Final Thoughts & Assessment',
          subtitle: 'Executive sign-off and immediate strategic next steps (Page 13 of PDF)',
          children: [
            _EditableField(
              label: 'Executive Conclusion',
              value: proposal.finalThoughtsSummary,
              maxLines: 3,
              onChanged: (v) => onChanged(proposal.copyWith(finalThoughtsSummary: v)),
            ),
            const SizedBox(height: 12),
            _EditableField(
              label: 'Strategic Roadmap Recommendation',
              value: proposal.finalThoughtsRecommendation,
              maxLines: 3,
              onChanged: (v) => onChanged(proposal.copyWith(finalThoughtsRecommendation: v)),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Section Container
// ─────────────────────────────────────────────────────────────────────────────
class _SectionContainer extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SectionContainer({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B1B),
        borderRadius: BorderRadius.circular(ClinicSageRadius.md),
        border: Border.all(color: const Color(0xFF2A3333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFFA3E635))),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Editable Text Box Helper
// ─────────────────────────────────────────────────────────────────────────────
class _EditableField extends StatelessWidget {
  final String label;
  final String value;
  final int maxLines;
  final ValueChanged<String> onChanged;

  const _EditableField({
    required this.label,
    required this.value,
    this.maxLines = 2,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFA3E635)),
        alignLabelWithHint: true,
      ),
      onChanged: onChanged,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SWOT Editor Box
// ─────────────────────────────────────────────────────────────────────────────
class _SwotEditorBox extends StatelessWidget {
  final String title;
  final Color color;
  final List<String> items;
  final ValueChanged<List<String>> onChanged;

  const _SwotEditorBox({
    required this.title,
    required this.color,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111616),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334141)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFA3E635),
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0A0D0D), fontSize: 12.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: items.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: TextFormField(
                    initialValue: e.value,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    onChanged: (val) {
                      final list = List<String>.from(items);
                      list[e.key] = val;
                      onChanged(list);
                    },
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

// ─────────────────────────────────────────────────────────────────────────────
// 4Ps Box
// ─────────────────────────────────────────────────────────────────────────────
class _PBox extends StatelessWidget {
  final String title;
  final String current;
  final String opportunity;
  final ValueChanged<String> onCurrentChanged;
  final ValueChanged<String> onOppChanged;

  const _PBox({
    required this.title,
    required this.current,
    required this.opportunity,
    required this.onCurrentChanged,
    required this.onOppChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111616),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334141)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFA3E635),
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0A0D0D), fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextFormField(
                  initialValue: current,
                  style: const TextStyle(fontSize: 12.5, color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Current Approach',
                    labelStyle: TextStyle(color: Color(0xFFA3E635)),
                    isDense: true,
                  ),
                  onChanged: onCurrentChanged,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: opportunity,
                  style: const TextStyle(fontSize: 12.5, color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Strategic Opportunity',
                    labelStyle: TextStyle(color: Color(0xFFA3E635)),
                    isDense: true,
                  ),
                  onChanged: onOppChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
