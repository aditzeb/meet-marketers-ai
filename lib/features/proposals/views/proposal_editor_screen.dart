import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/proposal_pdf_service.dart';
import '../../../core/services/proposal_domain_engine.dart';
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
  bool _isExporting = false;

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

  Future<void> _handleDeleteProposal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClinicSageColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_outlined, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Delete Proposal?'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete the proposal for "${_proposal.leadCompanyName}"?\n\nThis will remove all strategic analysis, copywriting, and media assets for this lead.',
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(proposalProvider.notifier).deleteProposal(_proposal.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑 Proposal for "${_proposal.leadCompanyName}" deleted.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
        context.go(AppRoutes.proposals);
      }
    }
  }

  Future<void> _handleRegenerateProposal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 24),
            SizedBox(width: 10),
            Text('Regenerate with AI Domain Intelligence?'),
          ],
        ),
        content: Text(
          'This will re-synthesize the 13-section strategy for "${_proposal.leadCompanyName}" using our domain intelligence engine and AI. Your proposal will be refreshed with sector-specific SWOT, 4Ps, Competitors, Creative Pillars, Visual Direction, and SEO analysis.',
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text('Regenerate Now'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final updated = await ref.read(proposalProvider.notifier).regenerateProposal(_proposal.id);
        if (updated != null && mounted) {
          setState(() {
            _proposal = updated;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ Proposal regenerated with domain intelligence and latest AI!'),
              backgroundColor: ClinicSageColors.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error regenerating proposal: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    }
  }

  bool _isLegacyGeneralContent(ProposalModel p) {
    if (p.industry.toLowerCase().contains('yacht')) return false;
    final socialText = p.socialPosts.map((s) => s.values.join(' ')).join(' ');
    final allText = '${p.executiveSummaryPosition} ${p.swot.strengths.join(' ')} ${p.swot.opportunities.join(' ')} ${p.marketingMix4Ps.productCurrent} $socialText'.toLowerCase();
    return allText.contains('retreats and team bonding') ||
        allText.contains('booming experiential economy') ||
        allText.contains('diverse service packages and high visual appeal') ||
        allText.contains('competitor alpha') ||
        allText.contains('hotel ballroom') ||
        allText.contains('private charter') ||
        allText.contains('private yacht') ||
        allText.contains('whitesails') ||
        allText.contains('charter') ||
        allText.contains('yacht');
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
      backgroundColor: ClinicSageColors.neutral,
      body: Column(
        children: [
          // ── Top Bar ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: ClinicSageColors.surface,
              border: Border(bottom: BorderSide(color: ClinicSageColors.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go(AppRoutes.proposals),
                  tooltip: 'Back to Proposals',
                ),
                const SizedBox(width: 8),
                if (_proposal.companyLogoUrl != null && _proposal.companyLogoUrl!.trim().isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 36,
                      height: 36,
                      color: Colors.white,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: _proposal.companyLogoUrl!.startsWith('data:image')
                          ? Image.memory(
                              base64Decode(_proposal.companyLogoUrl!.substring(_proposal.companyLogoUrl!.indexOf(',') + 1)),
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 16),
                            )
                          : Image.network(
                              _proposal.companyLogoUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 16),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _proposal.leadCompanyName,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(status: _proposal.status),
                        ],
                      ),
                      Text(
                        '${_proposal.industry} · ${_proposal.websiteUrl}',
                        style: theme.textTheme.bodySmall?.copyWith(color: ClinicSageColors.secondary),
                      ),
                    ],
                  ),
                ),

                // Export PDF Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: _isExporting ? null : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _isExporting = true);
                    try {
                      // 1. Auto-save all current edits to Firestore
                      await ref.read(proposalProvider.notifier).updateProposal(_proposal);
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('⚡ Edits saved! Compiling updated 13-page luxury proposal PDF with your latest content...')),
                        );
                      }
                      // 2. Export and trigger browser download with latest proposal model
                      await ProposalPdfService.instance.exportAndDownloadPdf(_proposal);
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('✅ 13-page PDF downloaded with all your latest edits & visuals!')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red.shade700),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isExporting = false);
                    }
                  },
                  icon: _isExporting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFA3E635)))
                      : const Icon(Icons.picture_as_pdf, size: 15, color: Color(0xFFA3E635)),
                  label: Text(_isExporting ? 'Exporting...' : 'Export PDF', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),

                // Regenerate with AI Button (Prominent)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: proposalState.isGenerating ? null : _handleRegenerateProposal,
                  icon: const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                  label: const Text('Regenerate with AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),

                // Save Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ClinicSageColors.primary,
                    side: const BorderSide(color: ClinicSageColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
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
                const SizedBox(width: 6),

                // Delete Proposal Button
                IconButton(
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                    hoverColor: Colors.red.withOpacity(0.08),
                    padding: const EdgeInsets.all(8),
                  ),
                  tooltip: 'Delete Proposal',
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: _handleDeleteProposal,
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

          // ── Legacy Outdated Content Warning Banner ─────────────
          if (_isLegacyGeneralContent(_proposal))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: const Color(0xFFFEF3C7),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Legacy General Content Detected',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                        ),
                        Text(
                          'This proposal was generated before our latest domain precision engine update. Click "Regenerate with AI" to synthesize deep pitch deck intelligence for ${_proposal.leadCompanyName}.',
                          style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 15),
                    label: const Text('Regenerate Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    onPressed: proposalState.isGenerating ? null : _handleRegenerateProposal,
                  ),
                ],
              ),
            ),

          // ── Tab Navigation ────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: ClinicSageColors.surface,
              border: Border(bottom: BorderSide(color: ClinicSageColors.border)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: ClinicSageColors.primary,
              labelColor: ClinicSageColors.primary,
              unselectedLabelColor: ClinicSageColors.secondary,
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
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0)),
                  left: BorderSide(color: Color(0xFFE2E8F0)),
                  right: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 170,
                    child: Text('Brand', style: TextStyle(fontWeight: FontWeight.w700, color: ClinicSageColors.primary, fontSize: 13)),
                  ),
                  Expanded(
                    child: Text('Primary USP', style: TextStyle(fontWeight: FontWeight.w700, color: ClinicSageColors.primary, fontSize: 13)),
                  ),
                ],
              ),
            ),
            // Table Rows
            ...proposal.competitorUsps.map((c) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: c.isLeadBrand ? const Color(0xFFF0FDF4) : Colors.white,
                  border: Border(
                    left: const BorderSide(color: Color(0xFFE2E8F0)),
                    right: const BorderSide(color: Color(0xFFE2E8F0)),
                    bottom: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 170,
                      child: Text(
                        c.brandName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: c.isLeadBrand ? const Color(0xFF15803D) : ClinicSageColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(c.primaryUsp, style: const TextStyle(fontSize: 13, color: ClinicSageColors.secondary)),
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
            Builder(builder: (context) {
              final mapData = ProposalDomainEngine.instance.resolvePerceptualMapData(proposal);
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${proposal.leadCompanyName.toUpperCase()} MARKET POSITIONING',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: ClinicSageColors.primary, letterSpacing: 1),
                    ),
                    const SizedBox(height: 12),
                    Text('HIGH: ${mapData.yAxisLabel}', style: const TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text('LOW\n${mapData.xAxisLabel}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: ClinicSageColors.secondary)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Stack(
                              children: [
                                Center(child: Container(height: 1, color: const Color(0xFFE2E8F0))),
                                Center(child: Container(width: 1, color: const Color(0xFFE2E8F0))),
                                // Quadrant 1 (Top-Right): LEAD BRAND (High Y, High X)
                                Positioned(
                                  top: 10,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                                    child: Text(
                                      '★ ${mapData.topRightBrand}',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF15803D)),
                                    ),
                                  ),
                                ),
                                // Quadrant 2 (Top-Left): Niche / High Y, Low X
                                Positioned(
                                  top: 10,
                                  left: 12,
                                  child: Text('• ${mapData.topLeftBrand}', style: const TextStyle(fontSize: 10.5, color: ClinicSageColors.secondary)),
                                ),
                                // Quadrant 3 (Bottom-Left): Low Y, Low X
                                Positioned(
                                  bottom: 10,
                                  left: 12,
                                  child: Text('• ${mapData.bottomLeftBrand}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                                ),
                                // Quadrant 4 (Bottom-Right): Low Y, High X
                                Positioned(
                                  bottom: 10,
                                  right: 12,
                                  child: Text('• ${mapData.bottomRightBrand}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: Text('HIGH\n${mapData.xAxisLabel}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Color(0xFF15803D), fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('LOW: ${mapData.yAxisLabel}', style: const TextStyle(fontSize: 11, color: ClinicSageColors.secondary)),
                  ],
                ),
              );
            }),
            Row(
              children: [
                Expanded(
                  child: _EditableField(
                    label: 'Vertical (Y-Axis) Attribute',
                    value: proposal.perceptualMapYAxis.isNotEmpty
                        ? proposal.perceptualMapYAxis
                        : ProposalDomainEngine.instance.resolvePerceptualMapData(proposal).yAxisLabel,
                    onChanged: (v) => onChanged(proposal.copyWith(perceptualMapYAxis: v)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EditableField(
                    label: 'Horizontal (X-Axis) Attribute',
                    value: proposal.perceptualMapXAxis.isNotEmpty
                        ? proposal.perceptualMapXAxis
                        : ProposalDomainEngine.instance.resolvePerceptualMapData(proposal).xAxisLabel,
                    onChanged: (v) => onChanged(proposal.copyWith(perceptualMapXAxis: v)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _EditableField(
              label: 'Positioning Narrative',
              value: proposal.perceptualMapNarrative,
              maxLines: 3,
              onChanged: (v) => onChanged(proposal.copyWith(perceptualMapNarrative: v)),
            ),
            const SizedBox(height: 14),
            _EditableField(
              label: 'Key Strategic Insight',
              value: proposal.perceptualMapInsight,
              maxLines: 2,
              onChanged: (v) => onChanged(proposal.copyWith(perceptualMapInsight: v)),
            ),
            const SizedBox(height: 14),
            _EditableField(
              label: 'Core Market Opportunity',
              value: proposal.perceptualMapOpportunity,
              maxLines: 2,
              onChanged: (v) => onChanged(proposal.copyWith(perceptualMapOpportunity: v)),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Media Picker Card: "Choose AI or Upload by Self"
// ─────────────────────────────────────────────────────────────────────────────
class _MediaPickerCard extends ConsumerStatefulWidget {
  final String title;
  final String? mediaUrl;
  final String promptHint;
  final String proposalId;
  final String? logoUrl;
  final String? companyName;
  final ValueChanged<String> onMediaUrlChanged;

  const _MediaPickerCard({
    required this.title,
    required this.mediaUrl,
    required this.promptHint,
    required this.proposalId,
    this.logoUrl,
    this.companyName,
    required this.onMediaUrlChanged,
  });

  @override
  ConsumerState<_MediaPickerCard> createState() => _MediaPickerCardState();
}

class _MediaPickerCardState extends ConsumerState<_MediaPickerCard> {
  bool _isGenerating = false;
  bool _isUploading = false;
  late TextEditingController _urlCtrl;
  late TextEditingController _promptCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: widget.mediaUrl ?? '');
    _promptCtrl = TextEditingController(text: widget.promptHint);
  }

  @override
  void didUpdateWidget(covariant _MediaPickerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaUrl != widget.mediaUrl && widget.mediaUrl != _urlCtrl.text) {
      _urlCtrl.text = widget.mediaUrl ?? '';
    }
    if (oldWidget.promptHint != widget.promptHint && _promptCtrl.text == oldWidget.promptHint) {
      _promptCtrl.text = widget.promptHint;
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateAi() async {
    setState(() => _isGenerating = true);
    try {
      final notifier = ref.read(proposalProvider.notifier);
      final activePrompt = _promptCtrl.text.trim().isNotEmpty ? _promptCtrl.text.trim() : widget.promptHint;
      final url = await notifier.generateAiAssetImage(
        prompt: activePrompt,
        category: widget.title,
        proposalId: widget.proposalId,
        logoUrl: widget.logoUrl,
        companyName: widget.companyName,
      );
      if (mounted) {
        _urlCtrl.text = url;
        widget.onMediaUrlChanged(url);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ OpenRouter AI visual synthesized for ${widget.title} (with brand blending)'),
            backgroundColor: ClinicSageColors.tertiary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('AI Image API Error: $e')),
              ],
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'DISMISS',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _uploadSelf() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'mp4'],
        withData: true,
      );
      if (res != null && res.files.isNotEmpty) {
        final f = res.files.first;
        final bytes = f.bytes;
        if (bytes != null && bytes.isNotEmpty) {
          setState(() => _isUploading = true);
          final notifier = ref.read(proposalProvider.notifier);
          final url = await notifier.uploadMediaAsset(
            proposalId: widget.proposalId,
            fileName: f.name,
            bytes: bytes,
          );
          if (mounted) {
            _urlCtrl.text = url;
            widget.onMediaUrlChanged(url);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Uploaded ${f.name} successfully!'),
                backgroundColor: ClinicSageColors.tertiary,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildImagePreview(String rawUrl) {
    final trimmed = rawUrl.trim();
    Widget imageWidget;

    if (trimmed.startsWith('data:image')) {
      final commaIdx = trimmed.indexOf(',');
      if (commaIdx != -1) {
        try {
          final bytes = base64Decode(trimmed.substring(commaIdx + 1));
          imageWidget = Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _errorPlaceholder('Base64 image decode error'),
          );
        } catch (_) {
          imageWidget = _errorPlaceholder('Invalid base64 image encoding');
        }
      } else {
        imageWidget = _errorPlaceholder('Malformed data URI');
      }
    } else {
      imageWidget = Image.network(
        trimmed,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _errorPlaceholder('Asset failed to load from: $trimmed'),
      );
    }

    final hasLogo = widget.logoUrl != null && widget.logoUrl!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 220,
        width: double.infinity,
        color: const Color(0xFF0F172A),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageWidget,
            if (hasLogo)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Container(
                          width: 18,
                          height: 18,
                          color: Colors.white,
                          child: widget.logoUrl!.startsWith('data:image')
                              ? Image.memory(
                                  base64Decode(widget.logoUrl!.substring(widget.logoUrl!.indexOf(',') + 1)),
                                  fit: BoxFit.contain,
                                )
                              : Image.network(widget.logoUrl!, fit: BoxFit.contain),
                        ),
                      ),
                      if (widget.companyName != null && widget.companyName!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          widget.companyName!,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _errorPlaceholder(String text) {
    return Container(
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image_outlined, size: 20, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Click "Generate with AI" above to synthesize a fresh high-resolution visual, or upload one directly.',
                  style: TextStyle(fontSize: 10, color: Color(0xFF7F1D1D)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = _urlCtrl.text.isNotEmpty;
    final hasLogo = widget.logoUrl != null && widget.logoUrl!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClinicSageColors.neutral,
        borderRadius: BorderRadius.circular(ClinicSageRadius.md),
        border: Border.all(color: ClinicSageColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ClinicSageColors.primary),
              ),
              const Spacer(),
              if (_isGenerating || _isUploading)
                Row(
                  children: [
                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 8),
                    Text(_isGenerating ? 'AI Generating...' : 'Uploading...', style: const TextStyle(fontSize: 11, color: ClinicSageColors.secondary)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Action Buttons: AI vs Upload
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: const Color(0xFFA3E635),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: (_isGenerating || _isUploading) ? null : _generateAi,
                icon: const Icon(Icons.auto_awesome, size: 14),
                label: const Text('Generate with AI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ClinicSageColors.primary,
                  side: const BorderSide(color: ClinicSageColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: (_isGenerating || _isUploading) ? null : _uploadSelf,
                icon: const Icon(Icons.upload_file, size: 14),
                label: const Text('Upload by Self', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              if (hasLogo)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 13, color: Color(0xFF10B981)),
                      const SizedBox(width: 5),
                      const Text(
                        'Logo Blending Active',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // AI Image Synthesis Prompt (Editable before generating)
          TextFormField(
            controller: _promptCtrl,
            maxLines: 2,
            style: const TextStyle(fontSize: 11.5),
            decoration: InputDecoration(
              isDense: true,
              labelText: 'AI Image Synthesis Prompt (Customizable)',
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
              hintText: 'Describe visual details to synthesize...',
              prefixIcon: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF10B981)),
              filled: true,
              fillColor: const Color(0xFFF0FDF4),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFA7F3D0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5)),
            ),
          ),
          const SizedBox(height: 10),
          // Direct URL Field
          TextFormField(
            controller: _urlCtrl,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Media / Asset URL',
              labelStyle: const TextStyle(fontSize: 11),
              hintText: 'https://...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onChanged: widget.onMediaUrlChanged,
          ),
          if (hasUrl) ...[
            const SizedBox(height: 12),
            _buildImagePreview(_urlCtrl.text),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Company Brand Logo Card for Visual Blending & PDF Branding
// ─────────────────────────────────────────────────────────────────────────────
class _CompanyLogoCard extends StatelessWidget {
  final String? logoUrl;
  final String companyName;
  final ValueChanged<String?> onLogoChanged;

  const _CompanyLogoCard({
    required this.logoUrl,
    required this.companyName,
    required this.onLogoChanged,
  });

  Future<void> _pickNewLogo(BuildContext context) async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'svg'],
        withData: true,
      );
      if (res != null && res.files.isNotEmpty) {
        final f = res.files.first;
        final bytes = f.bytes;
        if (bytes != null && bytes.isNotEmpty) {
          final mime = f.name.endsWith('.png')
              ? 'image/png'
              : (f.name.endsWith('.webp')
                  ? 'image/webp'
                  : (f.name.endsWith('.svg') ? 'image/svg+xml' : 'image/jpeg'));
          final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
          onLogoChanged(dataUrl);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ Brand logo updated for $companyName!'),
                backgroundColor: ClinicSageColors.tertiary,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not read logo: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoUrl != null && logoUrl!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasLogo ? const Color(0xFFF0FDF4) : ClinicSageColors.neutral,
        borderRadius: BorderRadius.circular(ClinicSageRadius.md),
        border: Border.all(
          color: hasLogo ? const Color(0xFF86EFAC) : ClinicSageColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: hasLogo ? const Color(0xFF86EFAC) : ClinicSageColors.border),
            ),
            padding: const EdgeInsets.all(4),
            child: hasLogo
                ? (logoUrl!.startsWith('data:image')
                    ? Image.memory(
                        base64Decode(logoUrl!.substring(logoUrl!.indexOf(',') + 1)),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey, size: 20),
                      )
                    : Image.network(
                        logoUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey, size: 20),
                      ))
                : const Icon(Icons.add_photo_alternate_outlined, color: ClinicSageColors.secondary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      hasLogo ? 'Official Brand Logo Active' : 'No Brand Logo Attached',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: hasLogo ? const Color(0xFF166534) : ClinicSageColors.primary,
                      ),
                    ),
                    if (hasLogo) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, size: 14, color: Color(0xFF10B981)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  hasLogo
                      ? 'AI weaves this logo into visual prompts, diffusion references & watermarks your 13-page PDF.'
                      : 'Upload $companyName\'s logo so AI can weave it into image prompts, reference blending, and watermark the exported PDF.',
                  style: TextStyle(fontSize: 11, color: hasLogo ? const Color(0xFF15803D) : ClinicSageColors.secondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => _pickNewLogo(context),
            icon: Icon(hasLogo ? Icons.change_circle_outlined : Icons.upload_outlined, size: 14),
            label: Text(hasLogo ? 'Change Logo' : 'Upload Logo', style: const TextStyle(fontSize: 11)),
            style: OutlinedButton.styleFrom(
              foregroundColor: hasLogo ? const Color(0xFF166534) : ClinicSageColors.primary,
              side: BorderSide(color: hasLogo ? const Color(0xFF166534) : ClinicSageColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          ),
          if (hasLogo) ...[
            const SizedBox(width: 6),
            IconButton(
              onPressed: () => onLogoChanged(null),
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
              tooltip: 'Remove Logo',
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3: Creative Direction, Visual Guidelines & Content Framework
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
        // 1. Visual Direction & Keywords
        _SectionContainer(
          title: '1. Visual Direction & Aesthetic Framework',
          subtitle: 'Core creative direction, visual keywords, and hero media asset (Page 8 of PDF)',
          children: [
            // Company Brand Logo Management
            _CompanyLogoCard(
              logoUrl: proposal.companyLogoUrl,
              companyName: proposal.leadCompanyName,
              onLogoChanged: (newLogoUrl) => onChanged(proposal.copyWith(companyLogoUrl: newLogoUrl)),
            ),
            const SizedBox(height: 14),
            _EditableField(
              label: 'Creative Direction Narrative',
              value: proposal.visualGuidelineNotes,
              maxLines: 3,
              onChanged: (v) => onChanged(proposal.copyWith(visualGuidelineNotes: v)),
            ),
            const SizedBox(height: 14),
            _EditableField(
              label: 'Visual Keywords (comma-separated)',
              value: proposal.visualKeywords.join(', '),
              onChanged: (v) {
                final list = v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                onChanged(proposal.copyWith(visualKeywords: list));
              },
            ),
            const SizedBox(height: 14),
            _MediaPickerCard(
              title: 'Visual Direction Hero Media Asset',
              mediaUrl: proposal.visualDirectionImageUrl,
              promptHint: _buildTunedHeroPrompt(proposal),
              proposalId: proposal.id,
              logoUrl: proposal.companyLogoUrl,
              companyName: proposal.leadCompanyName,
              onMediaUrlChanged: (url) => onChanged(proposal.copyWith(visualDirectionImageUrl: url)),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2. Photography Style & Quote
        _SectionContainer(
          title: '2. Photography Style & Experience Philosophy',
          subtitle: 'What to capture vs what to avoid in imagery (Page 8 of PDF)',
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _EditableField(
                    label: 'Focus More On (comma-separated)',
                    value: proposal.focusMoreOn.join(', '),
                    maxLines: 3,
                    onChanged: (v) {
                      final list = v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                      onChanged(proposal.copyWith(focusMoreOn: list));
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _EditableField(
                    label: 'Focus Less On (comma-separated)',
                    value: proposal.focusLessOn.join(', '),
                    maxLines: 3,
                    onChanged: (v) {
                      final list = v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                      onChanged(proposal.copyWith(focusLessOn: list));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _EditableField(
              label: 'Core Photography Philosophy Quote',
              value: proposal.photographyQuote,
              onChanged: (v) => onChanged(proposal.copyWith(photographyQuote: v)),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 3. Design Style, Typography & Brand Voice
        _SectionContainer(
          title: '3. Design Style, Typography & Brand Voice',
          subtitle: 'Headline tone, brand personality traits, and color palette (Page 8 of PDF)',
          children: [
            _EditableField(
              label: 'Typography Headline Sample',
              value: proposal.typographySampleHeadline,
              onChanged: (v) => onChanged(proposal.copyWith(typographySampleHeadline: v)),
            ),
            const SizedBox(height: 16),
            const Text('Brand Personality Traits:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            ...proposal.brandToneOfVoice.asMap().entries.map((entry) {
              final idx = entry.key;
              final t = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: TextFormField(
                        initialValue: t['trait'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        decoration: const InputDecoration(labelText: 'Trait', isDense: true),
                        onChanged: (val) {
                          final updated = List<Map<String, String>>.from(proposal.brandToneOfVoice);
                          updated[idx] = {...t, 'trait': val};
                          onChanged(proposal.copyWith(brandToneOfVoice: updated));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: t['desc'] ?? '',
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(labelText: 'Description', isDense: true),
                        onChanged: (val) {
                          final updated = List<Map<String, String>>.from(proposal.brandToneOfVoice);
                          updated[idx] = {...t, 'desc': val};
                          onChanged(proposal.copyWith(brandToneOfVoice: updated));
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 20),

        // 4. Example Monthly Content Framework (4 Weeks Table)
        _SectionContainer(
          title: '4. Example Monthly Content Framework (4 Weeks)',
          subtitle: 'Interactive multi-channel publishing calendar (Page 8 of PDF)',
          children: [
            ...proposal.contentFrameworkWeeks.asMap().entries.map((entry) {
              final wIdx = entry.key;
              final w = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ClinicSageColors.neutral,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ClinicSageColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w['week'] as String? ?? 'WEEK ${wIdx + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: w['experienceStories'] as String? ?? '',
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(labelText: 'Experience Stories', isDense: true),
                            onChanged: (v) {
                              final list = List<Map<String, dynamic>>.from(proposal.contentFrameworkWeeks);
                              list[wIdx] = {...w, 'experienceStories': v};
                              onChanged(proposal.copyWith(contentFrameworkWeeks: list));
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: w['educational'] as String? ?? '',
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(labelText: 'Educational Content', isDense: true),
                            onChanged: (v) {
                              final list = List<Map<String, dynamic>>.from(proposal.contentFrameworkWeeks);
                              list[wIdx] = {...w, 'educational': v};
                              onChanged(proposal.copyWith(contentFrameworkWeeks: list));
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: w['corporate'] as String? ?? '',
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(labelText: 'Corporate Experiences', isDense: true),
                            onChanged: (v) {
                              final list = List<Map<String, dynamic>>.from(proposal.contentFrameworkWeeks);
                              list[wIdx] = {...w, 'corporate': v};
                              onChanged(proposal.copyWith(contentFrameworkWeeks: list));
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: w['testimonials'] as String? ?? '',
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(labelText: 'Testimonials', isDense: true),
                            onChanged: (v) {
                              final list = List<Map<String, dynamic>>.from(proposal.contentFrameworkWeeks);
                              list[wIdx] = {...w, 'testimonials': v};
                              onChanged(proposal.copyWith(contentFrameworkWeeks: list));
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: w['promotional'] as String? ?? '',
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(labelText: 'Promotional Content', isDense: true),
                            onChanged: (v) {
                              final list = List<Map<String, dynamic>>.from(proposal.contentFrameworkWeeks);
                              list[wIdx] = {...w, 'promotional': v};
                              onChanged(proposal.copyWith(contentFrameworkWeeks: list));
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: w['contentExamples'] as String? ?? '',
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(labelText: 'Content Examples (Deliverables)', isDense: true),
                            onChanged: (v) {
                              final list = List<Map<String, dynamic>>.from(proposal.contentFrameworkWeeks);
                              list[wIdx] = {...w, 'contentExamples': v};
                              onChanged(proposal.copyWith(contentFrameworkWeeks: list));
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 20),

        // 5. Sample Reel (Page 9 of PDF)
        _SectionContainer(
          title: '5. Sample Reel: Vertical Video Blueprint',
          subtitle: '9:16 vertical video poster, hook, scenes, and playable reel link (Page 9 of PDF)',
          children: [
            _EditableField(
              label: 'Reel Hero Headline Overlay',
              value: proposal.sampleReelHeadline,
              onChanged: (v) => onChanged(proposal.copyWith(sampleReelHeadline: v)),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            _EditableField(
              label: 'View Reel Hyperlink URL (Clickable in PDF)',
              value: proposal.sampleReelLink,
              onChanged: (v) => onChanged(proposal.copyWith(sampleReelLink: v)),
            ),
            const SizedBox(height: 14),
            _MediaPickerCard(
              title: 'Sample Reel Vertical Video / Poster Asset',
              mediaUrl: proposal.sampleReelMediaUrl,
              promptHint: _buildTunedReelPrompt(proposal),
              proposalId: proposal.id,
              logoUrl: proposal.companyLogoUrl,
              companyName: proposal.leadCompanyName,
              onMediaUrlChanged: (url) => onChanged(proposal.copyWith(sampleReelMediaUrl: url)),
            ),
          ],
        ),
      ],
    );
  }

  static String _buildTunedHeroPrompt(ProposalModel proposal) {
    final company = proposal.leadCompanyName;
    final industry = proposal.industry.isNotEmpty ? proposal.industry : 'Commercial Enterprise';
    final notes = proposal.visualGuidelineNotes.isNotEmpty ? proposal.visualGuidelineNotes : 'Modern premium aesthetic';
    final keywords = proposal.visualKeywords.isNotEmpty ? proposal.visualKeywords.take(4).join(', ') : 'commercial, authentic';
    return 'Cinematic flagship advertising visual for $company ($industry). Aesthetic: $notes. Atmosphere: $keywords. Rich dynamic lighting, commercial photography, authentic subject interaction, photorealistic, 8k resolution, no artificial watermark text';
  }

  static String _buildTunedReelPrompt(ProposalModel proposal) {
    final company = proposal.leadCompanyName;
    final industry = proposal.industry.isNotEmpty ? proposal.industry : 'Education & Enrichment';
    final topic = proposal.sampleReelTopic.isNotEmpty ? proposal.sampleReelTopic : 'Interactive Learning Transformation';
    // Extract first visual scene
    String firstScene = '';
    if (proposal.sampleReelVisualScenes.isNotEmpty) {
      final lines = proposal.sampleReelVisualScenes.split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (lines.isNotEmpty) {
        firstScene = lines.first.replaceAll(RegExp(r'^Scene\s*\d+\s*:\s*', caseSensitive: false), '').trim();
      }
    }
    final sceneDesc = firstScene.isNotEmpty ? firstScene : 'engaging real-world interaction with students and educators';
    return '9:16 vertical smartphone commercial video still for $company in $industry. Concept: "$topic". Scene: $sceneDesc. Authentic real subject interaction, modern vibrant natural lighting, shallow depth of field, award-winning cinematography, photorealistic, 8k resolution, no text overlays, no artifacts';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4: Copywriting, Social Media & SEO Audit
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
        // 1. 3 Multi-Angle Social Media Post Concepts (Page 10 of PDF)
        _SectionContainer(
          title: '1. Sample Social Media Copywriting & Graphic Mockups',
          subtitle: '3 high-converting post angles tailored to ${proposal.leadCompanyName} and ${proposal.industry} (Page 10 of PDF)',
          children: [
            if (!proposal.industry.toLowerCase().contains('yacht') &&
                proposal.socialPosts.any((p) => p.values.any((v) => v.toString().toLowerCase().contains('ballroom') || v.toString().toLowerCase().contains('charter') || v.toString().toLowerCase().contains('whitesails'))))
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Legacy placeholder post copy detected. Reload domain-tailored posts for ${proposal.leadCompanyName}?',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () {
                        final domainBase = ProposalDomainEngine.instance.synthesizeProposal(
                          proposalId: proposal.id,
                          amId: proposal.amId,
                          leadCompanyName: proposal.leadCompanyName,
                          industry: proposal.industry,
                          websiteUrl: proposal.websiteUrl,
                          socialUrls: proposal.socialUrls,
                          pitchDeckFileName: proposal.pitchDeckFileName,
                          pitchDeckStorageUrl: proposal.pitchDeckStorageUrl,
                          extractedPitchDeckText: proposal.extractedPitchDeckText,
                        );
                        onChanged(proposal.copyWith(socialPosts: domainBase.socialPosts));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Updated 3 social posts for ${proposal.leadCompanyName}!')),
                        );
                      },
                      child: const Text('Reload Posts', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),

            ...proposal.socialPosts.asMap().entries.map((entry) {
              final pIdx = entry.key;
              final p = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ClinicSageColors.neutral,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ClinicSageColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['title'] as String? ?? 'POST ${pIdx + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: p['headline'] as String? ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Graphic Poster Headline', isDense: true),
                      onChanged: (val) {
                        final list = List<Map<String, dynamic>>.from(proposal.socialPosts);
                        list[pIdx] = {...p, 'headline': val};
                        onChanged(proposal.copyWith(socialPosts: list));
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: p['body'] as String? ?? '',
                      maxLines: 4,
                      style: const TextStyle(fontSize: 12.5),
                      decoration: const InputDecoration(labelText: 'Caption Narrative Body & Offer', isDense: true),
                      onChanged: (val) {
                        final list = List<Map<String, dynamic>>.from(proposal.socialPosts);
                        list[pIdx] = {...p, 'body': val};
                        onChanged(proposal.copyWith(socialPosts: list));
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: p['badge'] as String? ?? '',
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(labelText: 'Proof / Metric Badge (e.g. 10 MARKETS · 130+ VCs)', isDense: true),
                            onChanged: (val) {
                              final list = List<Map<String, dynamic>>.from(proposal.socialPosts);
                              list[pIdx] = {...p, 'badge': val};
                              onChanged(proposal.copyWith(socialPosts: list));
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: ((p['hashtags'] as List?) ?? []).join(' '),
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(labelText: 'Hashtags', isDense: true),
                            onChanged: (val) {
                              final list = List<Map<String, dynamic>>.from(proposal.socialPosts);
                              final tags = val.split(' ').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                              list[pIdx] = {...p, 'hashtags': tags};
                              onChanged(proposal.copyWith(socialPosts: list));
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _MediaPickerCard(
                      title: 'Social Media Visual (${p['title'] ?? 'Post ${pIdx + 1}'})',
                      mediaUrl: p['imageUrl'] as String?,
                      promptHint: _buildTunedSocialPrompt(proposal, p),
                      proposalId: proposal.id,
                      logoUrl: proposal.companyLogoUrl,
                      companyName: proposal.leadCompanyName,
                      onMediaUrlChanged: (url) {
                        final list = List<Map<String, dynamic>>.from(proposal.socialPosts);
                        list[pIdx] = {...p, 'imageUrl': url};
                        onChanged(proposal.copyWith(socialPosts: list));
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 20),

        // 2. Sample Blog Article (Page 11 of PDF)
        _SectionContainer(
          title: '2. Sample Copywriting: SEO Pillar Blog Article',
          subtitle: 'Long-form authority article and organic search capture (Page 11 of PDF)',
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

        // 3. SEO & Digital Presence Opportunities (Page 12 of PDF)
        _SectionContainer(
          title: '3. SEO & Digital Presence Opportunities',
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
                  child: TextFormField(
                    initialValue: proposal.seoAudit.healthScore.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Score (0 - 100)', isDense: true),
                    onChanged: (v) {
                      final score = int.tryParse(v) ?? proposal.seoAudit.healthScore;
                      onChanged(proposal.copyWith(seoAudit: proposal.seoAudit.copyWith(healthScore: score)));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _EditableField(
              label: 'SEO Audit Summary Text',
              value: proposal.seoAudit.summaryText,
              maxLines: 3,
              onChanged: (v) => onChanged(proposal.copyWith(seoAudit: proposal.seoAudit.copyWith(summaryText: v))),
            ),
            const SizedBox(height: 12),
            _EditableField(
              label: 'High Priority Initiatives (comma-separated)',
              value: proposal.seoAudit.highPriority.join(', '),
              onChanged: (v) {
                final list = v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                onChanged(proposal.copyWith(seoAudit: proposal.seoAudit.copyWith(highPriority: list)));
              },
            ),
            const SizedBox(height: 12),
            _EditableField(
              label: 'Medium Priority Enhancements (comma-separated)',
              value: proposal.seoAudit.mediumPriority.join(', '),
              onChanged: (v) {
                final list = v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                onChanged(proposal.copyWith(seoAudit: proposal.seoAudit.copyWith(mediumPriority: list)));
              },
            ),
            const SizedBox(height: 12),
            _EditableField(
              label: 'Long-Term Opportunities (comma-separated)',
              value: proposal.seoAudit.longTermOpportunities.join(', '),
              onChanged: (v) {
                final list = v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                onChanged(proposal.copyWith(seoAudit: proposal.seoAudit.copyWith(longTermOpportunities: list)));
              },
            ),
            const SizedBox(height: 12),
            _EditableField(
              label: 'View Full SEO/AIO Audit Hyperlink URL (Clickable in PDF)',
              value: proposal.seoAuditLink,
              onChanged: (v) => onChanged(proposal.copyWith(seoAuditLink: v)),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 4. Our Assessment On SEO Audit & Final Thoughts (Page 13 of PDF)
        _SectionContainer(
          title: '4. Our Assessment On SEO Audit & Final Thoughts',
          subtitle: 'Executive recommendation and solid lime-green summary card (Page 13 of PDF)',
          children: [
            _EditableField(
              label: 'Our Assessment On SEO Audit Narrative',
              value: proposal.seoAssessmentText,
              maxLines: 3,
              onChanged: (v) => onChanged(proposal.copyWith(seoAssessmentText: v)),
            ),
            const SizedBox(height: 16),
            // Live Preview of Solid Lime-Green Final Thoughts Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFA3E635),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Final Thoughts (Live Preview of Page 13 Card)',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0A0D0D)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: proposal.finalThoughtsSummary,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0A0D0D), height: 1.4),
                    decoration: const InputDecoration(
                      labelText: 'Final Thoughts Summary Paragraph',
                      labelStyle: TextStyle(color: Color(0xFF0A0D0D), fontWeight: FontWeight.w700),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (v) => onChanged(proposal.copyWith(finalThoughtsSummary: v)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: proposal.finalThoughtsRecommendation,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0A0D0D), height: 1.4),
                    decoration: const InputDecoration(
                      labelText: 'Final Thoughts Strategic Recommendation',
                      labelStyle: TextStyle(color: Color(0xFF0A0D0D), fontWeight: FontWeight.w700),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (v) => onChanged(proposal.copyWith(finalThoughtsRecommendation: v)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _buildTunedSocialPrompt(ProposalModel proposal, Map<String, dynamic> post) {
    final company = proposal.leadCompanyName;
    final industry = proposal.industry.isNotEmpty ? proposal.industry : 'Commercial Enterprise';
    final headline = (post['headline'] as String? ?? '').replaceAll(RegExp(r'["“”]'), '').trim();
    final title = post['title'] as String? ?? 'High-Value Campaign';
    return '1:1 square high-converting social media campaign ad visual for $company ($industry). Campaign Angle: "$title". Core Theme: "$headline". Premium modern commercial photography, studio lighting, authentic human engagement, rich cinematic color grading, photorealistic, 8k resolution, award-winning social visual, no artificial watermark text overlays, no artifacts';
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: ClinicSageColors.surface,
        borderRadius: BorderRadius.circular(ClinicSageRadius.md),
        border: Border.all(color: ClinicSageColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: ClinicSageColors.primary),
          ),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: ClinicSageColors.secondary)),
          const SizedBox(height: 18),
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
      style: const TextStyle(color: ClinicSageColors.primary, fontSize: 13, height: 1.4),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: ClinicSageColors.secondary),
        alignLabelWithHint: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
        ),
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
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: items.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextFormField(
                    initialValue: e.value,
                    style: const TextStyle(fontSize: 12.5, color: ClinicSageColors.primary),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: color, width: 1.5),
                      ),
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF4F46E5), fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextFormField(
                  initialValue: current,
                  style: const TextStyle(fontSize: 12.5, color: ClinicSageColors.primary),
                  decoration: InputDecoration(
                    labelText: 'Current Approach',
                    labelStyle: const TextStyle(color: ClinicSageColors.secondary, fontSize: 12),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                    ),
                  ),
                  onChanged: onCurrentChanged,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: opportunity,
                  style: const TextStyle(fontSize: 12.5, color: ClinicSageColors.primary),
                  decoration: InputDecoration(
                    labelText: 'Strategic Opportunity',
                    labelStyle: const TextStyle(color: ClinicSageColors.secondary, fontSize: 12),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                    ),
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
