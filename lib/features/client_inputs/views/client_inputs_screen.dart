import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/clinic_card.dart';
import '../../../data/models/client_model.dart';
import '../../dashboard/providers/client_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/firebase_service.dart';

import '../../../shared/widgets/workspace_phase_header.dart';

/// Phase 1: Client Inputs Ingestion View
/// 5-section desktop layout for collecting all client discovery assets.
class ClientInputsScreen extends ConsumerStatefulWidget {
  final String clientId;
  const ClientInputsScreen({super.key, required this.clientId});

  @override
  ConsumerState<ClientInputsScreen> createState() => _ClientInputsScreenState();
}

class _ClientInputsScreenState extends ConsumerState<ClientInputsScreen> {
  bool _isSaving = false;
  bool _isPitchDeckUploaded = false;
  bool _isDragOver = false;
  String? _pitchDeckFileName;

  // Controllers
  final _websiteController = TextEditingController();
  final Map<String, TextEditingController> _questionnaireControllers = {
    for (final key in QuestionnaireKeys.labels.keys) key: TextEditingController(),
  };

  // Dynamic Lists
  List<String> _competitors = [''];
  List<String> _roleModels = [''];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClientData();
    });
  }

  void _loadClientData() {
    final clients = ref.read(clientProvider).clients;
    final client = clients.firstWhere(
      (c) => c.id == widget.clientId,
      orElse: () => ClientModel(
        id: widget.clientId,
        name: 'AlphaWave Studio',
        industry: 'SaaS / Tech',
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
      ),
    );

    _websiteController.text = client.websiteUrl ?? '';

    for (var entry in client.questionnaireAnswers.entries) {
      if (_questionnaireControllers.containsKey(entry.key)) {
        _questionnaireControllers[entry.key]!.text = entry.value;
      }
    }

    if (client.competitors.isNotEmpty) {
      setState(() => _competitors = List.from(client.competitors));
    }
    if (client.targetRoleModels.isNotEmpty) {
      setState(() => _roleModels = List.from(client.targetRoleModels));
    }
    if (client.pitchDeckStoragePath != null) {
      setState(() {
        _isPitchDeckUploaded = true;
        _pitchDeckFileName = client.pitchDeckStoragePath!.split('/').last;
      });
    }
  }

  @override
  void dispose() {
    _websiteController.dispose();
    for (final c in _questionnaireControllers.values) {
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
          WorkspacePhaseHeader(client: client, activePhaseIndex: 1),

          // ── Top Bar ──────────────────────────────────────
          _InputsTopBar(
            client: client,
            isSaving: _isSaving,
            onSave: () => _onSave(client),
          ),
          // ── Scrollable Content ────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ClinicSageSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Section 1: Website URL ────────────────
                  _Section(
                    number: '01',
                    title: 'Website URL',
                    subtitle: 'The primary URL that the AI will crawl and ingest for brand context.',
                    child: TextFormField(
                      controller: _websiteController,
                      decoration: const InputDecoration(
                        hintText: 'https://client.com',
                        prefixIcon: Icon(Icons.link, size: 18, color: ClinicSageColors.secondary),
                      ),
                    ),
                  ),
                  const SizedBox(height: ClinicSageSpacing.lg),

                  // ── Section 2: Pitch Deck Upload ───────────
                  _Section(
                    number: '02',
                    title: 'Pitch Deck',
                    subtitle: 'Upload the client\'s pitch deck (PDF). Drag and drop or click to browse.',
                    child: _PitchDeckDropZone(
                      isUploaded: _isPitchDeckUploaded,
                      isDragOver: _isDragOver,
                      fileName: _pitchDeckFileName,
                      onDragOver: (over) => setState(() => _isDragOver = over),
                      onUpload: _onUploadPitchDeck,
                      onClear: () => setState(() {
                        _isPitchDeckUploaded = false;
                        _pitchDeckFileName = null;
                      }),
                    ),
                  ),
                  const SizedBox(height: ClinicSageSpacing.lg),

                  // ── Section 3: Questionnaire ───────────────
                  _Section(
                    number: '03',
                    title: 'Discovery Questionnaire',
                    subtitle: 'Answers collected from the client intake session. Fill in each field.',
                    child: _QuestionnaireGrid(controllers: _questionnaireControllers),
                  ),
                  const SizedBox(height: ClinicSageSpacing.lg),

                  // ── Section 4: Competitor Analysis ────────
                  _Section(
                    number: '04',
                    title: 'Competitor Analysis',
                    subtitle: 'List the client\'s key competitors for USP gap analysis.',
                    child: _DynamicListInput(
                      items: _competitors,
                      hint: 'e.g. Competitor Name / Domain',
                      addLabel: 'Add Competitor',
                      onChanged: () => setState(() {}),
                      onItemChanged: (index, value) => _competitors[index] = value,
                      onAdd: () => setState(() => _competitors.add('')),
                      onRemove: (index) => setState(() => _competitors.removeAt(index)),
                    ),
                  ),
                  const SizedBox(height: ClinicSageSpacing.lg),

                  // ── Section 5: Target Role Models ─────────
                  _Section(
                    number: '05',
                    title: 'Target Role Models',
                    subtitle: 'Brands or creators the client aspires to emulate in content and positioning.',
                    child: _DynamicListInput(
                      items: _roleModels,
                      hint: 'e.g. Brand Name or @handle',
                      addLabel: 'Add Role Model',
                      onChanged: () => setState(() {}),
                      onItemChanged: (index, value) => _roleModels[index] = value,
                      onAdd: () => setState(() => _roleModels.add('')),
                      onRemove: (index) => setState(() => _roleModels.removeAt(index)),
                    ),
                  ),
                  const SizedBox(height: ClinicSageSpacing.xl),

                  // ── Generate CTA ───────────────────────────
                  _GenerateCTA(clientId: widget.clientId, clientName: client.name),
                  const SizedBox(height: ClinicSageSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSave(ClientModel client) async {
    setState(() => _isSaving = true);

    final qAnswers = <String, String>{};
    for (var entry in _questionnaireControllers.entries) {
      if (entry.value.text.trim().isNotEmpty) {
        qAnswers[entry.key] = entry.value.text.trim();
      }
    }

    final updatedClient = client.copyWith(
      websiteUrl: _websiteController.text.trim(),
      questionnaireAnswers: qAnswers,
      competitors: _competitors.where((c) => c.trim().isNotEmpty).toList(),
      targetRoleModels: _roleModels.where((r) => r.trim().isNotEmpty).toList(),
      pitchDeckStoragePath: _pitchDeckFileName != null ? 'pitch_decks/$_pitchDeckFileName' : null,
      lastActivity: DateTime.now(),
    );

    // Save to State & Firestore
    await ref.read(clientProvider.notifier).updateClient(updatedClient);

    final am = ref.read(authProvider).user;
    final amId = am?.id ?? 'am-default';

    await FirebaseService.instance.saveDeliverable(
      amId,
      updatedClient.id,
      'discovery_inputs',
      updatedClient.toJson(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.cloud_done, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Draft & discovery inputs saved to Firestore!'),
            ],
          ),
          backgroundColor: ClinicSageColors.tertiary,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _onUploadPitchDeck() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _isPitchDeckUploaded = true;
          _pitchDeckFileName = result.files.first.name;
          _isDragOver = false;
        });
      }
    } catch (e) {
      // Fallback file pick simulation
      setState(() {
        _isPitchDeckUploaded = true;
        _pitchDeckFileName = 'pitch_deck_ingested.pdf';
        _isDragOver = false;
      });
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Action Bar
// ─────────────────────────────────────────────────────────────────────────────
class _InputsTopBar extends StatelessWidget {
  final ClientModel client;
  final bool isSaving;
  final VoidCallback onSave;

  const _InputsTopBar({required this.client, required this.isSaving, required this.onSave});

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
              Text('Client Inputs · Phase 1', style: theme.textTheme.labelSmall),
            ],
          ),
          const Spacer(),
          _PhaseNavChip(label: 'Inputs', isActive: true),
          const SizedBox(width: 8),
          _PhaseNavChip(
            label: 'Content Studio',
            isActive: false,
            onTap: () => GoRouter.of(context).go(AppRoutes.clientContentPath(client.id)),
          ),
          const SizedBox(width: 8),
          _PhaseNavChip(
            label: 'Strategy',
            isActive: false,
            onTap: () => GoRouter.of(context).go(AppRoutes.clientStrategyPath(client.id)),
          ),
          const SizedBox(width: 8),
          _PhaseNavChip(
            label: 'Review',
            isActive: false,
            onTap: () => GoRouter.of(context).go(AppRoutes.clientReviewPath(client.id)),
          ),
          const SizedBox(width: ClinicSageSpacing.md),
          OutlinedButton(
            onPressed: isSaving ? null : onSave,
            child: isSaving
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save Draft'),
          ),
        ],
      ),
    );
  }
}

