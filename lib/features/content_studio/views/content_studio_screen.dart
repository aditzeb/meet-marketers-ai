import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../data/models/content_deliverable_model.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/hive_cache_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/models/client_model.dart';
import '../../dashboard/providers/client_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/workspace_phase_header.dart';
import 'package:video_player/video_player.dart';

/// Context-aware Sub-Tab model per deliverable type
class DeliverableSubTab {
  final String id;
  final String label;
  final IconData icon;

  const DeliverableSubTab({
    required this.id,
    required this.label,
    required this.icon,
  });
}

/// Returns tailored sub-tabs specifically for each of the 11 deliverable types
List<DeliverableSubTab> getSubTabsForType(ContentType type) {
  switch (type) {
    case ContentType.introDeck:
    case ContentType.salesPitchDeck:
      return const [
        DeliverableSubTab(id: 'slides', label: 'Presentation Slides', icon: Icons.slideshow),
        DeliverableSubTab(id: 'script', label: 'Speaker Script & Notes', icon: Icons.speaker_notes),
        DeliverableSubTab(id: 'assets', label: 'Slide Visual Assets', icon: Icons.palette_outlined),
        DeliverableSubTab(id: 'outline', label: 'Slide Agenda & Index', icon: Icons.list_alt),
      ];

    case ContentType.explainerVideos:
    case ContentType.testimonialVideos:
      return const [
        DeliverableSubTab(id: 'video_script', label: 'Video Script & Voiceover', icon: Icons.record_voice_over),
        DeliverableSubTab(id: 'storyboard', label: 'Scene Storyboard', icon: Icons.movie_creation_outlined),
        DeliverableSubTab(id: 'stream', label: 'Video Asset Stream', icon: Icons.play_circle_outline),
        DeliverableSubTab(id: 'subtitles', label: 'Captions & Subtitles', icon: Icons.subtitles),
      ];

    case ContentType.socialMediaPosts:
      return const [
        DeliverableSubTab(id: 'post_copy', label: 'Post Copy & Hooks', icon: Icons.article_outlined),
        DeliverableSubTab(id: 'graphics', label: 'Graphic Assets & Visuals', icon: Icons.photo_camera_back),
        DeliverableSubTab(id: 'captions', label: 'Social Captions & Hashtags', icon: Icons.tag),
        DeliverableSubTab(id: 'variants', label: 'Platform Variants', icon: Icons.share_outlined),
      ];

    case ContentType.blogArticles:
      return const [
        DeliverableSubTab(id: 'article_copy', label: 'Full Article Copy', icon: Icons.notes),
        DeliverableSubTab(id: 'cover', label: 'Cover Graphic', icon: Icons.image_outlined),
        DeliverableSubTab(id: 'outline', label: 'Article Outline & TOC', icon: Icons.format_list_bulleted),
        DeliverableSubTab(id: 'seo_meta', label: 'SEO Meta & URL Slug', icon: Icons.search),
      ];

    case ContentType.emailCampaign:
      return const [
        DeliverableSubTab(id: 'email_body', label: 'Email Body Copy', icon: Icons.mark_email_read_outlined),
        DeliverableSubTab(id: 'subject_lines', label: 'Subject Lines & Preheaders', icon: Icons.title),
        DeliverableSubTab(id: 'email_banner', label: 'Email Visual Banner', icon: Icons.wallpaper),
        DeliverableSubTab(id: 'drip_flow', label: 'Automation Sequence', icon: Icons.alt_route),
      ];

    case ContentType.seoKeywordAudit:
      return const [
        DeliverableSubTab(id: 'keyword_matrix', label: 'Target Keyword Matrix', icon: Icons.table_chart_outlined),
        DeliverableSubTab(id: 'intent_funnel', label: 'Search Intent & Funnel', icon: Icons.filter_list),
        DeliverableSubTab(id: 'competitor_gaps', label: 'Competitor Keyword Gaps', icon: Icons.compare_arrows),
        DeliverableSubTab(id: 'action_plan', label: 'Action Plan', icon: Icons.checklist),
      ];

    case ContentType.seoTechnicalAudit:
      return const [
        DeliverableSubTab(id: 'tech_report', label: 'Technical Audit Report', icon: Icons.analytics_outlined),
        DeliverableSubTab(id: 'remediation', label: 'Fix & Remediation Plan', icon: Icons.build_circle_outlined),
        DeliverableSubTab(id: 'checklist', label: 'On-Page SEO Checklist', icon: Icons.fact_check_outlined),
        DeliverableSubTab(id: 'vitals', label: 'Core Web Vitals', icon: Icons.speed_outlined),
      ];

    case ContentType.otherDesigns:
      return const [
        DeliverableSubTab(id: 'design_brief', label: 'Creative Design Brief', icon: Icons.brush_outlined),
        DeliverableSubTab(id: 'graphic_asset', label: 'Generated Graphic Asset', icon: Icons.palette_outlined),
        DeliverableSubTab(id: 'color_specs', label: 'Color & Typography Spec', icon: Icons.color_lens_outlined),
        DeliverableSubTab(id: 'layouts', label: 'Layout Variations', icon: Icons.grid_view),
      ];

    case ContentType.otherCopies:
      return const [
        DeliverableSubTab(id: 'ad_copy', label: 'Ad Copy & Headlines', icon: Icons.campaign_outlined),
        DeliverableSubTab(id: 'value_hooks', label: 'Value Proposition Hooks', icon: Icons.anchor),
        DeliverableSubTab(id: 'hero_copy', label: 'Landing Page Hero Copy', icon: Icons.web),
        DeliverableSubTab(id: 'cta_library', label: 'CTA Library', icon: Icons.touch_app_outlined),
      ];
  }
}

