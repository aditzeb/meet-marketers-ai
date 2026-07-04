import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/clinic_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../data/models/content_deliverable_model.dart';
import '../../../core/services/hive_cache_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/models/client_model.dart';
import '../../dashboard/providers/client_provider.dart';
import '../../auth/providers/auth_provider.dart';

import '../../../shared/widgets/workspace_phase_header.dart';

/// Phase 4: AM Campaign Review & Approval Dashboard
/// Approve, lock, and save all vetted deliverables directly to Firestore
class ReviewScreen extends ConsumerStatefulWidget {
  final String clientId;
  const ReviewScreen({super.key, required this.clientId});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  late List<_ReviewItem> _items;
  bool _showOnlyPending = false;
  ContentType? _filterType;
  bool _isSavingBundle = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    _items = ContentType.values.map((t) {
      final key = 'draft_${widget.clientId}_${t.value}';
      final cachedText = HiveCacheService.instance.getDraftBuffer(key);
      final hasText = cachedText != null && cachedText.isNotEmpty;

      return _ReviewItem(
        id: 'del_${widget.clientId}_${t.value}',
        type: t,
        title: '${t.label} Campaign Asset',
        aiText: 'AI-generated ${t.label.toLowerCase()} framework ready for review.',
        vettedText: hasText ? cachedText : '',
        status: hasText ? VettingStatus.vetted : VettingStatus.draft,
      );
    }).toList();
  }

  List<_ReviewItem> get _filteredItems {
    var items = _items;
    if (_showOnlyPending) {
      items = items.where((i) => i.status != VettingStatus.locked).toList();
    }
    if (_filterType != null) {
      items = items.where((i) => i.type == _filterType).toList();
    }
    return items;
  }

  int get _approvedCount => _items.where((i) => i.status == VettingStatus.locked).length;
  int get _vettedCount => _items.where((i) => i.status == VettingStatus.vetted).length;
  int get _inReviewCount => _items.where((i) => i.status == VettingStatus.inReview).length;
  int get _draftCount => _items.where((i) => i.status == VettingStatus.draft).length;

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientProvider);
    final client = clientState.getClient(widget.clientId);

    return Scaffold(
      backgroundColor: ClinicSageColors.neutral,
      body: Column(
        children: [
          // ── Unified Workspace Navigation Header ──────────
          WorkspacePhaseHeader(client: client, activePhaseIndex: 4),

          // ── Top Bar ──────────────────────────────────────
          _ReviewTopBar(
            client: client,
            approvedCount: _approvedCount,
            totalCount: _items.length,
            isSavingBundle: _isSavingBundle,
            onSaveBundleToFirestore: () => _onSaveBundleToFirestore(client),
            onCopyJson: () => _onCopyJson(client),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ClinicSageSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Summary Metrics ───────────────────────
                  _ReviewMetrics(
                    approved: _approvedCount,
                    vetted: _vettedCount,
                    inReview: _inReviewCount,
                    draft: _draftCount,
                    total: _items.length,
                  ),
                  const SizedBox(height: ClinicSageSpacing.lg),

                  // ── Filter Bar ───────────────────────────
                  _ReviewFilterBar(
                    showOnlyPending: _showOnlyPending,
                    filterType: _filterType,
                    onTogglePending: () => setState(() => _showOnlyPending = !_showOnlyPending),
                    onFilterType: (t) => setState(() => _filterType = _filterType == t ? null : t),
                  ),
                  const SizedBox(height: ClinicSageSpacing.md),

                  // ── Review Items ─────────────────────────
                  ..._filteredItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: ClinicSageSpacing.md),
                    child: _ReviewCard(
                      item: item,
                      onStatusChange: (s) => _onUpdateItemStatus(item, s),
                      onCopy: () => _onCopyItem(item),
                    ),
                  )),

                  if (_filteredItems.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 48, color: ClinicSageColors.tertiary),
                            const SizedBox(height: 16),
                            Text('All items processed', style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onUpdateItemStatus(_ReviewItem item, VettingStatus newStatus) async {
    setState(() {
      final idx = _items.indexWhere((i) => i.id == item.id);
      if (idx != -1) _items[idx] = item.copyWith(status: newStatus);
    });

    final am = ref.read(authProvider).user;
    final amId = am?.id ?? 'am-default';

    await FirebaseService.instance.saveDeliverable(
      amId,
      widget.clientId,
      item.type.value,
      {
        'title': item.title,
        'status': newStatus.value,
        'vettedOutputText': item.vettedText,
        'aiGeneratedText': item.aiText,
      },
    );
  }

  void _onSaveBundleToFirestore(ClientModel client) async {
    setState(() => _isSavingBundle = true);

    final am = ref.read(authProvider).user;
    final amId = am?.id ?? 'am-default';

    final deliverablesPayload = <String, dynamic>{};
    for (var item in _items) {
      deliverablesPayload[item.type.value] = {
        'title': item.title,
        'status': item.status.value,
        'content': item.vettedText.isNotEmpty ? item.vettedText : item.aiText,
      };

      // Save each individual deliverable doc to Firestore
      await FirebaseService.instance.saveDeliverable(
        amId,
        client.id,
        item.type.value,
        {
          'title': item.title,
          'status': item.status.value,
          'vettedOutputText': item.vettedText,
          'aiGeneratedText': item.aiText,
        },
      );
    }

    // Save master campaign bundle document to Firestore
    await FirebaseService.instance.saveDeliverable(
      amId,
      client.id,
      'campaign_bundle',
      {
        'clientName': client.name,
        'industry': client.industry,
        'totalItems': _items.length,
        'lockedCount': _approvedCount,
        'deliverables': deliverablesPayload,
      },
    );

    if (mounted) {
      setState(() => _isSavingBundle = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cloud_done, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text('Campaign bundle & ${_items.length} deliverables saved to Firestore!'),
            ],
          ),
          backgroundColor: ClinicSageColors.tertiary,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _onCopyJson(ClientModel client) {
    final exportBundle = {
      'client': client.name,
      'exportedAt': DateTime.now().toIso8601String(),
      'deliverables': _items.map((i) => {
        'type': i.type.label,
        'status': i.status.label,
        'content': i.vettedText.isNotEmpty ? i.vettedText : i.aiText,
      }).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(exportBundle);
    Clipboard.setData(ClipboardData(text: jsonStr));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Campaign JSON bundle copied to clipboard!')),
    );
  }

  void _onCopyItem(_ReviewItem item) {
    final text = item.vettedText.isNotEmpty ? item.vettedText : item.aiText;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.title} copied to clipboard')),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────────────────
class _ReviewTopBar extends StatelessWidget {
  final ClientModel client;
  final int approvedCount;
  final int totalCount;
  final bool isSavingBundle;
  final VoidCallback onSaveBundleToFirestore;
  final VoidCallback onCopyJson;

  const _ReviewTopBar({
    required this.client,
    required this.approvedCount,
    required this.totalCount,
    required this.isSavingBundle,
    required this.onSaveBundleToFirestore,
    required this.onCopyJson,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: ClinicSageSpacing.lg),
      decoration: const BoxDecoration(
        color: ClinicSageColors.surface,
        border: Border(bottom: BorderSide(color: ClinicSageColors.border)),
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(client.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              Text('Review & Approval · Phase 4', style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(width: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: approvedCount == totalCount ? ClinicSageColors.statusVettedBg : ClinicSageColors.neutral,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: ClinicSageColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  approvedCount == totalCount ? Icons.lock : Icons.pending_actions,
                  size: 14,
                  color: approvedCount == totalCount ? ClinicSageColors.tertiary : ClinicSageColors.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '$approvedCount / $totalCount locked',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: approvedCount == totalCount ? ClinicSageColors.tertiary : ClinicSageColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: onCopyJson,
            icon: const Icon(Icons.copy, size: 14),
            label: const Text('Copy JSON'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: isSavingBundle ? null : onSaveBundleToFirestore,
            icon: isSavingBundle
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.cloud_upload, size: 16),
            label: Text(isSavingBundle ? 'Saving...' : 'Save Bundle to Firestore'),
          ),
        ],
      ),
    );
  }
}

class _ReviewMetrics extends StatelessWidget {
  final int approved, vetted, inReview, draft, total;
  const _ReviewMetrics({required this.approved, required this.vetted, required this.inReview, required this.draft, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = total > 0 ? (approved / total * 100).round() : 0;

    return ClinicCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Campaign Approval Progress', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('$pct% of deliverables locked for client presentation', style: theme.textTheme.bodySmall),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? approved / total : 0,
                    minHeight: 6,
                    backgroundColor: ClinicSageColors.neutral,
                    valueColor: const AlwaysStoppedAnimation<Color>(ClinicSageColors.tertiary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
          _MiniStat(count: approved, label: 'Locked', color: ClinicSageColors.statusApproved),
          const SizedBox(width: 24),
          _MiniStat(count: vetted, label: 'Vetted', color: ClinicSageColors.statusVetted),
          const SizedBox(width: 24),
          _MiniStat(count: inReview, label: 'In Review', color: const Color(0xFF8B7A4E)),
          const SizedBox(width: 24),
          _MiniStat(count: draft, label: 'Draft', color: ClinicSageColors.statusDraft),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _MiniStat({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          '$count',
          style: theme.textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _ReviewFilterBar extends StatelessWidget {
  final bool showOnlyPending;
  final ContentType? filterType;
  final VoidCallback onTogglePending;
  final ValueChanged<ContentType> onFilterType;

  const _ReviewFilterBar({
    required this.showOnlyPending,
    required this.filterType,
    required this.onTogglePending,
    required this.onFilterType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text('All Deliverables', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: onTogglePending,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: showOnlyPending ? ClinicSageColors.tertiaryLight : ClinicSageColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: showOnlyPending ? ClinicSageColors.tertiary : ClinicSageColors.border),
            ),
            child: Text(
              'Pending only',
              style: theme.textTheme.labelMedium?.copyWith(
                color: showOnlyPending ? ClinicSageColors.tertiary : ClinicSageColors.secondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ...ContentType.values.take(4).map((t) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () => onFilterType(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: filterType == t ? ClinicSageColors.tertiaryLight : ClinicSageColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: filterType == t ? ClinicSageColors.tertiary : ClinicSageColors.border),
              ),
              child: Text(
                t.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: filterType == t ? ClinicSageColors.tertiary : ClinicSageColors.secondary,
                ),
              ),
            ),
          ),
        )),
      ],
    );
  }
}

class _ReviewCard extends StatefulWidget {
  final _ReviewItem item;
  final ValueChanged<VettingStatus> onStatusChange;
  final VoidCallback onCopy;

  const _ReviewCard({required this.item, required this.onStatusChange, required this.onCopy});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final isLocked = item.status == VettingStatus.locked;

    return ClinicCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
              decoration: BoxDecoration(
                color: isLocked ? ClinicSageColors.statusApprovedBg : ClinicSageColors.surface,
                borderRadius: _isExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(ClinicSageRadius.lg))
                    : BorderRadius.circular(ClinicSageRadius.lg),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ClinicSageColors.neutral,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_typeIcon(item.type), size: 16, color: ClinicSageColors.secondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(item.type.label, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  StatusBadge(status: item.status),
                  const SizedBox(width: 12),
                  if (!isLocked) ...[
                    if (item.status == VettingStatus.vetted)
                      ElevatedButton.icon(
                        onPressed: () => widget.onStatusChange(VettingStatus.locked),
                        icon: const Icon(Icons.lock, size: 14),
                        label: const Text('Lock & Approve'),
                      )
                    else
                      OutlinedButton(
                        onPressed: () => widget.onStatusChange(item.status.nextStatus),
                        child: Text('Advance to ${item.status.nextStatus.label}'),
                      ),
                    const SizedBox(width: 8),
                  ],
                  if (isLocked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: ClinicSageColors.statusApprovedBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock, size: 12, color: ClinicSageColors.statusApproved),
                          const SizedBox(width: 4),
                          Text('Locked', style: theme.textTheme.labelSmall?.copyWith(color: ClinicSageColors.statusApproved)),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: widget.onCopy,
                    icon: const Icon(Icons.copy, size: 16),
                    color: ClinicSageColors.secondary,
                    tooltip: 'Copy to clipboard',
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: ClinicSageColors.secondary,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: ClinicSageColors.border)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, size: 12, color: ClinicSageColors.secondary),
                              const SizedBox(width: 4),
                              Text('AI Framework', style: theme.textTheme.labelSmall),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SelectableText(
                            item.aiText.isNotEmpty ? item.aiText : 'No AI content generated.',
                            style: theme.textTheme.bodySmall?.copyWith(height: 1.7, color: ClinicSageColors.secondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(width: 1, color: ClinicSageColors.border),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.edit_outlined, size: 12, color: ClinicSageColors.tertiary),
                              const SizedBox(width: 4),
                              Text('AM Vetted Content', style: theme.textTheme.labelSmall?.copyWith(color: ClinicSageColors.tertiary)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SelectableText(
                            item.vettedText.isNotEmpty ? item.vettedText : 'No AM edits saved yet. Go to Content Studio to edit and sync.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.7,
                              color: item.vettedText.isNotEmpty ? ClinicSageColors.primary : ClinicSageColors.secondary,
                              fontStyle: item.vettedText.isEmpty ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _typeIcon(ContentType type) {
    switch (type) {
      case ContentType.script:
        return Icons.videocam_outlined;
      case ContentType.copy:
        return Icons.text_fields;
      case ContentType.designBrief:
        return Icons.palette_outlined;
      case ContentType.socialPost:
        return Icons.share_outlined;
      case ContentType.emailCopy:
        return Icons.email_outlined;
      case ContentType.pressRelease:
        return Icons.newspaper_outlined;
    }
  }
}

class _ReviewItem {
  final String id;
  final ContentType type;
  final String title;
  final String aiText;
  final String vettedText;
  final VettingStatus status;

  const _ReviewItem({
    required this.id,
    required this.type,
    required this.title,
    required this.aiText,
    required this.vettedText,
    required this.status,
  });

  _ReviewItem copyWith({VettingStatus? status}) {
    return _ReviewItem(
      id: id,
      type: type,
      title: title,
      aiText: aiText,
      vettedText: vettedText,
      status: status ?? this.status,
    );
  }
}
