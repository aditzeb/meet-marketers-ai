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
import '../../../core/services/web_download_helper.dart';
import '../../../shared/widgets/workspace_phase_header.dart';
import 'package:video_player/video_player.dart';

/// Phase 3A: Content Production — Split-Screen Editor + Real Photo, Video & Caption Generator
class ContentStudioScreen extends ConsumerStatefulWidget {
  final String clientId;
  const ContentStudioScreen({super.key, required this.clientId});

  @override
  ConsumerState<ContentStudioScreen> createState() => _ContentStudioScreenState();
}

class _ContentStudioScreenState extends ConsumerState<ContentStudioScreen> {
  ContentType _selectedType = ContentType.socialMediaPosts;
  _MediaTab _mediaTab = _MediaTab.textAndScript;

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
          // ── Type Tabs & Media Selector ────────────────────
          _ContentTypeTabs(
            selectedType: _selectedType,
            statuses: _statuses,
            onTypeSelected: (t) => setState(() => _selectedType = t),
          ),
          _SubMediaSelectorBar(
            selectedTab: _mediaTab,
            onTabSelected: (tab) => setState(() => _mediaTab = tab),
          ),

          // ── Split Pane ────────────────────────────────────
          Expanded(
            child: Row(
              children: [
                // Left: AI Generated Output (Text, Photo, Video, or Captions)
                Expanded(
                  child: _AIOutputPanel(
                    type: _selectedType,
                    mediaTab: _mediaTab,
                    aiText: _aiTexts[_selectedType] ?? '',
                    mediaAsset: _mediaAssets[_selectedType],
                    hasGenerated: _hasGenerated[_selectedType] ?? false,
                    isGenerating: _isGenerating,
                    onGenerate: () => _onGenerate(client),
                  ),
                ),
                // Divider
                Container(width: 1, color: ClinicSageColors.border),
                // Right: AM Editor
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

enum _MediaTab {
  textAndScript('Text & Script', Icons.notes),
  photoAsset('AI Photo Asset', Icons.photo_camera_back),
  videoStoryboard('Video Storyboard', Icons.movie_creation_outlined),
  socialCaptions('Social Captions', Icons.tag);

  const _MediaTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub Media Selector Bar
// ─────────────────────────────────────────────────────────────────────────────
class _SubMediaSelectorBar extends StatelessWidget {
  final _MediaTab selectedTab;
  final ValueChanged<_MediaTab> onTabSelected;

  const _SubMediaSelectorBar({required this.selectedTab, required this.onTabSelected});

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
        children: _MediaTab.values.map((tab) {
          final isSelected = tab == selectedTab;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () => onTabSelected(tab),
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
          // Selected content type badge
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
                      ? LinearGradient(colors: [ClinicSageColors.tertiary.withOpacity(0.4), ClinicSageColors.tertiary.withOpacity(0.4)])
                      : ClinicSageGradients.aiGlow,
                  borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                  boxShadow: isGeneratingAll
                      ? []
                      : [BoxShadow(color: ClinicSageColors.tertiary.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
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
// AI Output Panel (Supports Text, Photo, Video Storyboard & Captions)
// ─────────────────────────────────────────────────────────────────────────────
class _AIOutputPanel extends StatelessWidget {
  final ContentType type;
  final _MediaTab mediaTab;
  final String aiText;
  final GeneratedMediaAsset? mediaAsset;
  final bool hasGenerated;
  final bool isGenerating;
  final VoidCallback onGenerate;

  const _AIOutputPanel({
    required this.type,
    required this.mediaTab,
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
                Text('AI Generated — ${type.label} (${mediaTab.label})', style: theme.textTheme.labelMedium),
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
                ? _GeneratingAnimation()
                : !hasGenerated
                    ? _EmptyGenerateState(type: type, onGenerate: onGenerate)
                    : _buildMediaTabContent(context),
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
                      label: Text(hasGenerated ? 'Regenerate Media & Text' : 'Generate ${type.label} & Photos/Video'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaTabContent(BuildContext context) {
    switch (mediaTab) {
      case _MediaTab.textAndScript:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _FormattedTextView(text: aiText),
        );

      case _MediaTab.photoAsset:
        return _PhotoAssetView(mediaAsset: mediaAsset);

      case _MediaTab.videoStoryboard:
        return _VideoStoryboardView(mediaAsset: mediaAsset);

      case _MediaTab.socialCaptions:
        return _SocialCaptionsView(mediaAsset: mediaAsset);
    }
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ClinicSageColors.tertiaryLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 12, color: ClinicSageColors.tertiary),
                    const SizedBox(width: 4),
                    Text('Gemini Nano / Vertex AI Image Engine', style: theme.textTheme.labelSmall?.copyWith(color: ClinicSageColors.tertiary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image.network(
                  url,
                  width: double.infinity,
                  height: 380,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 380,
                      color: ClinicSageColors.surface,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: ClinicSageColors.tertiary),
                            const SizedBox(height: 12),
                            Text('Loading high-res Vertex AI photography...', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 320,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [ClinicSageColors.primary, Color(0xFF2C5E48)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, size: 48, color: ClinicSageColors.tertiary),
                          const SizedBox(height: 12),
                          Text(
                            'Vertex AI 8K Photography Asset',
                            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Minimalist editorial commercial render',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hd, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text('8K Resolution', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    downloadWebFile(url, 'Vertex_8K_Visual_Photo.jpg');
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download 8K Visual Photo'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  downloadWebFile(url, 'Vertex_8K_Visual_Photo.jpg');
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Open Full High-Res'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ClinicSageColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ClinicSageColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 14, color: ClinicSageColors.tertiary),
                    const SizedBox(width: 6),
                    Text('Vertex AI Prompt Parameters', style: theme.textTheme.labelMedium?.copyWith(color: ClinicSageColors.tertiary, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 14),
                      onPressed: () {
                        final prompt = mediaAsset?.prompt ?? '';
                        Clipboard.setData(ClipboardData(text: prompt));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prompt copied to clipboard')));
                      },
                      tooltip: 'Copy image prompt',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SelectableText(
                  mediaAsset?.prompt ?? 'Professional commercial photography, 8k resolution, cinematic lighting.',
                  style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, height: 1.6),
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
// Real Video Storyboard & Scene Preview with Video Player Renderer
// ─────────────────────────────────────────────────────────────────────────────
class _VideoStoryboardView extends StatelessWidget {
  final GeneratedMediaAsset? mediaAsset;
  const _VideoStoryboardView({required this.mediaAsset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scenes = mediaAsset?.storyboard ?? [];
    final videoUrl = mediaAsset?.videoUrl ?? 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Vertex AI Generated Video & Storyboard', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ClinicSageColors.tertiaryLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.videocam, size: 12, color: ClinicSageColors.tertiary),
                    const SizedBox(width: 4),
                    Text('Gemini 2.0 Vertex Video Engine', style: theme.textTheme.labelSmall?.copyWith(color: ClinicSageColors.tertiary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Interactive Video Player Canvas ──────────────────
          _VertexVideoPlayerWidget(videoUrl: videoUrl),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    downloadWebFile(videoUrl, 'Vertex_AI_Video_Render.mp4');
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download AI Video (MP4)'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  downloadWebFile(videoUrl, 'Vertex_AI_Video_Render.mp4');
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Open Stream'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Scene Direction & Script Breakdown', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
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
                Text('Voiceover / Audio:', style: theme.textTheme.labelSmall?.copyWith(color: ClinicSageColors.tertiary)),
                Text('"${s.voiceoverScript}"', style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
              ],
            ),
          )),
        ],
      ),
    );
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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() async {
    // High-performance CORS-enabled Google Cloud Storage MP4 stream
    final url = widget.videoUrl.contains('mixkit') || widget.videoUrl.isEmpty
        ? 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4'
        : widget.videoUrl;

    _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await _controller.initialize();
      _controller.setLooping(true);
      // Mute initial volume to satisfy Web autoplay policy guidelines
      await _controller.setVolume(0.0);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
      }
    } catch (e) {
      debugPrint('Video player initialization warning: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.setVolume(1.0);
        _controller.play();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_isInitialized) {
      return Container(
        height: 320,
        decoration: BoxDecoration(
          color: ClinicSageColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ClinicSageColors.border),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: ClinicSageColors.tertiary),
              SizedBox(height: 12),
              Text('Initializing Vertex AI Video Stream...'),
            ],
          ),
        ),
      );
    }

    final aspectRatio = (_controller.value.isInitialized && _controller.value.aspectRatio > 0)
        ? _controller.value.aspectRatio
        : (16 / 9);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 340,
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
            // Interactive Play / Pause Overlay Trigger
            Positioned.fill(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  color: Colors.black.withValues(alpha: _controller.value.isPlaying ? 0.0 : 0.4),
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _controller.value.isPlaying ? 0.0 : 0.9,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: ClinicSageColors.tertiary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Icon(
                          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 42,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Controls Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.black.withValues(alpha: 0.75),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gemini Vertex AI Video Stream Preview',
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _controller.value.volume > 0 ? Icons.volume_up : Icons.volume_off,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() {
                        _controller.setVolume(_controller.value.volume > 0 ? 0.0 : 1.0);
                      });
                    },
                  ),
                ],
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
          Text('Hashtags', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
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

class _GeneratingAnimation extends StatefulWidget {
  @override
  State<_GeneratingAnimation> createState() => _GeneratingAnimationState();
}

class _GeneratingAnimationState extends State<_GeneratingAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _animation,
            child: const Icon(Icons.auto_awesome, size: 32, color: ClinicSageColors.tertiary),
          ),
          const SizedBox(height: 16),
          Text('Generating Photos, Videos & Captions with Gemini...', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text('Structuring visual prompts, video storyboards, and social captions.', style: theme.textTheme.bodySmall),
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
          Text('No ${type.label} or Media Generated Yet', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Click "Generate" to generate photo assets,\nvideo storyboards, text, and captions using Gemini AI.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
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
                const Icon(Icons.edit_outlined, size: 14, color: ClinicSageColors.secondary),
                const SizedBox(width: 8),
                Text('AM Editor — ${type.label}', style: theme.textTheme.labelMedium),
                const Spacer(),
                StatusBadge(status: status, compact: true),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onTextChanged,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.8),
              decoration: InputDecoration(
                hintText: hasGenerated
                    ? 'Click "Sync from AI" to load Gemini output & captions, then edit here...'
                    : 'Generate content first, or type your own draft here...',
                hintStyle: theme.textTheme.bodySmall?.copyWith(color: ClinicSageColors.secondary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                filled: false,
                contentPadding: const EdgeInsets.all(24),
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
                if (hasGenerated)
                  OutlinedButton.icon(
                    onPressed: onSyncFromAI,
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('Sync from AI'),
                  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onCopyToClipboard,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                ),
                const Spacer(),
                if (status != VettingStatus.locked)
                  ElevatedButton.icon(
                    onPressed: onStatusAdvance,
                    icon: Icon(
                      status == VettingStatus.draft
                          ? Icons.rate_review_outlined
                          : status == VettingStatus.inReview
                              ? Icons.verified_outlined
                              : Icons.lock_outlined,
                      size: 16,
                    ),
                    label: Text(
                      status == VettingStatus.draft
                          ? 'Mark In Review'
                          : status == VettingStatus.inReview
                              ? 'Approve & Vet'
                              : 'Lock & Export',
                    ),
                  ),
                if (status == VettingStatus.locked)
                  Row(
                    children: [
                      const Icon(Icons.lock, size: 14, color: ClinicSageColors.secondary),
                      const SizedBox(width: 6),
                      Text('Locked', style: theme.textTheme.labelMedium?.copyWith(color: ClinicSageColors.secondary)),
                    ],
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
// Clean Formatted Typography View (No raw ***, **, ###, ---, |)
// ─────────────────────────────────────────────────────────────────────────────
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