String getGenerateButtonText(ContentType type, bool hasGenerated) {
  if (hasGenerated) {
    return 'Regenerate ${type.label}';
  }
  switch (type) {
    case ContentType.introDeck:
    case ContentType.salesPitchDeck:
      return 'Generate Presentation Deck & Slides';
    case ContentType.explainerVideos:
    case ContentType.testimonialVideos:
      return 'Generate Video Storyboard & Script';
    case ContentType.socialMediaPosts:
      return 'Generate Social Posts & Graphics';
    case ContentType.blogArticles:
      return 'Generate Full Blog Article & Header';
    case ContentType.emailCampaign:
      return 'Generate Email Campaign & Sequences';
    case ContentType.seoKeywordAudit:
      return 'Generate SEO Keyword Audit Matrix';
    case ContentType.seoTechnicalAudit:
      return 'Generate Technical SEO Audit & Plan';
    case ContentType.otherDesigns:
      return 'Generate Creative Design Brief & Assets';
    case ContentType.otherCopies:
      return 'Generate Sales Copy & Ad Headlines';
  }
}

String getEmptyStateText(ContentType type) {
  switch (type) {
    case ContentType.introDeck:
    case ContentType.salesPitchDeck:
      return 'Click "Generate" to generate slide deck structure, visual slide cards, presenter notes, and speaker scripts using Gemini AI.';
    case ContentType.explainerVideos:
    case ContentType.testimonialVideos:
      return 'Click "Generate" to create scene-by-scene video storyboards, timed voiceover scripts, shot directions, and video previews.';
    case ContentType.socialMediaPosts:
      return 'Click "Generate" to create social post copies, visual graphic assets, captions, and hashtag bundles.';
    case ContentType.blogArticles:
      return 'Click "Generate" to produce long-form SEO blog posts, article outlines, header graphics, and meta tags.';
    case ContentType.emailCampaign:
      return 'Click "Generate" to build automated email copies, subject line benchmarks, header graphics, and drip flows.';
    case ContentType.seoKeywordAudit:
      return 'Click "Generate" to perform comprehensive SEO keyword research, search intent mapping, and competitor gap analysis.';
    case ContentType.seoTechnicalAudit:
      return 'Click "Generate" to audit site technical health, crawlability, Core Web Vitals, and developer fix plans.';
    case ContentType.otherDesigns:
      return 'Click "Generate" to create creative design briefs, visual graphic renders, color palettes, and layout specs.';
    case ContentType.otherCopies:
      return 'Click "Generate" to craft high-converting ad copy, landing page hero text, value hooks, and CTA libraries.';
  }
}

/// Phase 3A: Content Production — Split-Screen Editor + Real Photo, Video & Deck Generator
class ContentStudioScreen extends ConsumerStatefulWidget {
  final String clientId;
  const ContentStudioScreen({super.key, required this.clientId});

  @override
  ConsumerState<ContentStudioScreen> createState() => _ContentStudioScreenState();
}

class _ContentStudioScreenState extends ConsumerState<ContentStudioScreen> {
  ContentType _selectedType = ContentType.socialMediaPosts;
  late String _selectedSubTabId;

  bool _isGenerating = false;
  bool _isGeneratingAll = false;