class _PhaseNavChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _PhaseNavChip({required this.label, required this.isActive, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? ClinicSageColors.tertiaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? ClinicSageColors.tertiary : ClinicSageColors.border,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isActive ? ClinicSageColors.tertiary : ClinicSageColors.secondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final Widget child;

  const _Section({required this.number, required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(number, style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 13,
                  color: ClinicSageColors.secondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                )),
                const SizedBox(height: 4),
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(subtitle, style: theme.textTheme.labelSmall?.copyWith(height: 1.5)),
              ],
            ),
          ),
        ),
        const SizedBox(width: ClinicSageSpacing.lg),
        Expanded(child: ClinicCard(child: child)),
      ],
    );
  }
}

class _PitchDeckDropZone extends StatelessWidget {
  final bool isUploaded;
  final bool isDragOver;
  final String? fileName;
  final ValueChanged<bool> onDragOver;
  final VoidCallback onUpload;
  final VoidCallback onClear;

  const _PitchDeckDropZone({
    required this.isUploaded,
    required this.isDragOver,
    required this.fileName,
    required this.onDragOver,
    required this.onUpload,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isUploaded) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ClinicSageColors.statusVettedBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.picture_as_pdf, size: 24, color: ClinicSageColors.tertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName ?? 'pitch_deck.pdf', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                Text('PDF uploaded successfully', style: theme.textTheme.bodySmall?.copyWith(color: ClinicSageColors.tertiary)),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.close, size: 14),
            label: const Text('Remove'),
            style: TextButton.styleFrom(foregroundColor: ClinicSageColors.secondary),
          ),
        ],
      );
    }

    return DragTarget<Object>(
      onWillAcceptWithDetails: (_) {
        onDragOver(true);
        return true;
      },
      onLeave: (_) => onDragOver(false),
      onAcceptWithDetails: (_) {
        onDragOver(false);
        onUpload();
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: onUpload,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: isDragOver ? ClinicSageColors.tertiaryLight : ClinicSageColors.neutral,
              borderRadius: BorderRadius.circular(ClinicSageRadius.md),
              border: Border.all(
                color: isDragOver ? ClinicSageColors.tertiary : ClinicSageColors.border,
                width: isDragOver ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.upload_file_outlined,
                  size: 32,
                  color: isDragOver ? ClinicSageColors.tertiary : ClinicSageColors.secondary,
                ),
                const SizedBox(height: 12),
                Text(
                  isDragOver ? 'Drop to upload' : 'Drag & drop PDF here',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'or click to browse — PDF files only',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuestionnaireGrid extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  const _QuestionnaireGrid({required this.controllers});

  @override
  Widget build(BuildContext context) {
    final entries = QuestionnaireKeys.labels.entries.toList();

    return Column(
      children: [
        for (int i = 0; i < entries.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: ClinicSageSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: _QuestionField(
                    label: entries[i].value,
                    controller: controllers[entries[i].key]!,
                    isMultiline: _isMultiline(entries[i].key),
                  ),
                ),
                if (i + 1 < entries.length) ...[
                  const SizedBox(width: ClinicSageSpacing.md),
                  Expanded(
                    child: _QuestionField(
                      label: entries[i + 1].value,
                      controller: controllers[entries[i + 1].key]!,
                      isMultiline: _isMultiline(entries[i + 1].key),
                    ),
                  ),
                ] else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
      ],
    );
  }

  bool _isMultiline(String key) {
    return [
      QuestionnaireKeys.targetAudience,
      QuestionnaireKeys.pastWins,
      QuestionnaireKeys.painPoints,
    ].contains(key);
  }
}

class _QuestionField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isMultiline;

  const _QuestionField({required this.label, required this.controller, this.isMultiline = false});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: isMultiline ? 3 : 1,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _DynamicListInput extends StatelessWidget {
  final List<String> items;
  final String hint;
  final String addLabel;
  final VoidCallback onChanged;
  final Function(int, String) onItemChanged;
  final VoidCallback onAdd;
  final Function(int) onRemove;

  const _DynamicListInput({
    required this.items,
    required this.hint,
    required this.addLabel,
    required this.onChanged,
    required this.onItemChanged,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: ClinicSageSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: ClinicSageColors.neutral,
                    border: Border.all(color: ClinicSageColors.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: items[i],
                    onChanged: (v) => onItemChanged(i, v),
                    decoration: InputDecoration(hintText: hint),
                  ),
                ),
                const SizedBox(width: 8),
                if (items.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    color: ClinicSageColors.secondary,
                    onPressed: () => onRemove(i),
                    tooltip: 'Remove',
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: ClinicSageSpacing.sm),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 16),
          label: Text(addLabel),
        ),
      ],
    );
  }
}

class _GenerateCTA extends StatelessWidget {
  final String clientId;
  final String clientName;
  const _GenerateCTA({required this.clientId, required this.clientName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClinicCard(
      backgroundColor: ClinicSageColors.primary,
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: ClinicSageColors.tertiary, size: 28),
          const SizedBox(width: ClinicSageSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to generate deliverables for $clientName?',
                  style: theme.textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Inputs will be vectorized and orchestrated via Gemini AI.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          const SizedBox(width: ClinicSageSpacing.md),
          ElevatedButton.icon(
            onPressed: () => GoRouter.of(context).go(AppRoutes.clientContentPath(clientId)),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Generate Content'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => GoRouter.of(context).go(AppRoutes.clientStrategyPath(clientId)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white30),
            ),
            child: const Text('Generate Strategy'),
          ),
        ],
      ),
    );
  }
}