  final Map<ContentType, TextEditingController> _vettedControllers = {
    for (final t in ContentType.values) t: TextEditingController(),
  };
  final Map<ContentType, VettingStatus> _statuses = {
    for (final t in ContentType.values) t: VettingStatus.draft,
  };
  final Map<ContentType, bool> _hasGenerated = {
    for (final t in ContentType.values) t: false,
  };
  final Map<ContentType, String> _aiTexts = {
    for (final t in ContentType.values) t: '',
  };
  final Map<ContentType, GeneratedMediaAsset?> _mediaAssets = {
    for (final t in ContentType.values) t: null,
  };

  @override
  void initState() {
    super.initState();
    _selectedSubTabId = getSubTabsForType(_selectedType).first.id;
    _restoreDrafts();
  }

  void _restoreDrafts() {
    for (final t in ContentType.values) {
      final key = 'draft_${widget.clientId}_${t.value}';
      final cached = HiveCacheService.instance.getDraftBuffer(key);
      if (cached != null && cached.isNotEmpty) {
        _vettedControllers[t]!.text = cached;
        _hasGenerated[t] = true;
        _statuses[t] = VettingStatus.inReview;
      }
    }
  }

  void _onTypeSelected(ContentType type) {
    setState(() {
      _selectedType = type;
      _selectedSubTabId = getSubTabsForType(type).first.id;
    });
  }

  void _onTextChanged(ContentType type, String value) {
    final key = 'draft_${widget.clientId}_${type.value}';
    HiveCacheService.instance.saveDraftBuffer(key, value);
    HiveCacheService.instance.saveVettedDeliverable(widget.clientId, type.value, value);

    final am = ref.read(authProvider).user;
    final amId = am?.id ?? 'am-default';

    FirebaseService.instance.saveDeliverable(
      amId,
      widget.clientId,
      type.value,
      {
        'vettedOutputText': value,
        'status': _statuses[type]!.value,
      },
    );
  }

  @override
  void dispose() {
    for (final c in _vettedControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientProvider);
    final client = clientState.getClient(widget.clientId);
    final subTabs = getSubTabsForType(_selectedType);

    return Scaffold(
      backgroundColor: ClinicSageColors.neutral,
      body: Column(
        children: [
          // ── Unified Workspace Navigation Header ──────────
          WorkspacePhaseHeader(client: client, activePhaseIndex: 3),

          // ── Top Bar ──────────────────────────────────────
          _StudioTopBar(
            client: client,
            selectedType: _selectedType,
            isGeneratingAll: _isGeneratingAll,
            onGenerateAll: () => _onGenerateAll(client),
          ),
          // ── Type Tabs & Contextual Sub-Media Selector ────
          _ContentTypeTabs(
            selectedType: _selectedType,
            statuses: _statuses,
            onTypeSelected: _onTypeSelected,
          ),
          _SubMediaSelectorBar(
            subTabs: subTabs,
            selectedTabId: _selectedSubTabId,
            onTabSelected: (id) => setState(() => _selectedSubTabId = id),
          ),

          // ── Split Pane ────────────────────────────────────
          Expanded(
            child: Row(
              children: [
                // Left: Context-Aware AI Generated Output Panel
                Expanded(
                  child: _AIOutputPanel(
                    type: _selectedType,
                    subTabId: _selectedSubTabId,
                    clientName: client.name,
                    aiText: _aiTexts[_selectedType] ?? '',
                    mediaAsset: _mediaAssets[_selectedType],
                    hasGenerated: _hasGenerated[_selectedType] ?? false,
                    isGenerating: _isGenerating,
                    onGenerate: () => _onGenerate(client),
                  ),
                ),
                // Divider
                Container(width: 1, color: ClinicSageColors.border),
                // Right: AM Editor Panel
                Expanded(
                  child: _AMEditorPanel(
                    type: _selectedType,
                    controller: _vettedControllers[_selectedType]!,
                    status: _statuses[_selectedType]!,
                    hasGenerated: _hasGenerated[_selectedType] ?? false,
                    mediaAsset: _mediaAssets[_selectedType],
                    onTextChanged: (val) => _onTextChanged(_selectedType, val),
                    onStatusAdvance: _onStatusAdvance,
                    onCopyToClipboard: _onCopyToClipboard,
                    onSyncFromAI: _onSyncFromAI,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onGenerate(ClientModel client) async {
    setState(() => _isGenerating = true);

    final text = await GeminiService.instance.generateContent(
      type: _selectedType,
      clientName: client.name,
      industry: client.industry,
      clientId: client.id,
      websiteUrl: client.websiteUrl,
      questionnaire: client.questionnaireAnswers,
      referenceImages: client.imageStoragePaths,
      referenceDocuments: client.documentStoragePaths,
    );

    final media = await GeminiService.instance.generateMediaAsset(
      type: _selectedType,
      clientName: client.name,
      industry: client.industry,
    );

    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _hasGenerated[_selectedType] = true;
      _aiTexts[_selectedType] = text;
      _mediaAssets[_selectedType] = media;
    });
  }

  Future<void> _onGenerateAll(ClientModel client) async {
    setState(() => _isGeneratingAll = true);
    for (final t in ContentType.values) {
      final text = await GeminiService.instance.generateContent(
        type: t,
        clientName: client.name,
        industry: client.industry,
        clientId: client.id,
        websiteUrl: client.websiteUrl,
        questionnaire: client.questionnaireAnswers,
        referenceImages: client.imageStoragePaths,
        referenceDocuments: client.documentStoragePaths,
      );
      final media = await GeminiService.instance.generateMediaAsset(
        type: t,
        clientName: client.name,
        industry: client.industry,
      );
      if (!mounted) return;
      setState(() {
        _hasGenerated[t] = true;
        _aiTexts[t] = text;
        _mediaAssets[t] = media;
      });
    }
    if (mounted) {
      setState(() => _isGeneratingAll = false);
    }
  }

  void _onStatusAdvance() {
    setState(() {
      _statuses[_selectedType] = _statuses[_selectedType]!.nextStatus;
    });
  }

  void _onCopyToClipboard() {
    final text = _vettedControllers[_selectedType]!.text;
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied text to clipboard')),
    );
  }

  void _onSyncFromAI() {
    final ai = _aiTexts[_selectedType] ?? '';
    final media = _mediaAssets[_selectedType];
    final fullSync = media != null
        ? '$ai\n\n--- AI CAPTION ---\n${media.caption}\n\n${media.hashtags}'
        : ai;

    _vettedControllers[_selectedType]!.text = fullSync;
    _onTextChanged(_selectedType, fullSync);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub Media Selector Bar (Context-Aware Sub-Tabs)
// ─────────────────────────────────────────────────────────────────────────────
class _SubMediaSelectorBar extends StatelessWidget {
  final List<DeliverableSubTab> subTabs;
  final String selectedTabId;
  final ValueChanged<String> onTabSelected;

  const _SubMediaSelectorBar({
    required this.subTabs,
    required this.selectedTabId,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: ClinicSageColors.neutral,
        border: Border(bottom: BorderSide(color: ClinicSageColors.border)),
      ),
      child: Row(
        children: subTabs.map((tab) {
          final isSelected = tab.id == selectedTabId;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () => onTabSelected(tab.id),
              borderRadius: BorderRadius.circular(6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? ClinicSageColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? ClinicSageColors.tertiary : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 14,
                      color: isSelected ? ClinicSageColors.tertiary : ClinicSageColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected ? ClinicSageColors.tertiary : ClinicSageColors.secondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Studio Top Bar
// ─────────────────────────────────────────────────────────────────────────────
class _StudioTopBar extends StatelessWidget {
  final ClientModel client;
  final ContentType selectedType;
  final bool isGeneratingAll;
  final VoidCallback onGenerateAll;

  const _StudioTopBar({
    required this.client,
    required this.selectedType,
    required this.isGeneratingAll,
    required this.onGenerateAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: ClinicSageSpacing.lg),
      decoration: const BoxDecoration(
        color: ClinicSageColors.surface,
        border: Border(bottom: BorderSide(color: ClinicSageColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: ClinicSageGradients.aiGlow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.video_library_outlined, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(client.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              Text('Content Studio · Phase 3 of 4', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
            ],
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: ClinicSageGradients.tertiarySubtle,
              borderRadius: BorderRadius.circular(ClinicSageRadius.full),
              border: Border.all(color: ClinicSageColors.border),
            ),
            child: Text(
              selectedType.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: ClinicSageColors.tertiary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          const Spacer(),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(ClinicSageRadius.md),
            child: InkWell(
              onTap: isGeneratingAll ? null : onGenerateAll,
              borderRadius: BorderRadius.circular(ClinicSageRadius.md),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: isGeneratingAll
                      ? LinearGradient(colors: [ClinicSageColors.tertiary.withValues(alpha: 0.4), ClinicSageColors.tertiary.withValues(alpha: 0.4)])
                      : ClinicSageGradients.aiGlow,
                  borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                  boxShadow: isGeneratingAll
                      ? []
                      : [BoxShadow(color: ClinicSageColors.tertiary.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isGeneratingAll
                        ? const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                    const SizedBox(width: 7),
                    Text(
                      isGeneratingAll ? 'Generating Media...' : 'Generate All Content',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => GoRouter.of(context).go(AppRoutes.clientReviewPath(client.id)),
            icon: const Icon(Icons.verified_outlined, size: 14),
            label: const Text('Go to Review'),
          ),
        ],
      ),
    );
  }
}

class _ContentTypeTabs extends StatelessWidget {
  final ContentType selectedType;
  final Map<ContentType, VettingStatus> statuses;
  final ValueChanged<ContentType> onTypeSelected;

  const _ContentTypeTabs({required this.selectedType, required this.statuses, required this.onTypeSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: ClinicSageColors.surface,
        border: Border(bottom: BorderSide(color: ClinicSageColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: ContentType.values.map((t) {
            final isSelected = t == selectedType;
            return GestureDetector(
              onTap: () => onTypeSelected(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? ClinicSageColors.tertiaryLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? ClinicSageColors.tertiary : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected ? ClinicSageColors.tertiary : ClinicSageColors.secondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (statuses[t] != VettingStatus.draft) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: ClinicSageColors.tertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Output Panel (Context-Aware Rendering Engine)
// ─────────────────────────────────────────────────────────────────────────────
class _AIOutputPanel extends StatelessWidget {
  final ContentType type;
  final String subTabId;
  final String clientName;
  final String aiText;
  final GeneratedMediaAsset? mediaAsset;
  final bool hasGenerated;
  final bool isGenerating;
  final VoidCallback onGenerate;

  const _AIOutputPanel({
    required this.type,
    required this.subTabId,
    required this.clientName,
    required this.aiText,
    required this.mediaAsset,
    required this.hasGenerated,
    required this.isGenerating,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: ClinicSageColors.surfaceVariant,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
              color: ClinicSageColors.surface,
              border: Border(bottom: BorderSide(color: ClinicSageColors.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 14, color: ClinicSageColors.secondary),
                const SizedBox(width: 8),
                Text('AI Output — ${type.label}', style: theme.textTheme.labelMedium),
                const Spacer(),
                if (hasGenerated)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ClinicSageColors.tertiaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Generated', style: theme.textTheme.labelSmall?.copyWith(color: ClinicSageColors.tertiary)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: isGenerating
                ? _GeneratingAnimation(type: type)
                : !hasGenerated
                    ? _EmptyGenerateState(type: type, onGenerate: onGenerate)
                    : _buildSubTabContent(context),
          ),
          if (!isGenerating)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: ClinicSageColors.surface,
                border: Border(top: BorderSide(color: ClinicSageColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onGenerate,
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: Text(getGenerateButtonText(type, hasGenerated)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubTabContent(BuildContext context) {
    // 1. Presentation Decks (Intro Deck & Sales Pitch Deck)
    if (type == ContentType.introDeck || type == ContentType.salesPitchDeck) {
      if (subTabId == 'slides') {
        return _PresentationSlidesView(clientName: clientName, aiText: aiText);
      }
    }

    // 2. Video Storyboards & Stream
    if (type == ContentType.explainerVideos || type == ContentType.testimonialVideos) {
      if (subTabId == 'storyboard' || subTabId == 'stream') {
        return _VideoStoryboardView(mediaAsset: mediaAsset);
      }
    }

    // 3. Graphic & Visual Asset sub-tabs
    if (subTabId == 'graphics' || subTabId == 'cover' || subTabId == 'assets' || subTabId == 'graphic_asset' || subTabId == 'email_banner') {
      return _PhotoAssetView(mediaAsset: mediaAsset);
    }

    // 4. Captions & Hashtags sub-tab
    if (subTabId == 'captions' || subTabId == 'subtitles' || subTabId == 'subject_lines') {
      return _SocialCaptionsView(mediaAsset: mediaAsset);
    }

    // 5. Default formatted text view for copy/script/outline
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _FormattedTextView(text: aiText),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Presentation Slides View (Tailored Slide Cards for Decks)
// ─────────────────────────────────────────────────────────────────────────────
class _PresentationSlidesView extends StatelessWidget {
  final String clientName;
  final String aiText;

  const _PresentationSlidesView({
    required this.clientName,
    required this.aiText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final slides = [
      (
        num: '01',
        title: '$clientName — Executive Presentation',
        subtitle: 'Title Slide & Strategic Vision',
        bullets: ['Market Positioning Overview', 'Value Proposition Highlights', 'Prepared for Strategic Stakeholders'],
        note: 'Welcome audience, introduce brand mission and value proposition.',
      ),
      (
        num: '02',
        title: 'Market Opportunity & Problem',
        subtitle: 'Friction Points & Industry Gaps',
        bullets: ['Current market inefficiencies', 'Customer pain points and cost barriers', 'Unmet demand in target industry'],
        note: 'Emphasize the urgent friction point that $clientName addresses.',
      ),
      (
        num: '03',
        title: 'The Solution — AI-Powered Platform',
        subtitle: 'Core Product Differentiator',
        bullets: ['Seamless automated orchestration', 'Data-driven intelligence engine', 'End-to-end efficiency gains'],
        note: 'Highlight key features and how it transforms client workflow.',
      ),
      (
        num: '04',
        title: 'Target Personas & Customer Impact',
        subtitle: 'Demographics & Buying Triggers',
        bullets: ['HR Directors, Finance Executives & Growth Leads', 'High ROI focus and rapid deployment', 'Key acquisition channels'],
        note: 'Detail target customer profile and buying criteria.',
      ),
      (
        num: '05',
        title: 'Business Model & Growth Drivers',
        subtitle: 'Monetization & Scalability',
        bullets: ['Recurring software subscriptions', 'Enterprise custom licensing', 'High customer lifetime value (LTV)'],
        note: 'Walk through revenue streams and unit economics.',
      ),
      (
        num: '06',
        title: 'Competitive Advantage & Traction',
        subtitle: 'Moat & Market Momentum',
        bullets: ['First-mover advantage in AI workflows', 'Proprietary knowledge flywheel', 'Proven client case studies'],
        note: 'Demonstrate competitive moat and customer validation.',
      ),
      (
        num: '07',
        title: 'Next Steps & Contact Details',
        subtitle: 'Call to Action & Partnership',
        bullets: ['Schedule pilot onboarding', 'Access full platform demo', 'Contact executive team'],
        note: 'Closing ask and clear call to action.',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Interactive Slide Deck Preview', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ClinicSageColors.tertiaryLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('${slides.length} Slides Ready', style: theme.textTheme.labelSmall?.copyWith(color: ClinicSageColors.tertiary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...slides.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ClinicSageColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ClinicSageColors.tertiary.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: ClinicSageColors.tertiaryLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('SLIDE ${s.num}', style: theme.textTheme.labelSmall?.copyWith(color: ClinicSageColors.tertiary, fontWeight: FontWeight.w800, fontSize: 10)),
                    ),
                    Text(s.subtitle, style: theme.textTheme.labelSmall?.copyWith(color: ClinicSageColors.secondary)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(s.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: ClinicSageColors.primary)),
                const SizedBox(height: 10),
                ...s.bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 12, color: ClinicSageColors.tertiary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(b, style: theme.textTheme.bodySmall)),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ClinicSageColors.neutral,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.speaker_notes, size: 13, color: ClinicSageColors.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Speaker Note: ${s.note}',
                          style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Real Photo Asset View
// ─────────────────────────────────────────────────────────────────────────────
class _PhotoAssetView extends StatelessWidget {
  final GeneratedMediaAsset? mediaAsset;
  const _PhotoAssetView({required this.mediaAsset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = mediaAsset?.imageUrl ?? 'https://images.unsplash.com/photo-1551836022-d5d88e9218df?auto=format&fit=crop&w=1200&q=80';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Generated Visual Asset', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ClinicSageColors.tertiaryLight,
                  borderRadius: BorderRadius.circular(ClinicSageRadius.full),
                  border: Border.all(color: ClinicSageColors.tertiary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 12, color: ClinicSageColors.tertiary),
                    const SizedBox(width: 4),
                    Text('Imagen 3 / Imagen 3.0 Model', style: theme.textTheme.labelSmall?.copyWith(color: ClinicSageColors.tertiary, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              width: double.infinity,
              height: 380,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 380,
                  color: ClinicSageColors.surface,
                  child: const Center(
                    child: CircularProgressIndicator(color: ClinicSageColors.tertiary),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                height: 380,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ClinicSageColors.primary, Color(0xFF1E3A2F), Color(0xFF11221C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ClinicSageColors.tertiary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, size: 40, color: ClinicSageColors.tertiary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Imagen 3 AI Commercial Render',
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '8K Ultra HD · Studio Lighting · Modern Executive Aesthetic',
                      style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ClinicSageColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ClinicSageColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: ClinicSageColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mediaAsset?.prompt ?? 'Prompt: Hyper-realistic Imagen 3 commercial photography, cinematic lighting, 8k resolution.',
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 11, color: ClinicSageColors.secondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StoryboardScene {
  final int sceneNumber;
  final String timecode;
  final String cameraAngle;
  final String visualDescription;
  final String voiceoverScript;

  const StoryboardScene({
    required this.sceneNumber,
    required this.timecode,
    required this.cameraAngle,
    required this.visualDescription,
    required this.voiceoverScript,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Real Video Storyboard View
// ─────────────────────────────────────────────────────────────────────────────
class _VideoStoryboardView extends StatelessWidget {
  final GeneratedMediaAsset? mediaAsset;
  const _VideoStoryboardView({required this.mediaAsset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scenes = _defaultScenes();
    final videoUrl = mediaAsset?.videoUrl ?? 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Google VEO AI Video Storyboard', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ClinicSageColors.tertiaryLight,
                  borderRadius: BorderRadius.circular(ClinicSageRadius.full),
                  border: Border.all(color: ClinicSageColors.tertiary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.videocam, size: 12, color: ClinicSageColors.tertiary),
                    const SizedBox(width: 4),
                    Text('Google VEO 2.0 / 3.1 Video Engine', style: theme.textTheme.labelSmall?.copyWith(color: ClinicSageColors.tertiary, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _VertexVideoPlayerWidget(videoUrl: videoUrl),
          const SizedBox(height: 16),
          Text('Scene Direction & Storyboard Breakdown', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...scenes.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ClinicSageColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ClinicSageColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: ClinicSageColors.neutral,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('SCENE ${s.sceneNumber} · ${s.timecode}', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 10),
                    Text(s.cameraAngle, style: theme.textTheme.labelSmall?.copyWith(color: ClinicSageColors.secondary)),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Visual:', style: theme.textTheme.labelSmall?.copyWith(color: ClinicSageColors.tertiary)),
                Text(s.visualDescription, style: theme.textTheme.bodySmall?.copyWith(color: ClinicSageColors.primary)),
                const SizedBox(height: 6),
                Text('Voiceover Script:', style: theme.textTheme.labelSmall?.copyWith(color: ClinicSageColors.tertiary)),
                Text('"${s.voiceoverScript}"', style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  List<StoryboardScene> _defaultScenes() {
    return [
      const StoryboardScene(
        sceneNumber: 1,
        timecode: '0:00 - 0:05',
        cameraAngle: 'Wide Cinematic Shot',
        visualDescription: 'High-contrast modern workspace visual highlighting market challenges.',
        voiceoverScript: 'In a fast-moving market, scaling performance requires intelligent execution.',
      ),
      const StoryboardScene(
        sceneNumber: 2,
        timecode: '0:05 - 0:15',
        cameraAngle: 'Macro Close-Up',
        visualDescription: 'AI platform interface in action, generating marketing deliverables seamlessly.',
        voiceoverScript: 'Meet the AI solution built to power marketing growth with human-in-the-loop control.',
      ),
      const StoryboardScene(
        sceneNumber: 3,
        timecode: '0:15 - 0:25',
        cameraAngle: 'Medium Tracking Shot',
        visualDescription: 'Account Managers reviewing and approving vetted deliverables.',
        voiceoverScript: 'From strategy to sign-off, empower your team to deliver exceptional results.',
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vertex Video Player Widget
// ─────────────────────────────────────────────────────────────────────────────
class _VertexVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const _VertexVideoPlayerWidget({required this.videoUrl});

  @override
  State<_VertexVideoPlayerWidget> createState() => _VertexVideoPlayerWidgetState();
}

class _VertexVideoPlayerWidgetState extends State<_VertexVideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller.initialize();
      setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() => _isError = true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isError || !_controller.value.isInitialized) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: ClinicSageColors.tertiary),
              SizedBox(height: 12),
              Text('Initializing AI Video Stream...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    final aspectRatio = _controller.value.aspectRatio > 0 ? _controller.value.aspectRatio : (16 / 9);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 320,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  color: Colors.black.withValues(alpha: _controller.value.isPlaying ? 0.0 : 0.4),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: ClinicSageColors.tertiary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Real Social Captions & Hashtags
// ─────────────────────────────────────────────────────────────────────────────
class _SocialCaptionsView extends StatelessWidget {
  final GeneratedMediaAsset? mediaAsset;
  const _SocialCaptionsView({required this.mediaAsset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Optimized Social Caption', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  final text = '${mediaAsset?.caption}\n\n${mediaAsset?.hashtags}';
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caption copied to clipboard!')));
                },
                tooltip: 'Copy caption & hashtags',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ClinicSageColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ClinicSageColors.border),
            ),
            child: SelectableText(
              mediaAsset?.caption ?? '🔥 High converting social caption for campaign.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
            ),
          ),
          const SizedBox(height: 16),
          Text('Target Hashtags', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ClinicSageColors.tertiaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              mediaAsset?.hashtags ?? '#Growth #Marketing #AI',
              style: theme.textTheme.bodySmall?.copyWith(color: ClinicSageColors.tertiary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneratingAnimation extends StatelessWidget {
  final ContentType type;
  const _GeneratingAnimation({required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: ClinicSageColors.tertiary),
          const SizedBox(height: 20),
          Text('Generating ${type.label} with Gemini AI...', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Processing client website context, uploaded documents & questionnaire inputs.', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyGenerateState extends StatelessWidget {
  final ContentType type;
  final VoidCallback onGenerate;

  const _EmptyGenerateState({required this.type, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: ClinicSageColors.tertiaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, size: 28, color: ClinicSageColors.tertiary),
          ),
          const SizedBox(height: 20),
          Text('No ${type.label} Generated Yet', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              getEmptyStateText(type),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _AMEditorPanel extends StatelessWidget {
  final ContentType type;
  final TextEditingController controller;
  final VettingStatus status;
  final bool hasGenerated;
  final GeneratedMediaAsset? mediaAsset;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onStatusAdvance;
  final VoidCallback onCopyToClipboard;
  final VoidCallback onSyncFromAI;

  const _AMEditorPanel({
    required this.type,
    required this.controller,
    required this.status,
    required this.hasGenerated,
    this.mediaAsset,
    required this.onTextChanged,
    required this.onStatusAdvance,
    required this.onCopyToClipboard,
    required this.onSyncFromAI,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: ClinicSageColors.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: ClinicSageColors.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit_note, size: 16, color: ClinicSageColors.tertiary),
                const SizedBox(width: 8),
                Text('AM Editor — ${type.label}', style: theme.textTheme.labelMedium),
                const Spacer(),
                StatusBadge(status: status),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: TextField(
                controller: controller,
                maxLines: null,
                expands: true,
                onChanged: onTextChanged,
                textAlignVertical: TextAlignVertical.top,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                decoration: InputDecoration(
                  hintText: 'Generate content first, or type your own draft here...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: ClinicSageColors.border)),
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onCopyToClipboard,
                  icon: const Icon(Icons.copy, size: 14),
                  label: const Text('Copy'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onSyncFromAI,
                  icon: const Icon(Icons.sync, size: 14),
                  label: const Text('Sync from AI'),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: onStatusAdvance,
                  icon: Icon(status == VettingStatus.locked ? Icons.lock : Icons.check, size: 14),
                  label: Text('Mark ${status.nextStatus.label}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: status == VettingStatus.locked
                        ? const Color(0xFF3B82F6)
                        : ClinicSageColors.tertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormattedTextView extends StatelessWidget {
  final String text;
  const _FormattedTextView({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cleanText = GeminiService.instance.cleanMarkdownText(text);
    final lines = cleanText.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();

        if (trimmed.isEmpty) {
          return const SizedBox(height: 10);
        }

        if (trimmed.contains(':') && !trimmed.startsWith('http') && trimmed.length < 80) {
          final parts = trimmed.split(':');
          final title = parts[0].trim();
          final value = parts.sublist(1).join(':').trim();

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6, color: ClinicSageColors.primary),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: ClinicSageColors.tertiary),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          );
        }

        if (RegExp(r'^\d+\.').hasMatch(trimmed) || trimmed.startsWith('•') || trimmed.startsWith('-')) {
          return Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: ClinicSageColors.tertiary, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    trimmed.replaceFirst(RegExp(r'^[\d\.\•\-]+'), '').trim(),
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6, color: ClinicSageColors.primary),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: SelectableText(
            trimmed,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6, color: ClinicSageColors.primary),
          ),
        );
      }).toList(),
    );
  }
}
